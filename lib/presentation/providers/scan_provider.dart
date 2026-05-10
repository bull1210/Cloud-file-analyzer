import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/models/cloud_account.dart';
import '../../domain/models/scan_session.dart';
import 'analytics_provider.dart';
import 'duplicates_provider.dart';
import 'files_provider.dart';
import 'di_providers.dart';

class ScanState {
  const ScanState({
    this.isScanning = false,
    this.scanningAccountId,
    this.progress,
    this.error,
    this.completedAccountId,
  });

  final bool isScanning;
  final String? scanningAccountId;
  final ScanProgress? progress;
  final String? error;
  final String? completedAccountId;

  ScanState copyWith({
    bool? isScanning,
    String? scanningAccountId,
    ScanProgress? progress,
    String? error,
    String? completedAccountId,
  }) =>
      ScanState(
        isScanning: isScanning ?? this.isScanning,
        scanningAccountId: scanningAccountId ?? this.scanningAccountId,
        progress: progress ?? this.progress,
        error: error ?? this.error,
        completedAccountId: completedAccountId ?? this.completedAccountId,
      );
}

class ScanNotifier extends Notifier<ScanState> {
  StreamSubscription<ScanProgress>? _subscription;

  @override
  ScanState build() => const ScanState();

  Future<void> startScan(CloudAccount account) async {
    if (state.isScanning) return;

    state = ScanState(isScanning: true, scanningAccountId: account.id);

    // Ensure the access token is fresh before the isolate is spawned —
    // the isolate receives a snapshot token and cannot refresh mid-scan.
    try {
      final tokenStorage = ref.read(tokenStorageProvider);
      if (!await tokenStorage.isTokenValid(account.id)) {
        await ref.read(authRepositoryProvider).refreshToken(account.id);
      }
    } catch (_) {
      // If refresh fails, the isolate will surface a TokenExpiredException
      // through the normal error path below.
    }

    _subscription = ref
        .read(startScanUseCaseProvider)
        .execute(account)
        .listen(
          (progress) {
            state = state.copyWith(progress: progress);
          },
          onDone: () {
            state = ScanState(
              isScanning: false,
              completedAccountId: account.id,
            );
            _invalidateDataProviders(account.id);
          },
          onError: (Object e) {
            if (e is TokenExpiredException) {
              ref.read(logoutAccountUseCaseProvider).execute(account.id);
            }
            state = ScanState(
              isScanning: false,
              error: e is AppException ? e.message : e.toString(),
            );
          },
          cancelOnError: true,
        );
  }

  void _invalidateDataProviders(String accountId) {
    ref.invalidate(folderRankingsProvider(accountId));
    ref.invalidate(fileTypeBreakdownProvider(accountId));
    ref.invalidate(accessTimeStatsProvider(accountId));
    ref.invalidate(largestFilesAnalyticsProvider(accountId));
    ref.invalidate(duplicateGroupsProvider(accountId));
    ref.invalidate(largestFilesProvider(accountId));
    ref.invalidate(filesProvider);
    ref.invalidate(staleDataSizeProvider(accountId));
    ref.invalidate(staleDataByCategoryProvider(accountId));
    ref.invalidate(crossAccountDuplicatesProvider);
    ref.invalidate(duplicateSummaryProvider(accountId));
  }

  void cancelScan() {
    _subscription?.cancel();
    ref.read(cancelScanUseCaseProvider).execute();
    state = const ScanState();
  }

  void clearError() => state = const ScanState();
}

final scanProvider = NotifierProvider<ScanNotifier, ScanState>(ScanNotifier.new);
