import '../../core/utils/file_type_utils.dart';
import 'cloud_account.dart';

class CloudFile {
  const CloudFile({
    required this.id,
    required this.accountId,
    required this.provider,
    required this.name,
    required this.path,
    this.sizeBytes,
    required this.mimeType,
    required this.category,
    required this.isFolder,
    required this.modifiedAt,
    this.accessedAt,
    this.parentId,
    required this.providerFileId,
    this.contentHash,
  });

  final String id;
  final String accountId;
  final CloudProvider provider;
  final String name;
  final String path;
  final int? sizeBytes;
  final String mimeType;
  final FileCategory category;
  final bool isFolder;
  final DateTime modifiedAt;
  final DateTime? accessedAt;
  final String? parentId;
  final String providerFileId;
  // Algorithm-prefixed hash (e.g. "md5:abc123", "sha1:def456", "quickxor:xyz").
  // Null for Google-native formats (Docs/Sheets/Slides) and OneDrive folders.
  final String? contentHash;

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  @override
  bool operator ==(Object other) => other is CloudFile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
