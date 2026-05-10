import '../../local/secure_storage/token_storage_service.dart';
import 'mega_auth_service.dart';

// Placeholder client for MEGA. Full implementation requires the mega_sdk
// package for AES/RSA key derivation and file node decryption.
class MegaClient {
  MegaClient({
    required this.tokenStorage,
    required this.authService,
  });

  final TokenStorageService tokenStorage;
  final MegaAuthService authService;

  String? _currentAccountId;

  void setAccount(String accountId) => _currentAccountId = accountId;

  // Returns the stored email (used as the account identifier for MEGA).
  Future<String?> getStoredEmail() async {
    if (_currentAccountId == null) return null;
    return tokenStorage.getAccessToken(_currentAccountId!);
  }
}

// Noop MEGA auth used in the scan isolate (no network calls).
class NoopMegaAuthService extends MegaAuthService {
  NoopMegaAuthService() : super(tokenStorage: _EmptyTokenStorage());
}

class _EmptyTokenStorage extends TokenStorageService {
  @override
  Future<String?> getAccessToken(String accountId) async => '';
  @override
  Future<bool> isTokenValid(String accountId) async => true;
}
