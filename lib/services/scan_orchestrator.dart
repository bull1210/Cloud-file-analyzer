import 'dart:async';
import 'dart:isolate';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/errors/app_exception.dart';
import '../core/logging/app_logger.dart';
import '../core/utils/file_type_utils.dart';
import '../data/local/database/app_database.dart';
import '../data/local/secure_storage/token_storage_service.dart';
import '../data/remote/dropbox/dropbox_api.dart';
import '../data/remote/dropbox/dropbox_auth_service.dart';
import '../data/remote/dropbox/dropbox_client.dart';
import '../data/remote/google/google_auth_service.dart';
import '../data/remote/google/google_drive_api.dart';
import '../data/remote/google/google_drive_client.dart';
import '../data/remote/mega/mega_api.dart';
import '../data/remote/microsoft/microsoft_auth_service.dart';
import '../data/remote/microsoft/onedrive_api.dart';
import '../data/remote/microsoft/onedrive_client.dart';
import '../data/remote/terabox/terabox_api.dart';
import '../data/remote/terabox/terabox_auth_service.dart';
import '../data/remote/terabox/terabox_client.dart';
import '../domain/models/cloud_account.dart';
import '../domain/models/scan_session.dart';

// ── Message types ─────────────────────────────────────────────────────────────

sealed class _ScanMessage {}

class _ScanProgressMessage extends _ScanMessage {
  _ScanProgressMessage(this.progress);
  final ScanProgress progress;
}

class _ScanCompleteMessage extends _ScanMessage {
  _ScanCompleteMessage({
    required this.totalFiles,
    required this.totalFolders,
    required this.totalBytes,
  });
  final int totalFiles;
  final int totalFolders;
  final int totalBytes;
}

class _ScanErrorMessage extends _ScanMessage {
  _ScanErrorMessage(this.error, {this.isAuthError = false});
  final String error;
  final bool isAuthError;
}

// ── Orchestrator ──────────────────────────────────────────────────────────────

class ScanOrchestrator {
  ScanOrchestrator({
    required this.db,
    required this.tokenStorage,
    required this.googleDriveApi,
    required this.oneDriveApi,
    required this.dropboxApi,
    required this.teraboxApi,
    required this.megaApi,
  });

  final AppDatabase db;
  final TokenStorageService tokenStorage;
  final GoogleDriveApi googleDriveApi;
  final OneDriveApi oneDriveApi;
  final DropboxApi dropboxApi;
  final TeraboxApi teraboxApi;
  final MegaApi megaApi;

  Isolate? _scanIsolate;
  SendPort? _cancelPort;
  final _uuid = const Uuid();

