class FolderRank {
  const FolderRank({
    required this.folderId,
    required this.folderName,
    required this.folderPath,
    required this.accountId,
    required this.totalBytes,
    required this.fileCount,
  });

  final String folderId;
  final String folderName;
  final String folderPath;
  final String accountId;
  final int totalBytes;
  final int fileCount;
}
