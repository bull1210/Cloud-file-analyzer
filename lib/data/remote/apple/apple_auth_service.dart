import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/errors/app_exception.dart';
import '../../local/secure_storage/token_storage_service.dart';
import '../oauth_token_result.dart';

class AppleAuthService {
  AppleAuthService({required this.tokenStorage});

  final TokenStorageService tokenStorage;

  bool get _isApplePlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<OAuthTokenResult> authorize() async {
    if (!_isApplePlatform) {
      throw const AuthException(
        'Sign in with Apple is only available on iOS and macOS. '
        'iCloud Drive cannot be accessed from Windows, Android, or Linux.',
      );
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        throw const AuthException('No identity token received from Apple.');
      }

      return OAuthTokenResult(
        // Apple identity tokens are short-lived (10 min). The stable identifier
        // is the userIdentifier — stored as refreshToken so we can recognise
        // the same Apple account across re-auths without re-prompting the user.
        accessToken: identityToken,
        refreshToken: credential.userIdentifier,
        accessTokenExpirationDateTime:
            DateTime.now().add(const Duration(minutes: 10)),
        idToken: identityToken,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Sign in cancelled.');
      }
      throw AuthException('Apple sign-in failed: ${e.message}', cause: e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AuthException('Apple sign-in failed: $e', cause: e);
    }
  }

  // Apple identity tokens expire in 10 minutes and cannot be refreshed by the
  // app — a new Sign in with Apple prompt is required. Returning null causes the
  // interceptor to skip refresh and use whatever token is cached; the user will
  // be prompted to re-auth on the next 401.
  Future<OAuthTokenResult?> refreshAccessToken(String accountId) async =>
      null;

  Future<void> revokeTokens(String accountId) async {
    await tokenStorage.deleteTokens(accountId);
  }
}
