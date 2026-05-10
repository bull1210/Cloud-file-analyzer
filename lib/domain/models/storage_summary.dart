import 'cloud_file.dart';

class StorageSummary {
  const StorageSummary({
    required this.accountId,
    required this.totalFiles,
    required this.totalFolders,
    required this.totalBytes,
    required this.duplicateGroupCount,
    required this.duplicateWastedBytes,
    this.largestFile,
  });

  final String accountId;
  final int totalFiles;
  final int totalFolders;
  final int totalBytes;
  final int duplicateGroupCount;
  final int duplicateWastedBytes;
  final CloudFile? largestFile;

  static const StorageSummary empty = StorageSummary(
    accountId: '',
    totalFiles: 0,
    totalFolders: 0,
    totalBytes: 0,
    duplicateGroupCount: 0,
    duplicateWastedBytes: 0,
  );
}
