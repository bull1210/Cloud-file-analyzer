import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/int_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/cloud_account.dart';
import '../../../domain/models/scan_session.dart';
import '../../navigation/route_names.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import '../../widgets/cloud_provider_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/open_in_cloud_button.dart';
import '../analytics/widgets/file_type_pie_chart.dart';
import 'widgets/scan_progress_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
    final scanState = ref.watch(scanProvider);
    final activeAccount = ref.watch(activeAccountProvider);

    if (accounts.isEmpty) {
      return const EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'No accounts connected',
        subtitle: 'Go to Cloud Storage to add a cloud account.',
      );
    }

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Dashboard'),
          pinned: true,
        ),
        if (scanState.isScanning)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ScanProgressBanner(
                progress: scanState.progress ??
                    const ScanProgress(
                      filesScanned: 0,
                      foldersScanned: 0,
                      bytesScanned: 0,
                    ),
              ),
            ),
          ),
        if (scanState.error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _ErrorBanner(
                error: scanState.error!,
                onDismiss: () => ref.read(scanProvider.notifier).clearError(),
              ),
            ),
          ),

        // ── Account selector ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _AccountSelectorRow(
              accounts: accounts,
              selectedId: activeAccount?.id,
              onSelect: (id) =>
                  ref.read(activeAccountIdProvider.notifier).state = id,
            ),
          ),
        ),

        // ── Dashboard content for the selected account ────────────────────
        if (activeAccount != null)
          SliverToBoxAdapter(
            child: _AccountDashboardSection(account: activeAccount),
          ),
      ],
    );
  }
}

// ── Account selector row ──────────────────────────────────────────────────────

class _AccountSelectorRow extends StatelessWidget {
  const _AccountSelectorRow({
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
  });

  final List<CloudAccount> accounts;
  final String? selectedId;
  final void Function(String id) onSelect;

  static const _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final showMore = accounts.length > _maxVisible;
    final visible = accounts.take(_maxVisible).toList();
    final extras = showMore ? accounts.skip(_maxVisible).toList() : <CloudAccount>[];
    final extraIsSelected =
        showMore && extras.any((a) => a.id == selectedId);

