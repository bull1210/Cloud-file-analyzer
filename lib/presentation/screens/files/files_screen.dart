import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/files_provider.dart';
import '../../widgets/empty_state.dart';
import 'widgets/filter_panel.dart';
import 'widgets/file_list_tile.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  final _searchController = TextEditingController();
  int _currentPage = 0;
  bool _showFilter = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(activeAccountProvider);
    if (account == null) {
      return const EmptyState(
        icon: Icons.folder_outlined,
        title: 'No account selected',
        subtitle: 'Select an account from the Dashboard.',
      );
    }

    final filesAsync = ref.watch(
        filesProvider((accountId: account.id, page: _currentPage)));
    final filter = ref.watch(filesFilterProvider(account.id));
    final hasFilters = filter.hasActiveFilters;

    return Scaffold(
      appBar: AppBar(
        title: Text('Files — ${account.label}',
            overflow: TextOverflow.ellipsis),
        actions: [
          if (hasFilters)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.close, size: 15),
              label: const Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          IconButton(
            icon: Icon(
              _showFilter ? Icons.filter_list : Icons.filter_list_outlined,
              color: (hasFilters || _showFilter) ? AppColors.brand : null,
            ),
            onPressed: () => setState(() => _showFilter = !_showFilter),
            tooltip: 'Filter & Sort',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: _applySearch,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_showFilter)
            FilterPanel(
              accountId: account.id,
              filter: filter,
              onFilterChanged: (newFilter) {
                ref.read(filesFilterProvider(account.id).notifier).state =
                    newFilter;
                setState(() => _currentPage = 0);
              },
            ),
          Expanded(
            child: filesAsync.when(
              loading: () => const LoadingState(message: 'Loading files…'),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load files',
                subtitle: e.toString(),
              ),
              data: (files) {
                if (files.isEmpty && _currentPage == 0) {
                  return const EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'No files found',
                    subtitle:
                        'Scan your account first, or adjust your filters.',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: files.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16),
                        itemBuilder: (context, index) =>
                            FileListTile(file: files[index]),
                      ),
                    ),
                    // Pagination
                    if (files.length >= 50 || _currentPage > 0)
                      _PaginationBar(
                        page: _currentPage,
                        hasMore: files.length >= 50,
                        onPrev: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                        onNext: files.length >= 50
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _applySearch(String query) {
    final accountId = ref.read(activeAccountProvider)?.id ?? '';
    ref.read(filesFilterProvider(accountId).notifier).state =
        ref.read(filesFilterProvider(accountId)).copyWith(
              nameFilter: query.isEmpty ? null : query,
            );
    setState(() => _currentPage = 0);
  }

  void _clearAll() {
    final accountId = ref.read(activeAccountProvider)?.id ?? '';
    _searchController.clear();
    ref.read(filesFilterProvider(accountId).notifier).state =
        const FilesFilter();
    setState(() {
      _currentPage = 0;
      _showFilter = false;
    });
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.hasMore,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final bool hasMore;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Previous'),
          ),
          const SizedBox(width: 16),
          Text(
            'Page ${page + 1}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Next'),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}
