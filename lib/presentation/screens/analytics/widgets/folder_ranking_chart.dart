import 'package:flutter/material.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/folder_rank.dart';

class FolderRankingChart extends StatelessWidget {
  const FolderRankingChart({super.key, required this.rankings});

  final List<FolderRank> rankings;

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No folder data available.'),
      );
    }

    final top = rankings.take(10).toList();
    final maxBytes = top.first.totalBytes.toDouble();

    return Column(
      children: top.asMap().entries.map((entry) {
        final i = entry.key;
        final rank = entry.value;
        final fraction = maxBytes > 0 ? rank.totalBytes / maxBytes : 0.0;
        final color =
            AppColors.chartPalette[i % AppColors.chartPalette.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rank.folderName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rank.totalBytes.toStorageString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: color.withValues(alpha: 0.12),
                  color: color,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
