import '../../core/utils/file_type_utils.dart';

class FileTypeBreakdown {
  const FileTypeBreakdown({
    required this.category,
    required this.fileCount,
    required this.totalBytes,
  });

  final FileCategory category;
  final int fileCount;
  final int totalBytes;

  double fractionOfTotal(int grandTotal) {
    if (grandTotal == 0) return 0;
    return totalBytes / grandTotal;
  }
}

class FileTypeBreakdownList {
  const FileTypeBreakdownList(this.items);

  final List<FileTypeBreakdown> items;

  int get totalBytes => items.fold(0, (sum, item) => sum + item.totalBytes);
  int get totalFiles => items.fold(0, (sum, item) => sum + item.fileCount);

  List<FileTypeBreakdown> get sortedBySize {
    final sorted = List<FileTypeBreakdown>.from(items)
      ..sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    return sorted;
  }
}
