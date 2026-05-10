import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/file_type_utils.dart';
import '../../../providers/files_provider.dart';

class FilterPanel extends StatelessWidget {
  const FilterPanel({
    super.key,
    required this.accountId,
    required this.filter,
    required this.onFilterChanged,
  });

  final String accountId;
  final FilesFilter filter;
  final ValueChanged<FilesFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category filter chips
          Text(
            'Filter by type',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _CategoryChip(
                label: 'All',
                selected: filter.categoryFilter == null,
                onTap: () =>
                    onFilterChanged(filter.copyWith(categoryFilter: null)),
              ),
              ...FileCategory.values.map((cat) => _CategoryChip(
                    label: cat.displayName,
                    selected: filter.categoryFilter == cat.name,
                    onTap: () => onFilterChanged(
                        filter.copyWith(categoryFilter: cat.name)),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          // Sort controls
          Row(
            children: [
              Expanded(
                child: _SortDropdown(
                  value: filter.sortColumn,
                  onChanged: (col) =>
                      onFilterChanged(filter.copyWith(sortColumn: col)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                icon: Icon(
                  filter.sortAsc
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 18,
                ),
                onPressed: () =>
                    onFilterChanged(filter.copyWith(sortAsc: !filter.sortAsc)),
                tooltip: filter.sortAsc ? 'Ascending' : 'Descending',
              ),
              if (filter.categoryFilter != null ||
                  filter.nameFilter != null ||
                  filter.minSizeBytes != null)
                TextButton(
                  onPressed: () => onFilterChanged(filter.clear()),
                  child: const Text('Clear'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.brand.withValues(alpha:0.15),
      checkmarkColor: AppColors.brand,
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? AppColors.brand : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Sort by',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: const [
        DropdownMenuItem(value: 'size_bytes', child: Text('Size')),
        DropdownMenuItem(value: 'name', child: Text('Name')),
        DropdownMenuItem(value: 'modified_at', child: Text('Modified Date')),
      ],
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}
