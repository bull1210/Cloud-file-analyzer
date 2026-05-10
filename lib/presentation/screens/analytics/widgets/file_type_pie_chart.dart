import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/analytics_provider.dart';
import '../../../widgets/empty_state.dart';

class FileTypePieChart extends ConsumerStatefulWidget {
  const FileTypePieChart({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<FileTypePieChart> createState() => _FileTypePieChartState();
}

class _FileTypePieChartState extends ConsumerState<FileTypePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final breakdownAsync =
        ref.watch(fileTypeBreakdownProvider(widget.accountId));

    return breakdownAsync.when(
      loading: () => const LoadingState(message: 'Analyzing file types…'),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error',
        subtitle: e.toString(),
      ),
      data: (list) {
        final items = list.sortedBySize;
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.pie_chart_outline,
            title: 'No data',
            subtitle: 'Scan your account to see file type breakdown.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 260,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      final isTouched = i == _touchedIndex;
                      final color = AppColors.chartPalette[
                          i % AppColors.chartPalette.length];
                      final pct = (item.fractionOfTotal(list.totalBytes) * 100)
                          .toStringAsFixed(1);

                      return PieChartSectionData(
                        color: color,
                        value: item.totalBytes.toDouble(),
                        title: isTouched ? '$pct%' : '',
                        radius: isTouched ? 90 : 75,
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Legend
              ...items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final color = AppColors.chartPalette[
                    i % AppColors.chartPalette.length];
                final pct =
                    (item.fractionOfTotal(list.totalBytes) * 100).toStringAsFixed(1);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.category.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      Text(
                        item.totalBytes.toStorageString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '$pct%',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: color, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
