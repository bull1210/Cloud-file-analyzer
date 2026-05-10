import 'package:flutter/material.dart';
import '../../core/utils/cloud_url_utils.dart';
import '../../domain/models/cloud_file.dart';

class OpenInCloudButton extends StatelessWidget {
  const OpenInCloudButton({super.key, required this.file, this.size = 16});

  final CloudFile file;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.open_in_new, size: size),
      onPressed: () => CloudUrlUtils.openFile(file),
      tooltip: 'Open in cloud',
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: size + 16, minHeight: size + 16),
      visualDensity: VisualDensity.compact,
    );
  }
}
