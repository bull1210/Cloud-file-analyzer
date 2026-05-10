import '../../../data/repositories/file_repository.dart';
import '../../../domain/models/cloud_file.dart';

class GetFilesUseCase {
  const GetFilesUseCase(this._fileRepo);

  final FileRepository _fileRepo;

  Future<List<CloudFile>> execute({
    required String accountId,
    int limit = 50,
    int offset = 0,
    String? nameFilter,
    String? categoryFilter,
    int? minSizeBytes,
    int? maxSizeBytes,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    String sortColumn = 'size_bytes',
    bool sortAsc = false,
  }) =>
      _fileRepo.getFiles(
        accountId: accountId,
        limit: limit,
        offset: offset,
        nameFilter: nameFilter,
        categoryFilter: categoryFilter,
        filesOnly: true,
        minSizeBytes: minSizeBytes,
        maxSizeBytes: maxSizeBytes,
        modifiedAfter: modifiedAfter,
        modifiedBefore: modifiedBefore,
        sortColumn: sortColumn,
        sortAsc: sortAsc,
      );
}
