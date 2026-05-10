import '../../../data/repositories/file_repository.dart';
import '../../../domain/models/storage_summary.dart';

class GetStorageSummaryUseCase {
  const GetStorageSummaryUseCase(this._fileRepo);

  final FileRepository _fileRepo;

  Future<StorageSummary> execute(String accountId) async {
    final largest = await _fileRepo.getLargestFiles(accountId, limit: 1);
    final duplicates = await _fileRepo.findDuplicates(accountId);

    final totalWasted = duplicates.fold<int>(
        0, (sum, g) => sum + g.wastedBytes);

    // We'll get real totals from the account record, but compute from files as fallback
    return StorageSummary(
      accountId: accountId,
      totalFiles: 0, // populated from account record in provider
      totalFolders: 0,
      totalBytes: 0,
      duplicateGroupCount: duplicates.length,
      duplicateWastedBytes: totalWasted,
      largestFile: largest.isNotEmpty ? largest.first : null,
    );
  }
}
