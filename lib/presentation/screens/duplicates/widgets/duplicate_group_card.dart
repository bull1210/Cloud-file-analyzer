import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/cloud_file.dart';
import '../../../../domain/models/duplicate_group.dart';
import '../../../providers/duplicates_provider.dart';
import '../../../widgets/cloud_provider_icon.dart';
import '../../../widgets/open_in_cloud_button.dart';

class DuplicateGroupCard extends ConsumerStatefulWidget {
  const DuplicateGroupCard({
    super.key,
    required this.group,
    required this.groupIndex,
    required this.strategy,
    required this.accountId,
  });

  final DuplicateGroup group;
  final int groupIndex;
  final DuplicateKeepStrategy strategy;
  final String accountId;

  @override
  ConsumerState<DuplicateGroupCard> createState() => _DuplicateGroupCardState();
}

class _DuplicateGroupCardState extends ConsumerState<DuplicateGroupCard> {
  bool _expanded = false;

  List<CloudFile> get _forDeletion =>
      widget.strategy == DuplicateKeepStrategy.newest
          ? widget.group.suggestedForDeletion
          : widget.group.suggestedForDeletionKeepOldest;

  Set<String> get _groupFileIds =>
      widget.group.files.map((f) => f.id).toSet();

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedForDeletionProvider(widget.accountId));
    final deletionState = ref.watch(deletionNotifierProvider);
    final selectedInGroup = selected.intersection(_groupFileIds);
    final isExact = widget.group.hasHashMatch;
    final badgeColor = isExact ? AppColors.warning : AppColors.info;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // ── Header (tap to expand) ──────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.groupIndex}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.fileName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              '${widget.group.fileCount} copies · '
                              '${widget.group.wastedBytes.toStorageString()} wasted',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: badgeColor),
                            ),
                            const SizedBox(width: 8),
                            _ConfidenceBadge(isExact: isExact),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ────────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),

            if (isExact) ...[
              // Select-all / deselect-all toggle row
              _SelectAllRow(
                selectedCount: selectedInGroup.length,
                totalCount: widget.group.files.length,
                onSelectAll: () => _selectAll(selected),
                onDeselectAll: () => _deselectAll(selected),
              ),
              const Divider(height: 1),

              // File rows with checkboxes
              ...widget.group.files.map((file) {
                final suggestedForDeletion =
                    _forDeletion.any((f) => f.id == file.id);
                return _ExactFileRow(
                  file: file,
                  suggestedForDeletion: suggestedForDeletion,
                  isSelected: selected.contains(file.id),
                  onToggle: () => _toggleFile(selected, file.id),
                );
              }),

              // Delete button — shown only when files in this group are selected
              if (selectedInGroup.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: deletionState.isDeleting
                              ? null
                              : () => _confirmDelete(
                                    context,
                                    ref,
                                    widget.group.files
                                        .where((f) =>
                                            selectedInGroup.contains(f.id))
                                        .toList(),
                                  ),
                          icon: deletionState.isDeleting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.delete_outline, size: 16),
                          label: Text(
                            deletionState.isDeleting
                                ? 'Moving to Trash…'
                                : 'Move ${selectedInGroup.length} '
                                    'file${selectedInGroup.length == 1 ? '' : 's'} to Trash',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                const SizedBox(height: 8),
            ] else ...[
              // Probable duplicates — read-only file list + warning banner
              ...widget.group.files.map((file) => _ProbableFileRow(file: file)),
              _ProbableWarningBanner(),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }

  void _toggleFile(Set<String> selected, String fileId) {
    final notifier =
        ref.read(selectedForDeletionProvider(widget.accountId).notifier);
    if (selected.contains(fileId)) {
      notifier.state = {...selected}..remove(fileId);
    } else {
      notifier.state = {...selected, fileId};
    }
  }

  void _selectAll(Set<String> selected) {
    final notifier =
        ref.read(selectedForDeletionProvider(widget.accountId).notifier);
    notifier.state = {...selected, ..._forDeletion.map((f) => f.id)};
  }

  void _deselectAll(Set<String> selected) {
    final notifier =
        ref.read(selectedForDeletionProvider(widget.accountId).notifier);
    notifier.state = selected.difference(_groupFileIds);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    List<CloudFile> filesToDelete,
  ) async {
    final allCopiesSelected =
        filesToDelete.length == widget.group.files.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (allCopiesSelected)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All copies selected — no copy will remain.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ...filesToDelete.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    CloudProviderIcon(provider: f.provider, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f.path,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Files are moved to your cloud Trash/Recycle Bin — '
              'not permanently deleted.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(deletionNotifierProvider.notifier)
          .deleteFiles(filesToDelete, widget.accountId);
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SelectAllRow extends StatelessWidget {
  const _SelectAllRow({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedCount == totalCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: allSelected ? onDeselectAll : onSelectAll,
            icon: Icon(
              allSelected
                  ? Icons.deselect_outlined
                  : Icons.select_all_outlined,
              size: 14,
            ),
            label: Text(
              allSelected ? 'Deselect all' : 'Select all for deletion',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
          if (selectedCount > 0) ...[
            const Spacer(),
            Text(
              '$selectedCount / $totalCount selected',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _ExactFileRow extends StatelessWidget {
  const _ExactFileRow({
    required this.file,
    required this.suggestedForDeletion,
    required this.isSelected,
    required this.onToggle,
  });

  final CloudFile file;
  final bool suggestedForDeletion;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: suggestedForDeletion
          ? AppColors.error.withValues(alpha: 0.04)
          : null,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Row(
          children: [
            CloudProviderIcon(provider: file.provider, size: 13),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                file.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
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
            Expanded(
              child: Text(
                file.path,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _StatusTag(
              label: suggestedForDeletion ? 'Suggested for deletion' : 'Keep',
              color:
                  suggestedForDeletion ? AppColors.error : AppColors.success,
            ),
          ],
        ),
        trailing: OpenInCloudButton(file: file, size: 14),
        dense: true,
      ),
    );
  }
}

class _ProbableFileRow extends StatelessWidget {
  const _ProbableFileRow({required this.file});

  final CloudFile file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: CloudProviderIcon(provider: file.provider, size: 18),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              file.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            DateFormat('MMM d, y').format(file.modifiedAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      subtitle: Text(
        file.path,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: OpenInCloudButton(file: file, size: 14),
      dense: true,
    );
  }
}

class _ProbableWarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 14, color: AppColors.warning),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Matched by name and size only — no content hash available. '
                'Open your cloud drive to verify and delete manually.',
                style: TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.isExact});

  final bool isExact;

  @override
  Widget build(BuildContext context) {
    final color = isExact ? AppColors.success : AppColors.info;
    return Tooltip(
      message: isExact
          ? 'Exact match — files share the same content hash (MD5/SHA)'
          : 'Probable duplicate — matched by name and size only (no hash available)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isExact ? 'Exact' : 'Probable',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
