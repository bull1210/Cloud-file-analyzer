import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cloud_file.dart';
import 'di_providers.dart';

class FilesFilter {
  const FilesFilter({
    this.nameFilter,
    this.categoryFilter,
    this.minSizeBytes,
    this.maxSizeBytes,
    this.modifiedAfter,
    this.modifiedBefore,
    this.sortColumn = 'size_bytes',
    this.sortAsc = false,
  });

  final String? nameFilter;
  final String? categoryFilter;
  final int? minSizeBytes;
  final int? maxSizeBytes;
  final DateTime? modifiedAfter;
  final DateTime? modifiedBefore;
  final String sortColumn;
  final bool sortAsc;

  FilesFilter copyWith({
    String? nameFilter,
    String? categoryFilter,
    int? minSizeBytes,
    int? maxSizeBytes,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    String? sortColumn,
    bool? sortAsc,
  }) =>
      FilesFilter(
        nameFilter: nameFilter ?? this.nameFilter,
        categoryFilter: categoryFilter ?? this.categoryFilter,
        minSizeBytes: minSizeBytes ?? this.minSizeBytes,
        maxSizeBytes: maxSizeBytes ?? this.maxSizeBytes,
        modifiedAfter: modifiedAfter ?? this.modifiedAfter,
        modifiedBefore: modifiedBefore ?? this.modifiedBefore,
        sortColumn: sortColumn ?? this.sortColumn,
        sortAsc: sortAsc ?? this.sortAsc,
      );

  bool get hasActiveFilters =>
      nameFilter != null ||
      categoryFilter != null ||
      minSizeBytes != null ||
      maxSizeBytes != null ||
      modifiedAfter != null ||
      modifiedBefore != null ||
      sortColumn != 'size_bytes' ||
      sortAsc != false;

  FilesFilter clear() => const FilesFilter();
}

final filesFilterProvider =
    StateProvider.family<FilesFilter, String>((_, __) => const FilesFilter());

final filesProvider =
    FutureProvider.family<List<CloudFile>, ({String accountId, int page})>(
        (ref, params) {
  final filter = ref.watch(filesFilterProvider(params.accountId));
  return ref.read(getFilesUseCaseProvider).execute(
        accountId: params.accountId,
        limit: 50,
        offset: params.page * 50,
        nameFilter: filter.nameFilter,
        categoryFilter: filter.categoryFilter,
        minSizeBytes: filter.minSizeBytes,
        maxSizeBytes: filter.maxSizeBytes,
        modifiedAfter: filter.modifiedAfter,
        modifiedBefore: filter.modifiedBefore,
        sortColumn: filter.sortColumn,
        sortAsc: filter.sortAsc,
      );
});

final largestFilesProvider =
    FutureProvider.family<List<CloudFile>, String>((ref, accountId) {
  return ref.read(getLargestFilesUseCaseProvider).execute(accountId);
});
