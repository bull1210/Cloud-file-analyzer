import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cloud_account.dart';
import 'di_providers.dart';

final accountsStreamProvider = StreamProvider<List<CloudAccount>>((ref) {
  return ref.watch(authRepositoryProvider).watchAccounts();
});

class AuthNotifier extends AsyncNotifier<List<CloudAccount>> {
  @override
  Future<List<CloudAccount>> build() async {
    return ref.read(authRepositoryProvider).getStoredAccounts();
  }

  Future<void> loginGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loginGoogleUseCaseProvider).execute().then((_) =>
          ref.read(authRepositoryProvider).getStoredAccounts()),
    );
  }

  Future<void> loginMicrosoft() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loginMicrosoftUseCaseProvider).execute().then((_) =>
          ref.read(authRepositoryProvider).getStoredAccounts()),
    );
  }

  Future<void> loginDropbox() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loginDropboxUseCaseProvider).execute().then((_) =>
          ref.read(authRepositoryProvider).getStoredAccounts()),
    );
  }

  Future<void> loginTerabox() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loginTeraboxUseCaseProvider).execute().then((_) =>
          ref.read(authRepositoryProvider).getStoredAccounts()),
    );
  }

  Future<void> loginApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loginAppleUseCaseProvider).execute().then((_) =>
          ref.read(authRepositoryProvider).getStoredAccounts()),
    );
  }

  Future<void> loginMega({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(loginMegaUseCaseProvider)
          .execute(email: email, password: password)
          .then((_) => ref.read(authRepositoryProvider).getStoredAccounts()),
    );
  }

  Future<void> logout(String accountId) async {
    await ref.read(logoutAccountUseCaseProvider).execute(accountId);
    ref.invalidateSelf();
  }

  Future<void> renameAccount(String accountId, String label) async {
    await ref.read(authRepositoryProvider).renameAccount(accountId, label);
    ref.invalidateSelf();
  }

  Future<void> reauthAccount(String accountId) async {
    await ref.read(authRepositoryProvider).reauthAccount(accountId);
    ref.invalidateSelf();
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, List<CloudAccount>>(AuthNotifier.new);

final activeAccountIdProvider = StateProvider<String?>((_) => null);

final activeAccountProvider = Provider<CloudAccount?>((ref) {
  final id = ref.watch(activeAccountIdProvider);
  final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? [];
  if (accounts.isEmpty) return null;
  if (id == null) return accounts.first;
  try {
    return accounts.firstWhere((a) => a.id == id);
  } catch (_) {
    return accounts.first;
  }
});
