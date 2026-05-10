import '../../../data/repositories/file_repository.dart';
import '../../../domain/models/access_time_stats.dart';
import '../../../domain/models/cloud_file.dart';

class GetAccessTimeStatsUseCase {
  const GetAccessTimeStatsUseCase(this._fileRepo);

  final FileRepository _fileRepo;

  Future<AccessTimeStatsList> execute(String accountId) =>
      _fileRepo.getAccessTimeStats(accountId);

  Future<List<CloudFile>> getFilesForBucket({
    required String accountId,
    required AccessTimeBucket bucket,
    int limit = 100,
    int offset = 0,
  }) =>
      _fileRepo.getFilesByAccessBucket(
        accountId: accountId,
        bucket: bucket,
        limit: limit,
        offset: offset,
      );
}
