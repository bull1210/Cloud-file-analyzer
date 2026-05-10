import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/int_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/cloud_account.dart';
import '../../../domain/models/scan_session.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import '../../widgets/cloud_provider_icon.dart';
import '../../widgets/empty_state.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);

    ref.listen(authProvider, (prev, next) {
      if (next is AsyncError && next.error != null) {
        final msg = next.error.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    });

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Cloud Storage'),
          pinned: true,
          actions: [
            FilledButton.icon(
              onPressed: () => _showAddAccountSheet(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Account'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              'Connect Google Drive, OneDrive, Dropbox, or iCloud to scan cloud files',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
        accountsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Error',
              subtitle: e.toString(),
            ),
          ),
          data: (accounts) {
            if (accounts.isEmpty) {
              return SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'No cloud accounts',
                  subtitle:
                      'Add a Google Drive, OneDrive, Dropbox, or iCloud account to get started.',
                  action: () => _showAddAccountSheet(context, ref),
                  actionLabel: 'Add Account',
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildAccountGrid(context, ref, accounts),
                  const SizedBox(height: 24),
                  _HowItWorksSection(),
                ]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountGrid(
      BuildContext context, WidgetRef ref, List<CloudAccount> accounts) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount =
        screenWidth >= 900 ? 3 : screenWidth >= 600 ? 2 : 1;

    final cards = <Widget>[
      ...accounts.map((a) => _AccountCard(account: a)),
      _AddAccountCard(onTap: () => _showAddAccountSheet(context, ref)),
    ];

    if (crossAxisCount == 1) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ))
            .toList(),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += crossAxisCount) {
      final rowCards =
          cards.sublist(i, (i + crossAxisCount).clamp(0, cards.length));
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowCards
                .expand((c) => [
                      Expanded(child: c),
                      if (c != rowCards.last) const SizedBox(width: 12),
                    ])
                .toList(),
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  void _showAddAccountSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddAccountSheet(outerRef: ref),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account});

  final CloudAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final isScanning =
        scanState.isScanning && scanState.scanningAccountId == account.id;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final providerColor = switch (account.provider) {
      CloudProvider.google => AppColors.googleBlue,
      CloudProvider.microsoft => AppColors.microsoftBlue,
      CloudProvider.dropbox => const Color(0xFF0061FE),
      CloudProvider.terabox => const Color(0xFF1296DB),
      CloudProvider.mega => const Color(0xFFD9272E),
      CloudProvider.apple => const Color(0xFF555555),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: provider badge + status
            Row(
              children: [
                // Provider pill badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: providerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: providerColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CloudProviderIcon(
                          provider: account.provider, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        account.provider.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: providerColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Status badge with dot
                if (isScanning)
                  const _StatusBadge(
                      label: 'SYNCING',
                      color: AppColors.warning,
                      showDot: true)
                else if (account.hasBeenScanned)
                  const _StatusBadge(
                      label: 'SYNCED',
                      color: AppColors.success,
                      showDot: true)
                else
                  _StatusBadge(
                      label: 'NOT SYNCED',
                      color: colorScheme.onSurfaceVariant),
              ],
            ),

            const SizedBox(height: 10),

            // Account name + email
            Text(
              account.displayName.isNotEmpty
                  ? account.displayName
                  : account.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              account.email,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),

            if (isScanning) ...[
              const SizedBox(height: 12),
              _ScanProgressMini(progress: scanState.progress),
            ] else if (account.hasBeenScanned) ...[
              const SizedBox(height: 14),
              // Stats: 3-column with large numbers
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CompactStat(
                        value: _compactCount(account.totalFiles),
                        label: 'Files'),
                    VerticalDivider(
                        thickness: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    _CompactStat(
                        value: _compactCount(account.totalFolders),
                        label: 'Folders'),
                    VerticalDivider(
                        thickness: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    _CompactStat(
                        value: account.totalBytes.toStorageShort(),
                        label: 'Total'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last synced: ${_formatSyncDate(account.lastScanAt)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Not synced yet',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                    ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Action buttons row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ActionButton(
                  label: 'Re-auth',
                  icon: Icons.lock_reset_outlined,
                  onTap: () =>
                      ref.read(authProvider.notifier).reauthAccount(account.id),
                ),
                // Sync – filled green button
                SizedBox(
                  height: 30,
                  child: FilledButton(
                    onPressed: !scanState.isScanning
                        ? () => ref
                            .read(scanProvider.notifier)
                            .startScan(account)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: isScanning
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: Text(isScanning ? 'Syncing…' : 'Sync'),
                  ),
                ),
                if (account.hasBeenScanned) ...[
                  _ActionButton(
                    label: 'Stats',
                    icon: Icons.bar_chart_outlined,
                    onTap: () {
                      ref.read(activeAccountIdProvider.notifier).state =
                          account.id;
                      GoRouter.of(context)
                          .go(RouteName.accountDetail(account.id));
                    },
                  ),
                  _ActionButton(
                    label: 'Browse',
                    icon: Icons.folder_open_outlined,
                    onTap: () {
                      ref.read(activeAccountIdProvider.notifier).state =
                          account.id;
                      GoRouter.of(context).go(RouteName.files);
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Bottom row: Duplicates button + delete icon
            Row(
              children: [
                if (account.hasBeenScanned)
                  _ActionButton(
                    label: 'Duplicates',
                    icon: Icons.copy_outlined,
                    color: AppColors.error,
                    onTap: () {
                      ref.read(activeAccountIdProvider.notifier).state =
                          account.id;
                      GoRouter.of(context).go(RouteName.duplicates);
                    },
                  )
                else
                  const SizedBox.shrink(),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Remove account',
                  color: AppColors.error,
                  onPressed: () => _confirmRemove(context, ref),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _compactCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _formatSyncDate(DateTime? dt) {
    if (dt == null) return 'Never';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text(
            'Remove "${account.label}"? All scanned data will be deleted from this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).logout(account.id);
    }
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    this.showDot = false,
  });

  final String label;
  final Color color;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDot) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: c.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: c,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.add, color: AppColors.brand, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                'Add Cloud Account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect Drive, OneDrive, Dropbox, or iCloud',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanProgressMini extends StatelessWidget {
  const _ScanProgressMini({required this.progress});

  final ScanProgress? progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (p != null && p.progressFraction > 0) ? p.progressFraction : null,
            backgroundColor: AppColors.brand.withValues(alpha: 0.12),
            color: AppColors.brand,
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 8),
        if (p == null)
          Text(
            'Connecting to cloud…',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _ProgressChip(
                icon: Icons.insert_drive_file_outlined,
                label: '${p.filesScanned} files',
              ),
              _ProgressChip(
                icon: Icons.folder_outlined,
                label: '${p.foldersScanned} folders',
              ),
              _ProgressChip(
                icon: Icons.storage_outlined,
                label: p.bytesScanned.toStorageShort(),
              ),
            ],
          ),
        if (p != null && p.currentPath.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.arrow_right,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  p.currentPath,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.brand),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final steps = [
            const _HowItWorksStep(
              step: '01',
              title: 'Add Account',
              description:
                  'Tap "Add Account" and pick your cloud provider — Google Drive, OneDrive, Dropbox, or iCloud.',
            ),
            const _HowItWorksStep(
              step: '02',
              title: 'Connect & Authorize',
              description:
                  'Click Connect to go through the OAuth flow. Tokens are stored locally.',
            ),
            const _HowItWorksStep(
              step: '03',
              title: 'Sync & Explore',
              description:
                  'Sync pulls file metadata into the local database — no files are downloaded.',
            ),
          ];

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps
                  .expand((s) => [
                        Expanded(child: s),
                        if (s != steps.last) const SizedBox(width: 12),
                      ])
                  .toList(),
            );
          }
          return Column(
            children: steps
                .map((s) =>
                    Padding(padding: const EdgeInsets.only(bottom: 12), child: s))
                .toList(),
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Add Account bottom sheet ──────────────────────────────────────────────────

class _AddAccountSheet extends ConsumerStatefulWidget {
  const _AddAccountSheet({required this.outerRef});

  final WidgetRef outerRef;

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: _buildProviderList(context),
    );
  }

  Widget _buildProviderList(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Cloud Account',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect a cloud storage account to scan file metadata.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        _providerButton(
          context,
          provider: CloudProvider.google,
          label: 'Continue with Google Drive',
          onTap: () {
            Navigator.pop(context);
            widget.outerRef.read(authProvider.notifier).loginGoogle();
          },
        ),
        const SizedBox(height: 12),
        _providerButton(
          context,
          provider: CloudProvider.microsoft,
          label: 'Continue with Microsoft OneDrive',
          onTap: () {
            Navigator.pop(context);
            widget.outerRef.read(authProvider.notifier).loginMicrosoft();
          },
        ),
        const SizedBox(height: 12),
        _providerButton(
          context,
          provider: CloudProvider.dropbox,
          label: 'Continue with Dropbox',
          onTap: () {
            Navigator.pop(context);
            widget.outerRef.read(authProvider.notifier).loginDropbox();
          },
        ),
        const SizedBox(height: 12),
        _providerButton(
          context,
          provider: CloudProvider.apple,
          label: 'Continue with iCloud (iOS / macOS)',
          onTap: () {
            final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS;
            if (!isApple) {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('iCloud Not Available'),
                  content: const Text(
                    'Sign in with Apple and iCloud Drive are only supported on iOS and macOS.\n\n'
                    'iCloud Drive has no public REST API, so it cannot be accessed from Windows, Android, or Linux.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              return;
            }
            Navigator.pop(context);
            widget.outerRef.read(authProvider.notifier).loginApple();
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }


  Widget _providerButton(
    BuildContext context, {
    required CloudProvider provider,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            CloudProviderIcon(provider: provider, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
