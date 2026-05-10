import '../../domain/models/cloud_file.dart';
import '../../domain/models/access_time_stats.dart';
import '../../domain/models/file_type_breakdown.dart';
import '../../domain/models/folder_rank.dart';
import '../../domain/models/duplicate_group.dart';

abstract class FileRepository {
  Future<List<CloudFile>> getFiles({
    required String accountId,
    int limit = 50,
    int offset = 0,
    String? nameFilter,
    String? categoryFilter,
    bool filesOnly = true,
    int? minSizeBytes,
    int? maxSizeBytes,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    String sortColumn = 'size_bytes',
    bool sortAsc = false,
  });

  Future<List<CloudFile>> getLargestFiles(String accountId, {int limit = 15});

  Future<List<CloudFile>> getChildren(String accountId, String parentId);

  Future<List<CloudFile>> getTopLevel(String accountId);

  Future<FileTypeBreakdownList> getFileTypeBreakdown(String accountId);

  Future<List<FolderRank>> getFolderRankings(String accountId);

  Future<AccessTimeStatsList> getAccessTimeStats(String accountId);

  Future<List<CloudFile>> getFilesByAccessBucket({
    required String accountId,
    required AccessTimeBucket bucket,
    int limit = 100,
    int offset = 0,
  });

  Future<List<DuplicateGroup>> findDuplicates(String accountId);

  Future<Map<String, int>> getFileAgeStats(String accountId);
  Future<Map<int, int>> getDepthDistribution(String accountId);
  Future<({int count, int wastedBytes})> getDuplicateSummary(String accountId);
  Future<int> getStaleDataSize(String accountId);
  Future<List<Map<String, dynamic>>> getStaleDataByCategory(String accountId);
  Future<List<Map<String, dynamic>>> findCrossAccountDuplicates();
}
