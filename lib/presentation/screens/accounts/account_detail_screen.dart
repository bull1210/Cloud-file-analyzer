import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/extensions/int_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/cloud_account.dart';
import '../../navigation/route_names.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import '../../widgets/cloud_provider_icon.dart';
import '../../widgets/empty_state.dart';
import '../analytics/widgets/file_type_pie_chart.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return accountsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Error',
          subtitle: e.toString(),
        ),
      ),
      data: (accounts) {
        final account = accounts.where((a) => a.id == accountId).firstOrNull;
        if (account == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Account'),
              leading: BackButton(onPressed: () => context.go(RouteName.accounts)),
            ),
            body: const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Account not found',
              subtitle: 'This account may have been removed.',
            ),
          );
        }
        return _AccountDetailBody(account: account);
      },
    );
  }
}

class _AccountDetailBody extends ConsumerWidget {
  const _AccountDetailBody({required this.account});

  final CloudAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final isScanning = scanState.isScanning &&
        scanState.scanningAccountId == account.id;

    final providerColor = account.provider == CloudProvider.google
        ? AppColors.googleBlue
        : AppColors.microsoftBlue;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero banner
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(RouteName.accounts),
              tooltip: 'Back to Cloud Storage',
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      providerColor,
                      providerColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CloudProviderIcon(
                              provider: account.provider,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.displayName.isNotEmpty
                                        ? account.displayName
                                        : account.email,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    account.email,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (account.hasBeenScanned)
                              Text(
                                account.totalBytes.toStorageString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                        if (account.lastScanAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Last synced ${account.lastScanAt!.toRelativeString()}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.lock_reset_outlined),
                tooltip: 'Re-authenticate',
                onPressed: () =>
                    ref.read(authProvider.notifier).reauthAccount(account.id),
              ),
              IconButton(
                icon: isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                tooltip: isScanning ? 'Syncing…' : 'Sync Now',
                onPressed: scanState.isScanning
                    ? null
                    : () =>
                        ref.read(scanProvider.notifier).startScan(account),
              ),
              IconButton(
                icon: const Icon(Icons.folder_open_outlined),
                tooltip: 'Browse Files',
                onPressed: () {
                  ref.read(activeAccountIdProvider.notifier).state = account.id;
                  context.go(RouteName.files);
                },
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Duplicates',
                onPressed: () {
                  ref.read(activeAccountIdProvider.notifier).state = account.id;
                  context.go(RouteName.duplicates);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          if (!account.hasBeenScanned)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.cloud_sync_outlined,
                title: 'Not synced yet',
                subtitle: 'Sync this account to see analytics.',
                action: () =>
                    ref.read(scanProvider.notifier).startScan(account),
                actionLabel: 'Sync Now',
              ),
            )
          else ...[
            // 4-stat summary row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _StatSummaryRow(account: account),
              ),
            ),

            // Two-column: pie chart + largest files
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 700) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SectionCard(
                                title: 'Files by Type',
                                child: SizedBox(
                                  height: 380,
                                  child: FileTypePieChart(accountId: account.id),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SectionCard(
                                title: 'Top 20 Largest Files',
                                child: _LargestFilesDetail(
                                    accountId: account.id),
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _SectionCard(
                            title: 'Files by Type',
                            child: SizedBox(
                              height: 380,
                              child: FileTypePieChart(accountId: account.id),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Top 20 Largest Files',
                            child:
                                _LargestFilesDetail(accountId: account.id),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatSummaryRow extends ConsumerWidget {
  const _StatSummaryRow({required this.account});

  final CloudAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileTypesAsync = ref.watch(fileTypesCountProvider(account.id));
    final fileTypesCount = fileTypesAsync.valueOrNull ?? 0;

    return Row(
      children: [
        Expanded(
          child: _SummaryStat(
            label: 'Total Files',
            value: account.totalFiles.toFileCountLabel(),
            icon: Icons.insert_drive_file_outlined,
            iconColor: AppColors.brand,
          ),
        ),
        Expanded(
          child: _SummaryStat(
            label: 'Folders',
            value: account.totalFolders.toFolderCountLabel(),
            icon: Icons.folder_outlined,
            iconColor: AppColors.warning,
          ),
        ),
        Expanded(
          child: _SummaryStat(
            label: 'Storage Used',
            value: account.totalBytes.toStorageString(),
            icon: Icons.storage_outlined,
            iconColor: AppColors.info,
          ),
        ),
        Expanded(
          child: _SummaryStat(
            label: 'File Types',
            value: '$fileTypesCount types',
            icon: Icons.category_outlined,
            iconColor: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

// Shows top 20 largest files using the detail provider
class _LargestFilesDetail extends ConsumerWidget {
  const _LargestFilesDetail({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(largestFilesDetailProvider(accountId));

    return filesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e'),
      ),
      data: (files) {
        if (files.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No files found.')),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor:
                    AppColors.chartPalette[index % AppColors.chartPalette.length]
                        .withValues(alpha: 0.15),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.chartPalette[
                        index % AppColors.chartPalette.length],
                  ),
                ),
              ),
              title: Text(
                file.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              trailing: Text(
                file.sizeBytes?.toStorageString() ?? '—',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
              ),
            );
          },
        );
      },
    );
  }
}
