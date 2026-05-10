import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cloud_file.dart';
import '../../domain/models/duplicate_group.dart';
import '../../services/cloud_delete_service.dart';
import 'analytics_provider.dart';
import 'di_providers.dart';
import 'files_provider.dart';

final duplicateGroupsProvider =
    FutureProvider.family<List<DuplicateGroup>, String>((ref, accountId) {
  return ref.read(findDuplicatesUseCaseProvider).execute(accountId);
});

// Tracks which files (by local ID) are checked for deletion — scoped per account
final selectedForDeletionProvider =
    StateProvider.family<Set<String>, String>((_, __) => {});

enum DuplicateKeepStrategy { newest, oldest }

final duplicateStrategyProvider =
    StateProvider<DuplicateKeepStrategy>((_) => DuplicateKeepStrategy.newest);

// ── Deletion state ──────────────────────────────────────────────────────────

class DeletionState {
  const DeletionState({
    this.isDeleting = false,
    this.result,
    this.error,
  });

  final bool isDeleting;
  final DeleteResult? result;
  final String? error;

  bool get isIdle => !isDeleting && result == null && error == null;
}

class DeletionNotifier extends AutoDisposeNotifier<DeletionState> {
  @override
  DeletionState build() => const DeletionState();

  Future<void> deleteFiles(List<CloudFile> files, String accountId) async {
    if (state.isDeleting) return;
    state = const DeletionState(isDeleting: true);
    try {
      final result =
          await ref.read(cloudDeleteServiceProvider).deleteFiles(files);
      state = DeletionState(result: result);
      // Clear selection so the UI resets
      ref.read(selectedForDeletionProvider(accountId).notifier).state = {};
      // Refresh providers affected by the removal
      ref.invalidate(duplicateGroupsProvider(accountId));
      ref.invalidate(duplicateSummaryProvider(accountId));
      ref.invalidate(fileTypeBreakdownProvider(accountId));
      ref.invalidate(largestFilesProvider(accountId));
      ref.invalidate(filesProvider);
    } catch (e) {
      state = DeletionState(error: e.toString());
    }
  }

  void clearResult() => state = const DeletionState();
}

final deletionNotifierProvider =
    AutoDisposeNotifierProvider<DeletionNotifier, DeletionState>(
        DeletionNotifier.new);
