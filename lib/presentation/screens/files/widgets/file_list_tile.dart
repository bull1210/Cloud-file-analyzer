import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/file_type_utils.dart';
import '../../../../domain/models/cloud_file.dart';
import '../../../widgets/cloud_provider_icon.dart';
import '../../../widgets/open_in_cloud_button.dart';

class FileListTile extends StatelessWidget {
  const FileListTile({super.key, required this.file});

  final CloudFile file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _FileTypeIcon(category: file.category, isFolder: file.isFolder),
      title: Row(
        children: [
          Expanded(
            child: Text(
              file.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (file.sizeBytes != null) ...[
            const SizedBox(width: 6),
            Text(
              file.sizeBytes!.toStorageString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
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
          CloudProviderIcon(provider: file.provider, size: 10),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              file.path,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      trailing: OpenInCloudButton(file: file),
    );
  }
}

class _FileTypeIcon extends StatelessWidget {
  const _FileTypeIcon({required this.category, required this.isFolder});

  final FileCategory category;
  final bool isFolder;

  @override
  Widget build(BuildContext context) {
    if (isFolder) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.folder, color: AppColors.warning, size: 22),
      );
    }

    final (icon, color) = _iconForCategory(category);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  (IconData, Color) _iconForCategory(FileCategory cat) {
    switch (cat) {
      case FileCategory.image:
        return (Icons.image_outlined, AppColors.success);
      case FileCategory.video:
        return (Icons.video_file_outlined, const Color(0xFFE91E63));
      case FileCategory.audio:
        return (Icons.audio_file_outlined, AppColors.info);
      case FileCategory.pdf:
        return (Icons.picture_as_pdf_outlined, AppColors.error);
      case FileCategory.document:
        return (Icons.description_outlined, AppColors.info);
      case FileCategory.spreadsheet:
        return (Icons.table_chart_outlined, AppColors.success);
      case FileCategory.presentation:
        return (Icons.slideshow_outlined, AppColors.warning);
      case FileCategory.archive:
        return (Icons.archive_outlined, const Color(0xFF795548));
      case FileCategory.code:
        return (Icons.code_outlined, AppColors.brand);
      case FileCategory.other:
        return (Icons.insert_drive_file_outlined, AppColors.darkTextMuted);
    }
  }
}
