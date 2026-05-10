import '../../domain/models/cloud_account.dart';

abstract class AuthRepository {
  Future<CloudAccount> loginGoogle();
  Future<CloudAccount> loginMicrosoft();
  Future<CloudAccount> loginDropbox();
  Future<CloudAccount> loginTerabox();
  Future<CloudAccount> loginMega({required String email, required String password});
  Future<CloudAccount> loginApple();
  Future<void> logout(String accountId);
  Future<void> refreshToken(String accountId);
  Future<List<CloudAccount>> getStoredAccounts();
  Future<CloudAccount?> getAccount(String accountId);
  Future<void> renameAccount(String accountId, String newLabel);
  Future<void> deleteAccount(String accountId);
  Future<void> reauthAccount(String accountId);
  Stream<List<CloudAccount>> watchAccounts();
}
