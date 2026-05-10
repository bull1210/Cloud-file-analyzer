import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/scan_session.dart';
import '../../../providers/scan_provider.dart';

class ScanProgressBanner extends ConsumerWidget {
  const ScanProgressBanner({super.key, required this.progress});

  final ScanProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fraction = progress.progressFraction;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brand.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Scanning cloud metadata…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                      ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(scanProvider.notifier).cancelScan(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction > 0 ? fraction : null,
              backgroundColor: AppColors.brand.withValues(alpha:0.15),
              color: AppColors.brand,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CountChip(
                icon: Icons.insert_drive_file_outlined,
                label: '${progress.filesScanned} files',
              ),
              const SizedBox(width: 8),
              _CountChip(
                icon: Icons.folder_outlined,
                label: '${progress.foldersScanned} folders',
              ),
              const SizedBox(width: 8),
              _CountChip(
                icon: Icons.storage_outlined,
                label: progress.bytesScanned.toStorageShort(),
              ),
            ],
          ),
          if (progress.currentPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.arrow_right,
                  size: 14,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    progress.currentPath,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.brand),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
