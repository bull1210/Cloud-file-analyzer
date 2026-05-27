import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/file_type_utils.dart';
import '../../../core/errors/app_exception.dart';
import 'google_drive_client.dart';

// Metadata-only model — no file content is fetched
class DriveFileMetadata {
  const DriveFileMetadata({
    required this.id,
    required this.name,
    required this.mimeType,
    this.sizeBytes,
    this.md5Checksum,
    required this.modifiedAt,
    this.accessedAt,
    required this.parents,
    required this.isFolder,
    required this.isTrashed,
  });

  final String id;
  final String name;
  final String mimeType;
  final int? sizeBytes;
  // Hex MD5 of file binary content. Null for Google-native files (Docs/Sheets/Slides).
  final String? md5Checksum;
  final DateTime modifiedAt;
  final DateTime? accessedAt;
  final List<String> parents;
  final bool isFolder;
  final bool isTrashed;

  // Prefixed hash string ready for storage — null when no binary content exists.
  String? get contentHash =>
      md5Checksum != null ? 'md5:$md5Checksum' : null;

  FileCategory get category => FileTypeUtils.categorize(
        mimeType: mimeType,
        extension: name.contains('.')
            ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
            : null,
      );

  static DriveFileMetadata fromJson(Map<String, dynamic> json) {
    final rawSize = json['size'] as String?;
    return DriveFileMetadata(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      sizeBytes: rawSize != null ? int.tryParse(rawSize) : null,
      md5Checksum: json['md5Checksum'] as String?,
      modifiedAt: json['modifiedTime'] != null
          ? DateTime.parse(json['modifiedTime'] as String)
          : DateTime.now(),
      accessedAt: json['viewedByMeTime'] != null
          ? DateTime.parse(json['viewedByMeTime'] as String)
          : null,
      parents: (json['parents'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isFolder: json['mimeType'] == 'application/vnd.google-apps.folder',
      isTrashed: json['trashed'] as bool? ?? false,
    );
  }
}

class DriveAbout {
  const DriveAbout({
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.totalBytes,
    this.usedBytes,
  });

  final String email;
  final String displayName;
  final String? photoUrl;
  final int? totalBytes;
  final int? usedBytes;

  static DriveAbout fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final quota = json['storageQuota'] as Map<String, dynamic>?;
    return DriveAbout(
      email: user?['emailAddress'] as String? ?? '',
      displayName: user?['displayName'] as String? ?? '',
      photoUrl: user?['photoLink'] as String?,
      totalBytes: quota != null
          ? int.tryParse(quota['limit'] as String? ?? '')
          : null,
      usedBytes: quota != null
          ? int.tryParse(quota['usage'] as String? ?? '')
          : null,
    );
  }
}

class GoogleDriveApi {
  GoogleDriveApi({required this.client});

  final GoogleDriveClient client;

  Future<DriveAbout> getAbout(String accountId) async {
    final response = await client.get<Map<String, dynamic>>(
      GoogleDriveEndpoints.aboutDrive,
      accountId: accountId,
      queryParameters: {
        'fields': 'user(emailAddress,displayName,photoLink),storageQuota',
      },
    );
    return DriveAbout.fromJson(response.data!);
  }

  /// Fetches one page of file metadata. No file content is downloaded.
  Future<({List<DriveFileMetadata> files, String? nextPageToken})> listFilesPage({
    required String accountId,
    String? pageToken,
    int pageSize = AppConstants.scanPageSize,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      GoogleDriveEndpoints.filesList,
      accountId: accountId,
      queryParameters: {
        'fields': GoogleDriveEndpoints.listFields,
        'pageSize': pageSize,
        'q': 'trashed = false',
        if (pageToken != null) 'pageToken': pageToken,
      },
    );

    final data = response.data!;
    final files = (data['files'] as List<dynamic>? ?? [])
        .map((e) => DriveFileMetadata.fromJson(e as Map<String, dynamic>))
        .where((f) => !f.isTrashed)
        .toList();

    return (
      files: files,
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  /// Moves a file to the user's Google Drive Trash (not permanently deleted).
  /// Requires the `drive` OAuth scope — will throw 403 with `drive.metadata.readonly`.
  Future<void> trashFile(String accountId, String fileId) async {
    await client.patch<Map<String, dynamic>>(
      '${GoogleDriveEndpoints.filesList}/$fileId',
      accountId: accountId,
      data: {'trashed': true},
    );
  }

  /// Stream all file metadata pages. Yields batches for DB insertion.
  /// Nothing is downloaded — only file metadata (name, size, dates, MIME type).
  Stream<List<DriveFileMetadata>> streamAllFiles(String accountId) async* {
    String? pageToken;
    int retryCount = 0;
    const maxRetries = 5;

    do {
      try {
        final page = await listFilesPage(accountId: accountId, pageToken: pageToken);
        if (page.files.isNotEmpty) yield page.files;
        pageToken = page.nextPageToken;
        retryCount = 0;

        // Rate limit courtesy delay between pages
        if (pageToken != null) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } on RateLimitException catch (e) {
        if (retryCount >= maxRetries) rethrow;
        retryCount++;
        final delay = Duration(seconds: e.retryAfter ?? (2 << retryCount));
        await Future.delayed(delay);
      }
    } while (pageToken != null);
  }
}
