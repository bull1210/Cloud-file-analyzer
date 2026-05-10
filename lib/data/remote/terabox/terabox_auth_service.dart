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

class TeraboxAuthService {
  TeraboxAuthService({required this.tokenStorage});

  final TokenStorageService tokenStorage;
  final _dio = Dio();

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  String get _redirectUri => _isDesktop
      ? TeraboxOAuthConstants.redirectUriDesktop
      : TeraboxOAuthConstants.redirectUriMobile;

  Future<OAuthTokenResult> authorize() async {
    logger.log('TeraboxAuth', 'authorize() isDesktop=$_isDesktop');
    try {
      final (codeVerifier, codeChallenge) = _generatePKCE();

      final authUri = Uri.parse(TeraboxOAuthConstants.authUrl).replace(
        queryParameters: {
          'client_id': TeraboxOAuthConstants.clientId,
          'response_type': 'code',
          'redirect_uri': _redirectUri,
          'scope': 'basic,netdisk',
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
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
      logger.error('TeraboxAuth', 'authorize() failed', e);
      throw AuthException('TeraBox authorization failed: $e', cause: e);
    }
  }

  Future<OAuthTokenResult> _exchangeCode(String code, String codeVerifier) async {
    final response = await _dio.post<Map<String, dynamic>>(
      TeraboxOAuthConstants.tokenUrl,
      data: {
        'code': code,
        'grant_type': 'authorization_code',
        'client_id': TeraboxOAuthConstants.clientId,
        'client_secret': TeraboxOAuthConstants.clientSecret,
        'redirect_uri': _redirectUri,
        'code_verifier': codeVerifier,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final data = response.data!;
    final expiresIn = data['expires_in'] as int?;
    logger.log('TeraboxAuth', 'Token exchange success');

    return OAuthTokenResult(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String?,
      accessTokenExpirationDateTime: expiresIn != null
          ? DateTime.now().add(Duration(seconds: expiresIn))
          : null,
    );
  }

  Future<OAuthTokenResult?> refreshAccessToken(String accountId) async {
    try {
      final refreshToken = await tokenStorage.getRefreshToken(accountId);
      if (refreshToken == null) return null;

      final response = await _dio.post<Map<String, dynamic>>(
        TeraboxOAuthConstants.tokenUrl,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': TeraboxOAuthConstants.clientId,
          'client_secret': TeraboxOAuthConstants.clientSecret,
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
      logger.error('TeraboxAuth', 'refreshAccessToken failed', e);
      throw const TokenExpiredException();
    }
  }

  Future<void> revokeTokens(String accountId) async {
    await tokenStorage.deleteTokens(accountId);
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
