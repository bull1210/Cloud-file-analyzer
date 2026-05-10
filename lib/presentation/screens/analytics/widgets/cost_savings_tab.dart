import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/file_type_utils.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';

class CostSavingsTab extends ConsumerWidget {
  const CostSavingsTab({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaleDataSection(accountId: accountId),
        const SizedBox(height: 16),
        _CrossAccountDuplicatesSection(accountId: accountId),
        const SizedBox(height: 16),
        _DuplicateWasteSection(accountId: accountId),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Stale data section ────────────────────────────────────────────────────────

class _StaleDataSection extends ConsumerWidget {
  const _StaleDataSection({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staleSizeAsync = ref.watch(staleDataSizeProvider(accountId));
    final staleCatAsync = ref.watch(staleDataByCategoryProvider(accountId));

    return _SectionCard(
      icon: Icons.cloud_sync_outlined,
      color: const Color(0xFFF59E0B),
      title: 'Stale Data',
      subtitle: 'Files not modified in over 1 year — candidates for cold storage',
      child: Column(
        children: [
          staleSizeAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorText(e.toString()),
            data: (bytes) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _BigMetric(
                      value: bytes.toStorageString(),
                      label: 'Total stale data',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  Expanded(
                    child: _BigMetric(
                      value: _estimateSavings(bytes),
                      label: 'Est. cold-storage savings',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
          staleCatAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) {
              if (cats.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Text(
                      'BY CATEGORY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  ...cats.map((cat) => _CategoryRow(
                        category: cat['category'] as String,
                        fileCount: cat['file_count'] as int,
                        totalBytes: cat['total_bytes'] as int,
                        maxBytes: (cats.first['total_bytes'] as int).toDouble(),
                      )),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _estimateSavings(int bytes) {
    // Rough estimate: cold storage (e.g. Glacier/Coldline) costs ~$0.004/GB/month
    // vs standard ~$0.023/GB/month — 83% savings
    const savingsFraction = 0.83;
    final savedBytes = (bytes * savingsFraction).round();
    return savedBytes.toStorageString();
  }
}

// ── Cross-account duplicates section ─────────────────────────────────────────

class _CrossAccountDuplicatesSection extends ConsumerWidget {
  const _CrossAccountDuplicatesSection({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crossDupsAsync = ref.watch(crossAccountDuplicatesProvider);

    return _SectionCard(
      icon: Icons.compare_arrows_outlined,
      color: const Color(0xFF8B5CF6),
      title: 'Cross-Account Duplicates',
      subtitle: 'Files that exist in multiple cloud accounts',
      child: crossDupsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _ErrorText(e.toString()),
        data: (dups) {
          if (dups.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 32),
                    SizedBox(height: 8),
                    Text('No cross-account duplicates found'),
                  ],
                ),
              ),
            );
          }

          final totalWaste = dups.fold<int>(
            0,
            (sum, d) => sum +
                ((d['total_copies'] as int) - 1) * (d['size_bytes'] as int),
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _BigMetric(
                        value: '${dups.length}',
                        label: 'Duplicate groups',
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    Expanded(
                      child: _BigMetric(
                        value: totalWaste.toStorageString(),
                        label: 'Wasted across accounts',
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...dups.take(10).map((dup) => _CrossDupRow(dup: dup, ref: ref)),
              if (dups.length > 10)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '… and ${dups.length - 10} more groups',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CrossDupRow extends ConsumerWidget {
  const _CrossDupRow({required this.dup, required this.ref});

  final Map<String, dynamic> dup;
  // ignore: unused_field
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef refArg) {
    final accounts = refArg.watch(accountsStreamProvider).valueOrNull ?? [];
    final accountIds = (dup['account_ids'] as List).cast<String>();
    final copies = dup['total_copies'] as int;
    final bytes = dup['size_bytes'] as int;
    final waste = (copies - 1) * bytes;

    final accountLabels = accountIds.map((id) {
      final match = accounts.where((a) => a.id == id).firstOrNull;
      return match?.label ?? id;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined,
                  size: 16, color: AppColors.info),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dup['name'] as String,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      accountLabels.join(' · '),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bytes.toStorageString(),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${copies}x · waste: ${waste.toStorageString()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.error,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}

// ── Same-account duplicate waste section ─────────────────────────────────────

class _DuplicateWasteSection extends ConsumerWidget {
  const _DuplicateWasteSection({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dupAsync = ref.watch(duplicateSummaryProvider(accountId));

    return _SectionCard(
      icon: Icons.copy_outlined,
      color: AppColors.error,
      title: 'Duplicate Waste',
      subtitle: 'Space wasted by duplicate files in this account',
      child: dupAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _ErrorText(e.toString()),
        data: (summary) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: _BigMetric(
                  value: '${summary.count}',
                  label: 'Duplicate files',
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: _BigMetric(
                  value: summary.wastedBytes.toStorageString(),
                  label: 'Wasted space',
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
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
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

class _BigMetric extends StatelessWidget {
  const _BigMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.fileCount,
    required this.totalBytes,
    required this.maxBytes,
  });

  final String category;
  final int fileCount;
  final int totalBytes;
  final double maxBytes;

  @override
  Widget build(BuildContext context) {
    final fraction = maxBytes > 0 ? totalBytes / maxBytes : 0.0;
    final catLabel = FileCategory.values
        .firstWhere((c) => c.name == category,
            orElse: () => FileCategory.other)
        .displayName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              catLabel,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    width: c.maxWidth,
                    color: Colors.transparent,
                  ),
                  Container(
                    height: 14,
                    width: c.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Text(
              totalBytes.toStorageString(),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$fileCount files',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Error: $message',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
