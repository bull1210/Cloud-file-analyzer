import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../local/secure_storage/token_storage_service.dart';
import '../oauth_token_result.dart';

// MEGA uses email/password auth — not standard OAuth2.
// Credentials are stored securely; scanning uses the stored session.
class MegaAuthService {
  MegaAuthService({required this.tokenStorage});

  final TokenStorageService tokenStorage;

  // Email/password are passed directly; we store the email as the "idToken"
  // and a composite credential string as the "accessToken" (not a bearer token).
  Future<OAuthTokenResult> authorizeWithCredentials({
    required String email,
    required String password,
  }) async {
    logger.log('MegaAuth', 'authorizeWithCredentials() email=$email');
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Email and password are required for MEGA login.');
    }

    // Store the password as the refresh token so we can re-authenticate later.
    // The access token is the email — MEGA sessions are managed separately.
    // Note: Actual MEGA file scanning requires the mega_sdk package which
    // handles their AES/RSA key derivation and file node decryption.
    return OAuthTokenResult(
      accessToken: email.trim().toLowerCase(),
      refreshToken: password,
      accessTokenExpirationDateTime: DateTime.now().add(const Duration(days: 365)),
      idToken: email.trim().toLowerCase(),
    );
  }

  Future<OAuthTokenResult?> refreshAccessToken(String accountId) async {
    // MEGA sessions don't expire in the traditional sense — no-op refresh.
    final token = await tokenStorage.getAccessToken(accountId);
    if (token == null) return null;
    return OAuthTokenResult(
      accessToken: token,
      accessTokenExpirationDateTime: DateTime.now().add(const Duration(days: 365)),
    );
  }

  Future<void> revokeTokens(String accountId) async {
    await tokenStorage.deleteTokens(accountId);
  }
}
