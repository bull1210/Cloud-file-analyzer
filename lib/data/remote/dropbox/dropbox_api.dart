import '../../../core/logging/app_logger.dart';
import 'dropbox_client.dart';

class DropboxUserInfo {
  const DropboxUserInfo({
    required this.accountId,
    required this.email,
    required this.displayName,
  });

  final String accountId;
  final String email;
  final String displayName;
}

class DropboxFileItem {
  const DropboxFileItem({
    required this.id,
    required this.name,
    required this.path,
    required this.isFolder,
    required this.modifiedAt,
    this.sizeBytes,
    this.contentHash,
    this.mimeType,
  });

  final String id;
  final String name;
  final String path;
  final bool isFolder;
  final DateTime modifiedAt;
  final int? sizeBytes;
  final String? contentHash;
  final String? mimeType;
}

class DropboxApi {
  DropboxApi({required this.client});

  final DropboxClient client;

  Future<DropboxUserInfo> getCurrentAccount() async {
    final resp = await client.postEmpty<Map<String, dynamic>>(
      '/users/get_current_account',
    );
    final data = resp.data!;
    final name = data['name'] as Map<String, dynamic>?;
    return DropboxUserInfo(
      accountId: data['account_id'] as String,
      email: data['email'] as String? ?? '',
      displayName: name?['display_name'] as String? ?? '',
    );
  }

  Future<void> testConnection() async {
    logger.log('DropboxApi', 'testConnection() starting…');
    await getCurrentAccount();
    logger.log('DropboxApi', 'testConnection() OK');
  }

  Stream<List<DropboxFileItem>> streamAllFiles() async* {
    logger.log('DropboxApi', 'streamAllFiles() starting');

    var resp = await client.post<Map<String, dynamic>>(
      '/files/list_folder',
      data: {
        'path': '',
        'recursive': true,
        'include_media_info': false,
        'include_deleted': false,
        'include_has_explicit_shared_members': false,
        'include_mounted_folders': true,
        'limit': 2000,
      },
    );

    int pageCount = 0;
    int totalItems = 0;

    while (true) {
      final data = resp.data!;
      final entries = (data['entries'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final hasMore = data['has_more'] as bool? ?? false;
      final cursor = data['cursor'] as String?;

      final items = entries.map(_mapEntry).toList();
      pageCount++;
      totalItems += items.length;
      logger.log('DropboxApi',
          'streamAllFiles() page=$pageCount items=${items.length} total=$totalItems');

      if (items.isNotEmpty) yield items;

      if (!hasMore || cursor == null) break;

      resp = await client.post<Map<String, dynamic>>(
        '/files/list_folder/continue',
        data: {'cursor': cursor},
      );
    }

    logger.log('DropboxApi', 'streamAllFiles() done — total=$totalItems');
  }

  DropboxFileItem _mapEntry(Map<String, dynamic> e) {
    final tag = e['.tag'] as String? ?? 'file';
    final isFolder = tag == 'folder';
    return DropboxFileItem(
      id: e['id'] as String? ?? e['path_lower'] as String? ?? '',
      name: e['name'] as String? ?? '',
      path: e['path_display'] as String? ?? '/',
      isFolder: isFolder,
      modifiedAt: isFolder
          ? DateTime.now()
          : _parseDate(e['client_modified'] as String?),
      sizeBytes: isFolder ? null : e['size'] as int?,
      contentHash: e['content_hash'] as String?,
      mimeType: isFolder ? null : _guessMimeType(e['name'] as String? ?? ''),
    );
  }

  DateTime _parseDate(String? raw) {
    if (raw == null) return DateTime.now();
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _guessMimeType(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    const map = {
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
      'gif': 'image/gif', 'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'mp4': 'video/mp4', 'mov': 'video/quicktime', 'avi': 'video/x-msvideo',
      'mp3': 'audio/mpeg', 'zip': 'application/zip',
      'txt': 'text/plain', 'csv': 'text/csv',
    };
    return map[ext] ?? 'application/octet-stream';
  }
}
