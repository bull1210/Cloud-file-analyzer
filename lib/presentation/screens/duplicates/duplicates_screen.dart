import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/int_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/cloud_file.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duplicates_provider.dart';
import '../../widgets/cloud_provider_icon.dart';
import '../../widgets/empty_state.dart';
import 'widgets/duplicate_group_card.dart';
import '../../../domain/models/cloud_account.dart';

class DuplicatesScreen extends ConsumerWidget {
  const DuplicatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(activeAccountProvider);
    if (account == null || !account.hasBeenScanned) {
      return EmptyState(
        icon: Icons.copy_outlined,
        title: 'No scan data',
        subtitle: account == null
            ? 'Select an account first.'
            : 'Scan "${account.label}" to find duplicates.',
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Duplicate Files — ${account.label}',
              overflow: TextOverflow.ellipsis),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'This Account'),
              Tab(text: 'All Accounts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ThisAccountTab(account: account),
            const _AllAccountsTab(),
          ],
        ),
      ),
    );
  }
}

class _ThisAccountTab extends ConsumerWidget {
  const _ThisAccountTab({required this.account});

  final CloudAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(duplicateGroupsProvider(account.id));
    final strategy = ref.watch(duplicateStrategyProvider);

    // Show SnackBar when deletion completes or fails
    ref.listen<DeletionState>(deletionNotifierProvider, (_, next) {
      if (next.isDeleting || next.isIdle) return;
      if (next.result != null) {
        final r = next.result!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              r.hasErrors
                  ? '${r.deleted} moved to Trash · ${r.failed.length} failed'
                  : '${r.deleted} file${r.deleted == 1 ? '' : 's'} moved to Trash',
            ),
            backgroundColor: r.hasErrors ? AppColors.warning : AppColors.success,
            behavior: SnackBarBehavior.floating,
            action: r.hasErrors
                ? SnackBarAction(
                    label: 'Details',
                    textColor: Colors.white,
                    onPressed: () =>
                        _showFailureDetails(context, r.failed),
                  )
                : null,
          ),
        );
        ref.read(deletionNotifierProvider.notifier).clearResult();
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${next.error}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(deletionNotifierProvider.notifier).clearResult();
      }
    });

    return groupsAsync.when(
      loading: () => const LoadingState(message: 'Analyzing duplicates…'),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error',
        subtitle: e.toString(),
      ),
      data: (groups) {
        final totalWasted = groups.fold<int>(0, (s, g) => s + g.wastedBytes);
        final exactGroups = groups.where((g) => g.hasHashMatch).toList();
        final allSuggested = exactGroups
            .expand((g) => strategy == DuplicateKeepStrategy.newest
                ? g.suggestedForDeletion
                : g.suggestedForDeletionKeepOldest)
            .toList();
        final deletionState = ref.watch(deletionNotifierProvider);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    SegmentedButton<DuplicateKeepStrategy>(
                      segments: const [
                        ButtonSegment(
                          value: DuplicateKeepStrategy.newest,
                          label: Text('Keep Newest'),
                          icon: Icon(Icons.new_releases_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: DuplicateKeepStrategy.oldest,
                          label: Text('Keep Oldest'),
                          icon: Icon(Icons.history_outlined, size: 16),
                        ),
                      ],
                      selected: {strategy},
                      onSelectionChanged: (s) => ref
                          .read(duplicateStrategyProvider.notifier)
                          .state = s.first,
                      style: ButtonStyle(
                        textStyle: WidgetStateProperty.all(
                          const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (allSuggested.isNotEmpty)
                      TextButton.icon(
                        onPressed: deletionState.isDeleting
                            ? null
                            : () => _confirmDeleteAll(
                                  context,
                                  ref,
                                  allSuggested,
                                  account.id,
                                ),
                        icon: const Icon(Icons.auto_delete_outlined, size: 16),
                        label: Text('Delete all (${allSuggested.length})'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (groups.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No duplicates found',
                  subtitle:
                      'No files with the same name and size were detected.',
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _SummaryBanner(
                    groupCount: groups.length,
                    exactCount: exactGroups.length,
                    wastedBytes: totalWasted,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _MetadataDisclaimer(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => DuplicateGroupCard(
                      group: groups[index],
                      groupIndex: index + 1,
                      strategy: strategy,
                      accountId: account.id,
                    ),
                    childCount: groups.length,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteAll(
    BuildContext context,
    WidgetRef ref,
    List<CloudFile> files,
    String accountId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move all suggested to Trash?'),
        content: Text(
          '${files.length} file${files.length == 1 ? '' : 's'} will be moved to your '
          'cloud Trash/Recycle Bin. Only exact hash-matched duplicates are included. '
          'You can restore them from Trash if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Move ${files.length} to Trash'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(deletionNotifierProvider.notifier)
          .deleteFiles(files, accountId);
    }
  }

  void _showFailureDetails(
    BuildContext context,
    List<(CloudFile, String)> failed,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Failed deletions (${failed.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...failed.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CloudProviderIcon(
                        provider: entry.$1.provider, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.$1.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            entry.$2,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── All Accounts cross-account duplicates tab ─────────────────────────────────

class _AllAccountsTab extends ConsumerWidget {
  const _AllAccountsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crossDupsAsync = ref.watch(crossAccountDuplicatesProvider);
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];

    return crossDupsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error',
        subtitle: e.toString(),
      ),
      data: (dups) {
        if (dups.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No cross-account duplicates',
            subtitle:
                'Files that exist in more than one cloud account will appear here.',
          );
        }

        final totalWaste = dups.fold<int>(
          0,
          (sum, d) =>
              sum +
              ((d['total_copies'] as int) - 1) * (d['size_bytes'] as int),
        );

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.compare_arrows_outlined,
                          color: Color(0xFF8B5CF6), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${dups.length} duplicate group${dups.length > 1 ? 's' : ''} across accounts',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${totalWaste.toStorageString()} wasted across cloud accounts',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF8B5CF6),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dup = dups[index];
                    final accountIds =
                        (dup['account_ids'] as List).cast<String>();
                    final copies = dup['total_copies'] as int;
                    final bytes = dup['size_bytes'] as int;
                    final waste = (copies - 1) * bytes;

                    final accountLabels = accountIds
                        .map((id) => accounts
                            .where((a) => a.id == id)
                            .map((a) => a.label)
                            .firstOrNull ?? id)
                        .toList();

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.insert_drive_file_outlined,
                                    size: 16, color: AppColors.info),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dup['name'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      bytes.toStorageString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      'Waste: ${waste.toStorageString()}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: accountLabels
                                  .map((label) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF8B5CF6)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          label,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: dups.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Screen-level widgets ─────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.groupCount,
    required this.exactCount,
    required this.wastedBytes,
  });

  final int groupCount;
  final int exactCount;
  final int wastedBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$groupCount duplicate group${groupCount > 1 ? 's' : ''} found'
                  '${exactCount > 0 ? ' · $exactCount exact' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${wastedBytes.toStorageString()} potentially wasted',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                      height: 1.5,
                    ),
                children: const [
                  TextSpan(
                    text: 'Exact ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'duplicates are verified using MD5/SHA content hashes '
                        '— byte-for-byte identical. ',
                  ),
                  TextSpan(
                    text: 'Probable ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'duplicates match only by name and size (no hash available). '
                        'Delete is enabled for exact matches only. '
                        'No file content is downloaded to this device.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
