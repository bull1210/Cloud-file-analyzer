import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../core/constants/oauth_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../local/secure_storage/token_storage_service.dart';
import '../oauth_token_result.dart';

class DropboxAuthService {
  DropboxAuthService({required this.tokenStorage});

  final TokenStorageService tokenStorage;
  final _dio = Dio();

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  String get _redirectUri => _isDesktop
      ? DropboxOAuthConstants.redirectUriDesktop
      : DropboxOAuthConstants.redirectUriMobile;

  Future<OAuthTokenResult> authorize() async {
    logger.log('DropboxAuth', 'authorize() isDesktop=$_isDesktop');
    try {
      final (codeVerifier, codeChallenge) = _generatePKCE();

      final authUri = Uri.parse(DropboxOAuthConstants.authUrl).replace(
        queryParameters: {
          'client_id': DropboxOAuthConstants.appKey,
          'response_type': 'code',
          'redirect_uri': _redirectUri,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
          'token_access_type': 'offline',
          'scope': DropboxOAuthConstants.scopes.join(' '),
        },
      );

      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: _isDesktop ? 'http' : 'cloudvaultapp',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw const AuthException('No authorization code in redirect');

      return await _exchangeCode(code, codeVerifier);
    } on AppException {
      rethrow;
    } catch (e) {
      logger.error('DropboxAuth', 'authorize() failed', e);
      throw AuthException('Dropbox authorization failed: $e', cause: e);
    }
  }

  Future<OAuthTokenResult> _exchangeCode(String code, String codeVerifier) async {
    final response = await _dio.post<Map<String, dynamic>>(
      DropboxOAuthConstants.tokenUrl,
      data: {
        'code': code,
        'grant_type': 'authorization_code',
        'redirect_uri': _redirectUri,
        'client_id': DropboxOAuthConstants.appKey,
        'code_verifier': codeVerifier,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final data = response.data!;
    final expiresIn = data['expires_in'] as int?;
    logger.log('DropboxAuth', 'Token exchange success — hasRefresh=${data['refresh_token'] != null}');

    return OAuthTokenResult(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String?,
      accessTokenExpirationDateTime: expiresIn != null
          ? DateTime.now().add(Duration(seconds: expiresIn))
          : null,
    );
  }

  Future<OAuthTokenResult?> refreshAccessToken(String accountId) async {
    logger.log('DropboxAuth', 'refreshAccessToken()');
    try {
      final refreshToken = await tokenStorage.getRefreshToken(accountId);
      if (refreshToken == null) return null;

      final response = await _dio.post<Map<String, dynamic>>(
        DropboxOAuthConstants.tokenUrl,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': DropboxOAuthConstants.appKey,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data!;
      final expiresIn = data['expires_in'] as int?;
      return OAuthTokenResult(
        accessToken: data['access_token'] as String,
        refreshToken: refreshToken,
        accessTokenExpirationDateTime: expiresIn != null
            ? DateTime.now().add(Duration(seconds: expiresIn))
            : null,
      );
    } catch (e) {
      logger.error('DropboxAuth', 'refreshAccessToken failed', e);
      throw const TokenExpiredException();
    }
  }

  Future<void> revokeTokens(String accountId) async {
    try {
      final token = await tokenStorage.getAccessToken(accountId);
      if (token != null) {
        await _dio.post(
          'https://api.dropboxapi.com/2/auth/token/revoke',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      logger.error('DropboxAuth', 'revokeTokens failed (best-effort)', e);
    } finally {
      await tokenStorage.deleteTokens(accountId);
    }
  }

  (String, String) _generatePKCE() {
    final rng = Random.secure();
    final verifierBytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final verifier = base64Url.encode(verifierBytes).replaceAll('=', '');
    final challengeBytes = sha256.convert(utf8.encode(verifier)).bytes;
    final challenge = base64Url.encode(challengeBytes).replaceAll('=', '');
    return (verifier, challenge);
  }
}
