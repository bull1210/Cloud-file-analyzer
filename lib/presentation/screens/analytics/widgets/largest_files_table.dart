import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/cloud_file.dart';
import '../../../providers/analytics_provider.dart';
import '../../../widgets/cloud_provider_icon.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/open_in_cloud_button.dart';

class LargestFilesTable extends ConsumerWidget {
  const LargestFilesTable({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(largestFilesAnalyticsProvider(accountId));

    return filesAsync.when(
      loading: () => const LoadingState(message: 'Computing largest files…'),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error',
        subtitle: e.toString(),
      ),
      data: (files) {
        if (files.isEmpty) {
          return const EmptyState(
            icon: Icons.folder_open_outlined,
            title: 'No files found',
            subtitle: 'Scan your account to see file sizes.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: files.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
          itemBuilder: (context, index) {
            final file = files[index];
            return _LargestFileTile(rank: index + 1, file: file);
          },
        );
      },
    );
  }
}

class _LargestFileTile extends StatelessWidget {
  const _LargestFileTile({required this.rank, required this.file});

  final int rank;
  final CloudFile file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _rankColor(rank).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _rankColor(rank),
              fontSize: 14,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              file.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            file.sizeBytes?.toStorageString() ?? '—',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMM d, y').format(file.modifiedAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          CloudProviderIcon(provider: file.provider, size: 11),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              file.path,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: OpenInCloudButton(file: file),
      isThreeLine: false,
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.brand;
  }
}
