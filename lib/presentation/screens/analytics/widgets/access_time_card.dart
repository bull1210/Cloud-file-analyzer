import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/access_time_stats.dart';
import '../../../navigation/route_names.dart';
import '../../../providers/analytics_provider.dart';
import '../../../widgets/empty_state.dart';

class AccessTimeTab extends ConsumerWidget {
  const AccessTimeTab({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(accessTimeStatsProvider(accountId));

    return statsAsync.when(
      loading: () => const LoadingState(message: 'Analyzing access times…'),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error',
        subtitle: e.toString(),
      ),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withValues(alpha:0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Access time data is provided by your cloud provider as part of file metadata. Tap any category to see the full file list.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.info,
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...AccessTimeBucket.values.map((bucket) {
                final stat = stats.forBucket(bucket);
                return _AccessTimeBucketCard(
                  stat: stat,
                  accountId: accountId,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _AccessTimeBucketCard extends StatelessWidget {
  const _AccessTimeBucketCard({
    required this.stat,
    required this.accountId,
  });

  final AccessTimeStats stat;
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _styling(stat.bucket);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: stat.fileCount > 0
              ? () => context.go(
                    RouteName.accessBucketFiles,
                    extra: {
                      'bucket': stat.bucket,
                      'accountId': accountId,
                    },
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.bucket.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat.bucket.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${stat.fileCount}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700, color: color),
                    ),
                    Text(
                      stat.totalBytes.toStorageShort(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (stat.fileCount > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, IconData) _styling(AccessTimeBucket bucket) {
    switch (bucket) {
      case AccessTimeBucket.recentSixMonths:
        return (AppColors.success, Icons.check_circle_outline);
      case AccessTimeBucket.notAccessedOneYear:
        return (AppColors.warning, Icons.schedule_outlined);
      case AccessTimeBucket.notAccessedTwoYears:
        return (AppColors.error, Icons.warning_amber_outlined);
      case AccessTimeBucket.never:
        return (AppColors.darkTextMuted, Icons.do_not_disturb_outlined);
    }
  }
}
