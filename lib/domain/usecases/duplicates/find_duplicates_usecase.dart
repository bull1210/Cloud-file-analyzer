import '../../../data/repositories/file_repository.dart';
import '../../../domain/models/duplicate_group.dart';

class FindDuplicatesUseCase {
  const FindDuplicatesUseCase(this._fileRepo);

  final FileRepository _fileRepo;

  /// Finds duplicate files using metadata-only matching:
  /// files with the same name AND same size are grouped as potential duplicates.
  ///
  /// Note: No file content is downloaded. This is entirely local analysis
  /// of metadata already stored in the local database from the last scan.
  Future<List<DuplicateGroup>> execute(String accountId) =>
      _fileRepo.findDuplicates(accountId);
}
