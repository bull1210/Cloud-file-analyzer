import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/file_type_utils.dart';
import 'onedrive_client.dart';

// Metadata-only model — no file content is fetched
class OneDriveItemMetadata {
  const OneDriveItemMetadata({
    required this.id,
    required this.name,
    this.sizeBytes,
    required this.modifiedAt,
    this.accessedAt,
    required this.isFolder,
    required this.parentId,
    required this.path,
    this.mimeType,
    this.md5Hash,
    this.sha1Hash,
    this.sha256Hash,
    this.quickXorHash,
  });

  final String id;
  final String name;
  final int? sizeBytes;
  final DateTime modifiedAt;
  final DateTime? accessedAt;
  final bool isFolder;
  final String? parentId;
  final String path;
  final String? mimeType;

  // Hashes from file.hashes — at most one will be non-null per file on a given tenant.
  // Personal OneDrive: typically sha1Hash + quickXorHash.
  // Business OneDrive / SharePoint: typically only quickXorHash.
  final String? md5Hash;
  final String? sha1Hash;
  final String? sha256Hash;
  final String? quickXorHash;

  // Returns the best available hash with an algorithm prefix, or null for folders.
  // Priority: md5 > sha256 > sha1 > quickXorHash (matches user preference).
  String? get contentHash {
    if (md5Hash != null) return 'md5:$md5Hash';
    if (sha256Hash != null) return 'sha256:$sha256Hash';
    if (sha1Hash != null) return 'sha1:$sha1Hash';
    if (quickXorHash != null) return 'quickxor:$quickXorHash';
    return null;
  }

  FileCategory get category => FileTypeUtils.categorize(
        mimeType: mimeType,
        extension: name.contains('.')
            ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
            : null,
      );

  static OneDriveItemMetadata fromJson(Map<String, dynamic> json) {
    final parentRef = json['parentReference'] as Map<String, dynamic>?;
    final fileInfo = json['file'] as Map<String, dynamic>?;
    final folderInfo = json['folder'] as Map<String, dynamic>?;
    final fsInfo = json['fileSystemInfo'] as Map<String, dynamic>?;
    final hashes = fileInfo?['hashes'] as Map<String, dynamic>?;

    return OneDriveItemMetadata(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled',
      sizeBytes: json['size'] as int?,
      modifiedAt: fsInfo?['lastModifiedDateTime'] != null
          ? DateTime.parse(fsInfo!['lastModifiedDateTime'] as String)
          : json['lastModifiedDateTime'] != null
              ? DateTime.parse(json['lastModifiedDateTime'] as String)
              : DateTime.now(),
      accessedAt: fsInfo?['lastAccessedDateTime'] != null
          ? DateTime.parse(fsInfo!['lastAccessedDateTime'] as String)
          : null,
      isFolder: folderInfo != null,
      parentId: parentRef?['id'] as String?,
      path: parentRef?['path'] as String? ?? '/',
      mimeType: fileInfo?['mimeType'] as String?,
      md5Hash: hashes?['md5Hash'] as String?,
      sha1Hash: hashes?['sha1Hash'] as String?,
      sha256Hash: hashes?['sha256Hash'] as String?,
      quickXorHash: hashes?['quickXorHash'] as String?,
    );
  }
}

class OneDriveUserInfo {
  const OneDriveUserInfo({
    required this.email,
    required this.displayName,
    this.totalBytes,
    this.usedBytes,
  });

  final String email;
  final String displayName;
  final int? totalBytes;
  final int? usedBytes;
}

class OneDriveApi {
  OneDriveApi({required this.client});

  final OneDriveClient client;

  Future<OneDriveUserInfo> getUserInfo() async {
    final userResp = await client.get<Map<String, dynamic>>(
      OneDriveEndpoints.userInfo,
      queryParameters: {'\$select': 'mail,displayName,userPrincipalName'},
    );
    final driveResp = await client.get<Map<String, dynamic>>(
      OneDriveEndpoints.driveInfo,
      queryParameters: {'\$select': 'quota'},
    );

    final userData = userResp.data!;
    final driveData = driveResp.data!;
    final quota = driveData['quota'] as Map<String, dynamic>?;

    return OneDriveUserInfo(
      email: userData['mail'] as String? ??
          userData['userPrincipalName'] as String? ?? '',
      displayName: userData['displayName'] as String? ?? '',
      totalBytes: quota?['total'] as int?,
      usedBytes: quota?['used'] as int?,
    );
  }

  /// Fetches one page of children for a given item (metadata only — no content).
  Future<({List<OneDriveItemMetadata> items, String? nextLink})>
      listChildrenPage({
    required String itemId,
    String? nextLink,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      nextLink ?? '${OneDriveEndpoints.driveItems}/$itemId/children',
      queryParameters: nextLink == null
          ? {
              '\$select': OneDriveEndpoints.itemFields,
              '\$top': 200,
            }
          : null,
    );

    final data = response.data!;
    final items = (data['value'] as List<dynamic>? ?? [])
        .map((e) => OneDriveItemMetadata.fromJson(e as Map<String, dynamic>))
        .toList();

    return (
      items: items,
      nextLink: data['@odata.nextLink'] as String?,
    );
  }

  /// Moves an item to the user's OneDrive Recycle Bin (not permanently deleted).
  /// Requires the `Files.ReadWrite` scope — will throw 403 with `Files.Read` only.
  Future<void> deleteItem(String itemId) async {
    await client.delete<void>(
      '${OneDriveEndpoints.driveItems}/$itemId',
    );
  }

  /// Stream all OneDrive metadata using BFS queue to avoid stack overflow.
  /// No file content is downloaded — only names, sizes, dates, MIME types.
  Stream<List<OneDriveItemMetadata>> streamAllItems() async* {
    // Queue-based BFS: start with the root drive
    final rootResp = await client.get<Map<String, dynamic>>(
      '/me/drive/root',
      queryParameters: {'\$select': OneDriveEndpoints.itemFields},
    );
    final rootId = rootResp.data!['id'] as String;

    final queue = <String>[rootId];
    int retryCount = 0;

    while (queue.isNotEmpty) {
      final itemId = queue.removeAt(0);
      String? nextLink;

      do {
        try {
          final page = await listChildrenPage(
            itemId: itemId,
            nextLink: nextLink,
          );
          if (page.items.isNotEmpty) {
            yield page.items;
            // Add subfolders to queue for recursive traversal
            for (final item in page.items) {
              if (item.isFolder) queue.add(item.id);
            }
          }
          nextLink = page.nextLink;
          retryCount = 0;
          if (nextLink != null) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } on RateLimitException catch (e) {
          if (retryCount >= 5) rethrow;
          retryCount++;
          await Future.delayed(
              Duration(seconds: e.retryAfter ?? (2 << retryCount)));
        }
      } while (nextLink != null);
    }
  }
}