    final tiles = <Widget>[
      for (int i = 0; i < visible.length; i++) ...[
        Expanded(
          child: _AccountTile(
            account: visible[i],
            isSelected: visible[i].id == selectedId,
            onTap: () => onSelect(visible[i].id),
          ),
        ),
        if (i < visible.length - 1 || showMore) const SizedBox(width: 8),
      ],
      if (showMore)
        Expanded(
          child: _MoreAccountsTile(
            extras: extras,
            isSelected: extraIsSelected,
            selectedId: selectedId,
            onSelect: onSelect,
          ),
        ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tiles,
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  final CloudAccount account;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final providerColor = switch (account.provider) {
      CloudProvider.google => AppColors.googleBlue,
      CloudProvider.microsoft => AppColors.microsoftBlue,
      CloudProvider.dropbox => const Color(0xFF0061FE),
      CloudProvider.terabox => const Color(0xFF1296DB),
      CloudProvider.mega => const Color(0xFFD9272E),
      CloudProvider.apple => const Color(0xFF555555),
    };

    final syncColor =
        account.hasBeenScanned ? AppColors.success : AppColors.warning;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brand.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.brand
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Provider icon + status dot
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: providerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: CloudProviderIcon(
                      provider: account.provider, size: 14),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: syncColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Account label
            Text(
              account.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.brand
                        : Theme.of(context).colorScheme.onSurface,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            // Email
            Text(
              account.email,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreAccountsTile extends StatelessWidget {
  const _MoreAccountsTile({
    required this.extras,
    required this.isSelected,
    required this.selectedId,
    required this.onSelect,
  });

  final List<CloudAccount> extras;
  final bool isSelected;
  final String? selectedId;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedExtra =
        isSelected ? extras.firstWhere((a) => a.id == selectedId) : null;

    return InkWell(
      onTap: () => _showDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brand.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.brand
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: (isSelected ? AppColors.brand : Theme.of(context).colorScheme.onSurfaceVariant)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    Icons.expand_circle_down_outlined,
                    size: 14,
                    color: isSelected
                        ? AppColors.brand
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '+${extras.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.brand
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isSelected ? selectedExtra!.label : 'More accounts',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.brand
                        : Theme.of(context).colorScheme.onSurface,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              isSelected ? selectedExtra!.email : 'Tap to select',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AccountPickerDialog(
        accounts: extras,
        selectedId: selectedId,
        onSelect: (id) {
          onSelect(id);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _AccountPickerDialog extends StatelessWidget {
  const _AccountPickerDialog({
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
  });

  final List<CloudAccount> accounts;
  final String? selectedId;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Account'),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: 340,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: accounts.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
          itemBuilder: (context, index) {
            final a = accounts[index];
            final isSelected = a.id == selectedId;
            return ListTile(
              leading: CloudProviderIcon(provider: a.provider, size: 20),
              title: Text(
                a.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.brand : null,
                ),
              ),
              subtitle: Text(a.email),
              trailing: isSelected
                  ? const Icon(Icons.check_circle,
                      color: AppColors.brand, size: 18)
                  : null,
              onTap: () => onSelect(a.id),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// ── Per-account dashboard section ─────────────────────────────────────────────

class _AccountDashboardSection extends ConsumerWidget {
  const _AccountDashboardSection({required this.account});

  final CloudAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account sub-header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CloudProviderIcon(
                  provider: account.provider, size: 22, withBackground: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${account.provider.displayName} – ${account.label}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      account.lastScanAt != null
                          ? '${account.email} · Last synced ${DateFormat('yyyy-MM-dd HH:mm').format(account.lastScanAt!)}'
                          : account.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(activeAccountIdProvider.notifier).state =
                      account.id;
                  context.go(RouteName.files);
                },
                icon: const Icon(Icons.folder_open_outlined, size: 15),
                label: const Text('Browse Files'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  ref.read(activeAccountIdProvider.notifier).state =
                      account.id;
                  context.go(RouteName.analytics);
                },
                icon: const Icon(Icons.bar_chart, size: 15),
                label: const Text('Analytics'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (!account.hasBeenScanned)
            _NotSyncedCard(account: account)
          else ...[
            // Summary stats row
            _DashStatsRow(account: account),

            const SizedBox(height: 16),

            // Charts row 1: Files by Extension + Top 10 Largest Files
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SectionCard(
                        title: 'Files by Extension',
                        child: SizedBox(
                          height: 340,
                          child: FileTypePieChart(accountId: account.id),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SectionCard(
                        title: 'Top 15 Largest Files',
                        child: _LargestFilesHBar(accountId: account.id),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _SectionCard(
                    title: 'Files by Extension',
                    child: SizedBox(
                      height: 340,
                      child: FileTypePieChart(accountId: account.id),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Top 15 Largest Files',
                    child: _LargestFilesHBar(accountId: account.id),
                  ),
                ],
              );
            }),

            const SizedBox(height: 16),

            // Charts row 2: Files by Age + Directory Depth
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SectionCard(
                        title: 'Files by Age',
                        child: _FilesAgeChart(accountId: account.id),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SectionCard(
                        title: 'Entries by Directory Depth',
                        child: _DepthChart(accountId: account.id),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _SectionCard(
                    title: 'Files by Age',
                    child: _FilesAgeChart(accountId: account.id),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Entries by Directory Depth',
                    child: _DepthChart(accountId: account.id),
                  ),
                ],
              );
            }),

            const SizedBox(height: 16),

            // Top Largest Files table
            _SectionCard(
              title: 'Top Largest Files',
              child: _TopFilesTable(accountId: account.id),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Summary stats row ─────────────────────────────────────────────────────────

class _DashStatsRow extends ConsumerWidget {
  const _DashStatsRow({required this.account});

  final CloudAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dupAsync = ref.watch(duplicateSummaryProvider(account.id));
    final dupCount = dupAsync.valueOrNull?.count ?? 0;
    final staleAsync = ref.watch(staleDataSizeProvider(account.id));
    final staleBytes = staleAsync.valueOrNull ?? 0;

    return LayoutBuilder(builder: (context, constraints) {
      final tiles = [
        _DashStatTile(
          icon: Icons.insert_drive_file_outlined,
          color: const Color(0xFF3B82F6),
          label: 'Total Files',
          value: _fmt(account.totalFiles),
          onTap: () {
            ref.read(activeAccountIdProvider.notifier).state = account.id;
            context.go(RouteName.files);
          },
        ),
        _DashStatTile(
          icon: Icons.cloud_sync_outlined,
          color: const Color(0xFFF59E0B),
          label: 'Stale Data (>1 yr old)',
          value: staleBytes.toStorageShort(),
          onTap: () {
            ref.read(activeAccountIdProvider.notifier).state = account.id;
            ref.read(analyticsInitialTabProvider.notifier).state = 2;
            context.go(RouteName.analytics);
          },
        ),
        _DashStatTile(
          icon: Icons.storage_outlined,
          color: const Color(0xFF10B981),
          label: 'Total Size',
          value: account.totalBytes.toStorageShort(),
        ),
        _DashStatTile(
          icon: Icons.copy_outlined,
          color: AppColors.error,
          label: 'Duplicates',
          value: _fmt(dupCount),
          onTap: () {
            ref.read(activeAccountIdProvider.notifier).state = account.id;
            context.go(RouteName.duplicates);
          },
        ),
      ];

      if (constraints.maxWidth >= 600) {
        return Row(
          children: tiles
              .expand((t) => [
                    Expanded(child: t),
                    if (t != tiles.last) const SizedBox(width: 10),
                  ])
              .toList(),
        );
      }
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: tiles[0]),
              const SizedBox(width: 10),
              Expanded(child: tiles[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: tiles[2]),
              const SizedBox(width: 10),
              Expanded(child: tiles[3]),
            ],
          ),
        ],
      );
    });
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _DashStatTile extends StatelessWidget {
  const _DashStatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: color, width: 3)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                            height: 1.1,
                          ),
                    ),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Not-synced placeholder ────────────────────────────────────────────────────

class _NotSyncedCard extends ConsumerWidget {
  const _NotSyncedCard({required this.account});

  final CloudAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_sync_outlined,
            size: 48,
            color: AppColors.brand.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Not synced yet',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Sync this account to see your storage analytics.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: scanState.isScanning
                ? null
                : () => ref.read(scanProvider.notifier).startScan(account),
            icon: const Icon(Icons.sync, size: 16),
            label: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }
}

// ── Section card wrapper ──────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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

// ── Top 10 Largest Files — horizontal bar ─────────────────────────────────────

class _LargestFilesHBar extends ConsumerWidget {
  const _LargestFilesHBar({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(largestFilesDetailProvider(accountId));

    return filesAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading files: $e'),
      ),
      data: (files) {
        if (files.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('No data')),
          );
        }
        // Top 15 only
        final display = files.take(15).toList();
        final maxBytes = display.first.sizeBytes ?? 1;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: display.asMap().entries.map((entry) {
              final file = entry.value;
              final fraction =
                  maxBytes > 0 ? (file.sizeBytes ?? 0) / maxBytes : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        file.name,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) => Stack(
                          children: [
                            Container(
                              height: 16,
                              color: Colors.transparent,
                              width: c.maxWidth,
                            ),
                            Container(
                              height: 16,
                              width: c.maxWidth * fraction,
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      child: Text(
                        file.sizeBytes?.toStorageString() ?? '',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ── Files by Age — vertical bar chart ─────────────────────────────────────────

class _FilesAgeChart extends ConsumerWidget {
  const _FilesAgeChart({required this.accountId});

  final String accountId;

  static const _buckets = [
    'lt_1day',
    '1_7days',
    '7_30days',
    '30d_1year',
    'gt_1year'
  ];
  static const _labels = [
    '< 1 day',
    '1-7 days',
    '7-30 days',
    '30d-1 year',
    '> 1 year'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(fileAgeStatsProvider(accountId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return statsAsync.when(
      loading: () => const SizedBox(
          height: 220, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(height: 220),
      data: (stats) {
        final values =
            _buckets.map((b) => (stats[b] ?? 0).toDouble()).toList();
        final maxY = values.reduce((a, b) => a > b ? a : b);
        if (maxY == 0) {
          return const SizedBox(
              height: 100,
              child: Center(child: Text('No data')));
        }

        return SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 12, 8),
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                barGroups: values.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: barColor,
                        width: 32,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= _labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _labels[i],
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(
                          _fmtK(value.toInt()),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _fmtK(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(0)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}

// ── Entries by Directory Depth — vertical bar chart ───────────────────────────

class _DepthChart extends ConsumerWidget {
  const _DepthChart({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depthAsync = ref.watch(depthDistributionProvider(accountId));

    return depthAsync.when(
      loading: () => const SizedBox(
          height: 220, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(height: 220),
      data: (distribution) {
        if (distribution.isEmpty) {
          return const SizedBox(
              height: 100, child: Center(child: Text('No data')));
        }

        final depths = distribution.keys.toList()..sort();
        final maxCount =
            distribution.values.reduce((a, b) => a > b ? a : b).toDouble();

        return SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 12, 8),
            child: BarChart(
              BarChartData(
                maxY: maxCount * 1.2,
                barGroups: depths.asMap().entries.map((e) {
                  final count = (distribution[e.value] ?? 0).toDouble();
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: count,
                        color: AppColors.info.withValues(alpha: 0.7),
                        width: depths.length > 12 ? 10 : 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= depths.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'L${depths[i]}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(
                          _fmtK(value.toInt()),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _fmtK(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(0)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}

// ── Top Largest Files — table ──────────────────────────────────────────────────

class _TopFilesTable extends ConsumerWidget {
  const _TopFilesTable({required this.accountId});

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
        if (files.isEmpty) return const SizedBox.shrink();

        final headerStyle =
            Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  SizedBox(width: 32, child: Text('#', style: headerStyle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('FILE', style: headerStyle)),
                  SizedBox(
                      width: 80,
                      child: Text('SIZE',
                          style: headerStyle, textAlign: TextAlign.end)),
                  SizedBox(
                      width: 100,
                      child: Text('MODIFIED',
                          style: headerStyle, textAlign: TextAlign.end)),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            const Divider(height: 1),
            ...files.asMap().entries.map((entry) {
              final i = entry.key;
              final file = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${i + 1}',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: i < 3
                                      ? _rankColor(i + 1)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            file.sizeBytes?.toStorageString() ?? '—',
                            textAlign: TextAlign.end,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(file.modifiedAt),
                            textAlign: TextAlign.end,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                        OpenInCloudButton(file: file, size: 14),
                      ],
                    ),
                  ),
                  if (i < files.length - 1)
                    const Divider(height: 1, indent: 16),
                ],
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.brand;
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error, required this.onDismiss});

  final String error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onDismiss,
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
