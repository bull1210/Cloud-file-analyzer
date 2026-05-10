import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/access_time_stats.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/empty_state.dart';
import '../files/widgets/file_list_tile.dart';

class AccessBucketScreen extends ConsumerStatefulWidget {
  const AccessBucketScreen({
    super.key,
    required this.bucket,
    required this.accountId,
  });

  final AccessTimeBucket bucket;
  final String accountId;

  @override
  ConsumerState<AccessBucketScreen> createState() => _AccessBucketScreenState();
}

class _AccessBucketScreenState extends ConsumerState<AccessBucketScreen> {
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(
      accessTimeBucketFilesProvider((
        accountId: widget.accountId,
        bucket: widget.bucket,
        offset: _offset,
      )),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.bucket.label)),
      body: filesAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Error',
          subtitle: e.toString(),
        ),
        data: (files) {
          if (files.isEmpty && _offset == 0) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No files in this bucket',
              subtitle: 'Great — no files match this access time range.',
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: files.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                  itemBuilder: (context, i) =>
                      FileListTile(file: files[i]),
                ),
              ),
              if (files.length >= 100 || _offset > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _offset > 0
                          ? () => setState(() => _offset -= 100)
                          : null,
                      child: const Text('Previous'),
                    ),
                    TextButton(
                      onPressed: files.length >= 100
                          ? () => setState(() => _offset += 100)
                          : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