  Stream<ScanProgress> startScan(CloudAccount account) async* {
    cancelScan();

    final sessionId = _uuid.v4();
    await db.scanSessionDao.insertSession(
      ScanSessionsTableCompanion.insert(
        id: sessionId,
        accountId: account.id,
        startedAt: DateTime.now().millisecondsSinceEpoch,
        status: 'running',
      ),
    );

    // Verify API access BEFORE deleting existing records.
    try {
      switch (account.provider) {
        case CloudProvider.google:
          await googleDriveApi.getAbout(account.id);
        case CloudProvider.microsoft:
          await oneDriveApi.getUserInfo(account.id);
        case CloudProvider.dropbox:
          await dropboxApi.testConnection(account.id);
        case CloudProvider.terabox:
          await teraboxApi.testConnection(account.id);
        case CloudProvider.mega:
          await megaApi.testConnection();
        case CloudProvider.apple:
          // iCloud Drive has no public REST API. Native iOS/macOS scanning is
          // planned for a future update. Throw here so existing data is preserved.
          throw const ScanException(
            'iCloud Drive scanning is not yet available.\n'
            'Your account is connected — native scanning on iOS and macOS '
            'is planned for a future release.',
          );
      }
    } catch (e) {
      await db.scanSessionDao.markFailed(
        sessionId: sessionId,
        error: e.toString(),
      );
      final msg = e is AppException
          ? e.message
          : 'Could not connect to cloud storage. Your existing data is preserved.';
      throw ScanException(msg, cause: e is Exception ? e : null);
    }

    logger.log('ScanOrchestrator',
        'verification passed for ${account.provider.name} — spawning isolate');
    await db.fileRecordDao.deleteAllForAccount(account.id);

    final accessToken = await tokenStorage.getAccessToken(account.id) ?? '';
    logger.log('ScanOrchestrator',
        'token for isolate: len=${accessToken.length} empty=${accessToken.isEmpty}');

    final progressController = StreamController<ScanProgress>.broadcast();
    final receivePort = ReceivePort();
    final cancelReceivePort = ReceivePort();

    var pendingInserts = Future<void>.value();

    try {
      _scanIsolate = await Isolate.spawn(
        _scanWorker,
        _ScanWorkerParams(
          sendPort: receivePort.sendPort,
          cancelPort: cancelReceivePort.sendPort,
          accountId: account.id,
          provider: account.provider,
          accessToken: accessToken,
        ),
      );

      _cancelPort = cancelReceivePort.sendPort;

      receivePort.listen((message) {
        if (message is _ScanProgressMessage) {
          progressController.add(message.progress);
        } else if (message is _ScanCompleteMessage) {
          pendingInserts = pendingInserts.then((_) async {
            await db.scanSessionDao.markComplete(
              sessionId: sessionId,
              totalFiles: message.totalFiles,
              totalFolders: message.totalFolders,
              totalBytes: message.totalBytes,
            );
            await db.accountDao.updateScanStats(
              accountId: account.id,
              totalFiles: message.totalFiles,
              totalFolders: message.totalFolders,
              totalBytes: message.totalBytes,
              lastScanAt: DateTime.now(),
            );
            progressController.close();
            receivePort.close();
            _scanIsolate = null;
          });
        } else if (message is _ScanErrorMessage) {
          pendingInserts = pendingInserts.then((_) async {
            await db.scanSessionDao.markFailed(
              sessionId: sessionId,
              error: message.error,
            );
            final error = message.isAuthError
                ? const TokenExpiredException()
                : ScanException(message.error);
            progressController.addError(error);
            progressController.close();
            receivePort.close();
            _scanIsolate = null;
          });
        } else if (message is List) {
          final companions = (message as List<Map<String, dynamic>>)
              .map(_mapToCompanion)
              .toList();
          pendingInserts =
              pendingInserts.then((_) => db.fileRecordDao.insertBatch(companions));
        }
      });

      yield* progressController.stream;
    } catch (e) {
      await db.scanSessionDao.markFailed(
        sessionId: sessionId,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void cancelScan() {
    _cancelPort?.send(true);
    _scanIsolate?.kill(priority: Isolate.immediate);
    _scanIsolate = null;
    _cancelPort = null;
  }

  FileRecordsTableCompanion _mapToCompanion(Map<String, dynamic> data) {
    return FileRecordsTableCompanion.insert(
      id: data['id'] as String,
      accountId: data['accountId'] as String,
      provider: data['provider'] as String,
      name: data['name'] as String,
      path: data['path'] as String,
      sizeBytes: Value(data['sizeBytes'] as int?),
      mimeType: data['mimeType'] as String,
      category: data['category'] as String,
      isFolder: Value(data['isFolder'] as bool? ?? false),
      modifiedAt: data['modifiedAt'] as int,
      accessedAt: Value(data['accessedAt'] as int?),
      parentId: Value(data['parentId'] as String?),
      providerFileId: data['providerFileId'] as String,
      contentHash: Value(data['contentHash'] as String?),
    );
  }
}

// ── Isolate params ────────────────────────────────────────────────────────────

class _ScanWorkerParams {
  const _ScanWorkerParams({
    required this.sendPort,
    required this.cancelPort,
    required this.accountId,
    required this.provider,
    required this.accessToken,
  });

  final SendPort sendPort;
  final SendPort cancelPort;
  final String accountId;
  final CloudProvider provider;
  final String accessToken;
}

// ── Isolate worker ────────────────────────────────────────────────────────────

Future<void> _scanWorker(_ScanWorkerParams params) async {
  int filesScanned = 0;
  int foldersScanned = 0;
  int bytesScanned = 0;
  const uuid = Uuid();
  final List<Map<String, dynamic>> batch = [];

  void flushBatch() {
    if (batch.isNotEmpty) {
      params.sendPort.send(List<Map<String, dynamic>>.from(batch));
      batch.clear();
    }
  }

  void addToBuffer(Map<String, dynamic> record) {
    batch.add(record);
    if (batch.length >= 100) flushBatch();
  }

  void sendProgress(String currentItem) {
    final total = filesScanned + foldersScanned;
    // Send every 25 items; also always send the first item so the banner
    // shows a live count immediately rather than waiting for 100 items.
    if (total == 1 || total % 25 == 0) {
      params.sendPort.send(_ScanProgressMessage(
        ScanProgress(
          filesScanned: filesScanned,
          foldersScanned: foldersScanned,
          bytesScanned: bytesScanned,
          currentPath: currentItem,
        ),
      ));
    }
  }

  try {
    final tokenStorage = _IsolateTokenStorage(params.accessToken);

    switch (params.provider) {
      case CloudProvider.google:
        final client = GoogleDriveClient(
          tokenStorage: tokenStorage,
          authService: _NoopGoogleAuthService(),
        );
        final api = GoogleDriveApi(client: client);

        await for (final page in api.streamAllFiles(params.accountId)) {
          for (final file in page) {
            if (file.isFolder) {
              foldersScanned++;
            } else {
              filesScanned++;
              bytesScanned += file.sizeBytes ?? 0;
            }
            addToBuffer({
              'id': uuid.v4(),
              'accountId': params.accountId,
              'provider': 'google',
              'name': file.name,
              'path': '/${file.name}',
              'sizeBytes': file.sizeBytes,
              'mimeType': file.mimeType,
              'category': file.category.name,
              'isFolder': file.isFolder,
              'modifiedAt': file.modifiedAt.millisecondsSinceEpoch,
              'accessedAt': file.accessedAt?.millisecondsSinceEpoch,
              'parentId': file.parents.isNotEmpty ? file.parents.first : null,
              'providerFileId': file.id,
              'contentHash': file.contentHash,
            });
            sendProgress(file.name);
          }
        }

      case CloudProvider.microsoft:
        final client = OneDriveClient(
          tokenStorage: tokenStorage,
          authService: _NoopMicrosoftAuthService(),
        );
        final api = OneDriveApi(client: client);

        await for (final page in api.streamAllItems(params.accountId)) {
          for (final item in page) {
            if (item.isFolder) {
              foldersScanned++;
            } else {
              filesScanned++;
              bytesScanned += item.sizeBytes ?? 0;
            }
            addToBuffer({
              'id': uuid.v4(),
              'accountId': params.accountId,
              'provider': 'microsoft',
              'name': item.name,
              'path': '${item.path}/${item.name}',
              'sizeBytes': item.sizeBytes,
              'mimeType': item.mimeType ?? 'application/octet-stream',
              'category': item.category.name,
              'isFolder': item.isFolder,
              'modifiedAt': item.modifiedAt.millisecondsSinceEpoch,
              'accessedAt': item.accessedAt?.millisecondsSinceEpoch,
              'parentId': item.parentId,
              'providerFileId': item.id,
              'contentHash': item.contentHash,
            });
            sendProgress(item.name);
          }
        }

      case CloudProvider.dropbox:
        final client = DropboxClient(
          tokenStorage: tokenStorage,
          authService: _NoopDropboxAuthService(),
        );
        final api = DropboxApi(client: client);

        await for (final page in api.streamAllFiles(params.accountId)) {
          for (final file in page) {
            if (file.isFolder) {
              foldersScanned++;
            } else {
              filesScanned++;
              bytesScanned += file.sizeBytes ?? 0;
            }
            final category = FileTypeUtils.categorize(
              mimeType: file.mimeType ?? 'application/octet-stream',
              extension: file.name.contains('.')
                  ? file.name.split('.').last.toLowerCase()
                  : null,
            );
            addToBuffer({
              'id': uuid.v4(),
              'accountId': params.accountId,
              'provider': 'dropbox',
              'name': file.name,
              'path': file.path,
              'sizeBytes': file.sizeBytes,
              'mimeType': file.mimeType ?? 'application/octet-stream',
              'category': category.name,
              'isFolder': file.isFolder,
              'modifiedAt': file.modifiedAt.millisecondsSinceEpoch,
              'accessedAt': null,
              'parentId': null,
              'providerFileId': file.id,
              'contentHash': file.contentHash,
            });
            sendProgress(file.name);
          }
        }

      case CloudProvider.terabox:
        final client = TeraboxClient(
          tokenStorage: tokenStorage,
          authService: _NoopTeraboxAuthService(),
        );
        final api = TeraboxApi(client: client);

        await for (final page in api.streamAllFiles(params.accountId)) {
          for (final file in page) {
            if (file.isFolder) {
              foldersScanned++;
            } else {
              filesScanned++;
              bytesScanned += file.sizeBytes ?? 0;
            }
            final ext = file.name.contains('.')
                ? file.name.split('.').last.toLowerCase()
                : null;
            final category = FileTypeUtils.categorize(
              mimeType: 'application/octet-stream',
              extension: ext,
            );
            addToBuffer({
              'id': uuid.v4(),
              'accountId': params.accountId,
              'provider': 'terabox',
              'name': file.name,
              'path': file.path,
              'sizeBytes': file.sizeBytes,
              'mimeType': 'application/octet-stream',
              'category': category.name,
              'isFolder': file.isFolder,
              'modifiedAt': file.modifiedAt.millisecondsSinceEpoch,
              'accessedAt': null,
              'parentId': null,
              'providerFileId': file.fsId,
              'contentHash': null,
            });
            sendProgress(file.name);
          }
        }

      case CloudProvider.mega:
        // Mega scanning requires mega_sdk — testConnection() already throws
        // MegaScanNotSupportedException before the isolate is spawned.
        // This branch is unreachable in normal operation.
        throw const ScanException(
          'MEGA scanning requires the mega_sdk package. '
          'Please check back in a future update.',
        );

      case CloudProvider.apple:
        // iCloud Drive has no public REST API. The pre-flight check in
        // startScan() throws before the isolate is spawned. This branch
        // is unreachable in normal operation.
        throw const ScanException(
          'iCloud Drive scanning is not yet available. '
          'Native iOS/macOS integration is planned for a future release.',
        );
    }

    flushBatch();
    // Final progress update so the banner reflects exact counts before closing.
    params.sendPort.send(_ScanProgressMessage(
      ScanProgress(
        filesScanned: filesScanned,
        foldersScanned: foldersScanned,
        bytesScanned: bytesScanned,
      ),
    ));
    params.sendPort.send(_ScanCompleteMessage(
      totalFiles: filesScanned,
      totalFolders: foldersScanned,
      totalBytes: bytesScanned,
    ));
  } catch (e) {
    flushBatch();
    final message = e is AppException ? e.message : e.toString();
    params.sendPort.send(_ScanErrorMessage(
      message,
      isAuthError: e is TokenExpiredException,
    ));
  }
}

// ── Isolate-safe stubs ────────────────────────────────────────────────────────

class _IsolateTokenStorage extends TokenStorageService {
  _IsolateTokenStorage(this._token);
  final String _token;

  @override
  Future<String?> getAccessToken(String accountId) async => _token;

  @override
  Future<bool> isTokenValid(String accountId) async => true;
}

class _NoopGoogleAuthService extends GoogleAuthService {
  _NoopGoogleAuthService() : super(tokenStorage: _IsolateTokenStorage(''));
}

class _NoopMicrosoftAuthService extends MicrosoftAuthService {
  _NoopMicrosoftAuthService() : super(tokenStorage: _IsolateTokenStorage(''));
}

class _NoopDropboxAuthService extends DropboxAuthService {
  _NoopDropboxAuthService() : super(tokenStorage: _IsolateTokenStorage(''));
}

class _NoopTeraboxAuthService extends TeraboxAuthService {
  _NoopTeraboxAuthService() : super(tokenStorage: _IsolateTokenStorage(''));
}
