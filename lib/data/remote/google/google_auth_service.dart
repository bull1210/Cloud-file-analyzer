import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/oauth_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../local/secure_storage/token_storage_service.dart';
import '../oauth_token_result.dart';

class GoogleAuthService {
  GoogleAuthService({
    required this.tokenStorage,
    List<String>? scopes,
  }) : _scopes = scopes ?? GoogleOAuthConstants.scopes;

  final TokenStorageService tokenStorage;
  final List<String> _scopes;
  final _dio = Dio();

  // Instance-level so Drive and Photos services each get their own
  // GoogleSignIn with the correct scopes on Android/iOS.
  late final _googleSignIn = GoogleSignIn(scopes: _scopes);

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  String get _clientId => GoogleOAuthConstants.clientIdDesktop;

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<OAuthTokenResult> authorize() async {
    logger.log('GoogleAuth', 'authorize() started — isDesktop=$_isDesktop');
    if (_isDesktop) return _authorizeDesktop();
    return _authorizeMobile();
  }

  Future<OAuthTokenResult?> refreshAccessToken(String accountId) async {
    logger.log('GoogleAuth', 'refreshAccessToken() for accountId=${accountId.substring(0, 8)}…');
    if (!_isDesktop) return _refreshMobile(accountId);

    try {
      final refreshToken = await tokenStorage.getRefreshToken(accountId);
      if (refreshToken == null) {
        logger.error('GoogleAuth', 'No refresh token stored — cannot refresh');
        return null;
      }
      logger.log('GoogleAuth', 'Calling token endpoint for desktop refresh…');

      final response = await _dio.post(
        'https://oauth2.googleapis.com/token',
        data: {
          'client_id': _clientId,
          'client_secret': GoogleOAuthConstants.clientSecretDesktop,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data as Map<String, dynamic>;
      final expiresIn = data['expires_in'] as int?;
      logger.log('GoogleAuth', 'Desktop refresh success — expiresIn=${expiresIn}s');

      return OAuthTokenResult(
        accessToken: data['access_token'] as String,
        refreshToken: refreshToken,
        accessTokenExpirationDateTime: expiresIn != null
            ? DateTime.now().add(Duration(seconds: expiresIn))
            : null,
      );
    } catch (e) {
      logger.error('GoogleAuth', 'refreshAccessToken failed', e);
      throw const TokenExpiredException();
    }
  }

  Future<void> revokeTokens(String accountId) async {
    logger.log('GoogleAuth', 'revokeTokens() for accountId=${accountId.substring(0, 8)}…');
    try {
      if (_isDesktop) {
        final accessToken = await tokenStorage.getAccessToken(accountId);
        if (accessToken != null) {
          await _dio.post(
            'https://oauth2.googleapis.com/revoke',
            queryParameters: {'token': accessToken},
          );
        }
      } else {
        await _googleSignIn.disconnect();
        logger.log('GoogleAuth', 'Mobile: disconnected from Google Sign-In');
      }
    } catch (e) {
      logger.error('GoogleAuth', 'revokeTokens failed (best-effort)', e);
    } finally {
      await tokenStorage.deleteTokens(accountId);
    }
  }

  // ── Desktop: PKCE via flutter_web_auth_2 ──────────────────────────────────

  Future<OAuthTokenResult> _authorizeDesktop() async {
    try {
      final (codeVerifier, codeChallenge) = _generatePKCE();

      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': _clientId,
        'redirect_uri': GoogleOAuthConstants.redirectUriDesktop,
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'prompt': 'consent',
        'access_type': 'offline',
      });

      logger.log('GoogleAuth', 'Desktop: opening browser for OAuth…');
      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: 'http',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw const AuthException('No authorization code in redirect');

      return await _exchangeCodeDesktop(code, codeVerifier);
    } on AppException {
      rethrow;
    } catch (e) {
      logger.error('GoogleAuth', '_authorizeDesktop() failed', e);
      throw AuthException('Google authorization failed: $e', cause: e);
    }
  }

  Future<OAuthTokenResult> _exchangeCodeDesktop(String code, String codeVerifier) async {
    try {
      final response = await _dio.post(
        'https://oauth2.googleapis.com/token',
        data: {
          'client_id': _clientId,
          'client_secret': GoogleOAuthConstants.clientSecretDesktop,
          'code': code,
          'code_verifier': codeVerifier,
          'grant_type': 'authorization_code',
          'redirect_uri': GoogleOAuthConstants.redirectUriDesktop,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data as Map<String, dynamic>;
      final expiresIn = data['expires_in'] as int?;
      final grantedScopes = data['scope'] as String? ?? '(none)';
      logger.log('GoogleAuth',
          'Desktop token exchange success — hasRefreshToken=${data['refresh_token'] != null} grantedScopes=$grantedScopes');

      return OAuthTokenResult(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String?,
        accessTokenExpirationDateTime: expiresIn != null
            ? DateTime.now().add(Duration(seconds: expiresIn))
            : null,
        idToken: data['id_token'] as String?,
      );
    } catch (e) {
      logger.error('GoogleAuth', '_exchangeCodeDesktop failed', e);
      rethrow;
    }
  }

  (String, String) _generatePKCE() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    final verifier =
        List.generate(64, (_) => chars[rng.nextInt(chars.length)]).join();
    final challenge =
        base64UrlEncode(sha256.convert(utf8.encode(verifier)).bytes)
            .replaceAll('=', '');
    return (verifier, challenge);
  }

  // ── Mobile: google_sign_in (uses Google Play Services on Android) ──────────

  Future<OAuthTokenResult> _authorizeMobile() async {
    try {
      logger.log('GoogleAuth', 'Mobile: starting Google Sign-In via Play Services…');

      // Sign out first to force the account picker on each sign-in
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();
      if (account == null) throw const AuthException('Sign-in was cancelled by the user');

      final auth = await account.authentication;
      if (auth.accessToken == null) throw const AuthException('Google Sign-In returned no access token');

      logger.log('GoogleAuth',
          'Mobile sign-in success — email=${account.email} hasIdToken=${auth.idToken != null}');

      return OAuthTokenResult(
        accessToken: auth.accessToken!,
        refreshToken: null, // managed internally by google_sign_in
        accessTokenExpirationDateTime: DateTime.now().add(const Duration(hours: 1)),
        idToken: auth.idToken,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      logger.error('GoogleAuth', '_authorizeMobile() failed', e);
      throw AuthException('Google sign-in failed: $e', cause: e);
    }
  }

  Future<OAuthTokenResult?> _refreshMobile(String accountId) async {
    try {
      logger.log('GoogleAuth', 'Mobile: refreshing via silent sign-in…');
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();

      if (account == null) {
        logger.error('GoogleAuth', 'Mobile refresh: no current user, re-auth required');
        return null;
      }

      // Calling .authentication always returns a fresh token
      final auth = await account.authentication;
      if (auth.accessToken == null) return null;

      logger.log('GoogleAuth', 'Mobile refresh success');
      return OAuthTokenResult(
        accessToken: auth.accessToken!,
        refreshToken: null,
        accessTokenExpirationDateTime: DateTime.now().add(const Duration(hours: 1)),
        idToken: auth.idToken,
      );
    } catch (e) {
      logger.error('GoogleAuth', '_refreshMobile failed', e);
      throw const TokenExpiredException();
    }
  }
}
