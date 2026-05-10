enum ScanStatus { running, complete, failed, cancelled }

class ScanProgress {
  const ScanProgress({
    required this.filesScanned,
    required this.foldersScanned,
    required this.bytesScanned,
    this.currentPath = '',
    this.estimatedTotal,
  });

  final int filesScanned;
  final int foldersScanned;
  final int bytesScanned;
  final String currentPath;
  final int? estimatedTotal;

  double get progressFraction {
    if (estimatedTotal == null || estimatedTotal == 0) return 0;
    return (filesScanned / estimatedTotal!).clamp(0.0, 0.95);
  }
}

class ScanSession {
  const ScanSession({
    required this.id,
    required this.accountId,
    required this.startedAt,
    required this.status,
    this.completedAt,
    this.totalFiles = 0,
    this.totalFolders = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  final String id;
  final String accountId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final ScanStatus status;
  final int totalFiles;
  final int totalFolders;
  final int totalBytes;
  final String? errorMessage;

  Duration? get duration => completedAt?.difference(startedAt);

  bool get isRunning => status == ScanStatus.running;
}
