import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/access_time_stats.dart';
import '../../domain/models/cloud_file.dart';
import '../../domain/models/file_type_breakdown.dart';
import '../../domain/models/folder_rank.dart';
import 'di_providers.dart';

// Controls which tab opens when navigating programmatically to analytics.
// Callers set this before calling context.go(RouteName.analytics).
final analyticsInitialTabProvider = StateProvider<int>((_) => 0);


final fileTypeBreakdownProvider =
    FutureProvider.family<FileTypeBreakdownList, String>((ref, accountId) {
  ref.keepAlive();
  return ref.read(getFileTypeBreakdownUseCaseProvider).execute(accountId);
});

final folderRankingsProvider =
    FutureProvider.family<List<FolderRank>, String>((ref, accountId) {
  return ref.read(getFolderRankingsUseCaseProvider).execute(accountId);
});

final accessTimeStatsProvider =
    FutureProvider.family<AccessTimeStatsList, String>((ref, accountId) {
  ref.keepAlive();
  return ref.read(getAccessTimeStatsUseCaseProvider).execute(accountId);
});

final accessTimeBucketFilesProvider = FutureProvider.family<List<CloudFile>,
    ({String accountId, AccessTimeBucket bucket, int offset})>((ref, params) {
  return ref
      .read(getAccessTimeStatsUseCaseProvider)
      .getFilesForBucket(
        accountId: params.accountId,
        bucket: params.bucket,
        limit: 100,
        offset: params.offset,
      );
});

final largestFilesAnalyticsProvider =
    FutureProvider.family<List<CloudFile>, String>((ref, accountId) {
  ref.keepAlive();
  return ref.read(getLargestFilesUseCaseProvider).execute(accountId, limit: 15);
});

final largestFilesDetailProvider =
    FutureProvider.family<List<CloudFile>, String>((ref, accountId) {
  return ref.read(getLargestFilesUseCaseProvider).execute(accountId, limit: 20);
});

final fileTypesCountProvider =
    FutureProvider.family<int, String>((ref, accountId) async {
  final breakdown = await ref.watch(fileTypeBreakdownProvider(accountId).future);
  return breakdown.items.length;
});

final fileAgeStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, accountId) {
  return ref.read(fileRepositoryProvider).getFileAgeStats(accountId);
});

final depthDistributionProvider =
    FutureProvider.family<Map<int, int>, String>((ref, accountId) {
  return ref.read(fileRepositoryProvider).getDepthDistribution(accountId);
});

final duplicateSummaryProvider = FutureProvider.family<
    ({int count, int wastedBytes}), String>((ref, accountId) {
  return ref.read(fileRepositoryProvider).getDuplicateSummary(accountId);
});

final staleDataSizeProvider =
    FutureProvider.family<int, String>((ref, accountId) {
  return ref.read(fileRepositoryProvider).getStaleDataSize(accountId);
});

final staleDataByCategoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, accountId) {
  return ref.read(fileRepositoryProvider).getStaleDataByCategory(accountId);
});

final crossAccountDuplicatesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(fileRepositoryProvider).findCrossAccountDuplicates();
});
