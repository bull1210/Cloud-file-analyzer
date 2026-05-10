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

const _tag = 'MicrosoftAuth';
const _tokenEndpoint =
    'https://login.microsoftonline.com/common/oauth2/v2.0/token';
const _authEndpoint =
    'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';

class MicrosoftAuthService {
  MicrosoftAuthService({required this.tokenStorage});

  final TokenStorageService tokenStorage;
  final _dio = Dio();

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  String get _redirectUri => _isDesktop
      ? MicrosoftOAuthConstants.redirectUriDesktop
      : MicrosoftOAuthConstants.redirectUriMobile;

  String get _callbackScheme =>
      _isDesktop ? 'http' : 'msauth.com.cloudvault.app';

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

  Future<OAuthTokenResult> authorize() async {
    logger.log(_tag, '─── authorize() START ───');
    logger.log(_tag, 'Platform: $defaultTargetPlatform  isDesktop=$_isDesktop  isAndroid=${defaultTargetPlatform == TargetPlatform.android}');
    logger.log(_tag, 'Redirect URI: $_redirectUri');
    logger.log(_tag, 'Callback scheme: $_callbackScheme');
    logger.log(_tag, 'Client ID: ${MicrosoftOAuthConstants.clientId}');
    logger.log(_tag, 'Scopes: ${MicrosoftOAuthConstants.scopes}');

    if (defaultTargetPlatform == TargetPlatform.android) {
      logger.log(_tag, '[Android] Auth mechanism: Chrome Custom Tab (CCT) via flutter_web_auth_2');
      logger.log(_tag, '[Android] CCT will open for Microsoft login; callback intercepted by CallbackActivity via intent-filter scheme=$_callbackScheme host=auth');
      logger.log(_tag, '[Android] Expected redirect: $_redirectUri?code=…');
      logger.log(_tag, '[Android] NOTE: if account is added but CCT does not visually close, FlutterWebAuth2.authenticate() DID return — the issue is native CCT task/activity stack management, not the Dart layer');
    }

    try {
      final (codeVerifier, codeChallenge) = _generatePKCE();
      logger.log(_tag, 'PKCE generated — verifier length=${codeVerifier.length}  challenge length=${codeChallenge.length}');

      final authUri = Uri.parse(_authEndpoint).replace(queryParameters: {
        'client_id': MicrosoftOAuthConstants.clientId,
        'redirect_uri': _redirectUri,
        'response_type': 'code',
        'response_mode': 'query',
        'scope': MicrosoftOAuthConstants.scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'prompt': 'select_account',
      });

      logger.log(_tag, 'Auth URI host: ${authUri.host}  path: ${authUri.path}');
      logger.log(_tag, 'Auth URI query params keys: ${authUri.queryParameters.keys.toList()}');
      logger.log(_tag, 'Full auth URI: $authUri');

      logger.log(_tag, 'Calling FlutterWebAuth2.authenticate — browser/webview will open now');
      final authenticateStart = DateTime.now();

      String result;
      try {
        result = await FlutterWebAuth2.authenticate(
          url: authUri.toString(),
          callbackUrlScheme: _callbackScheme,
          options: const FlutterWebAuth2Options(preferEphemeral: true),
        );
      } catch (e, st) {
        final elapsed = DateTime.now().difference(authenticateStart).inMilliseconds;
        logger.error(_tag, 'FlutterWebAuth2.authenticate threw after ${elapsed}ms — type=${e.runtimeType}  err=$e', e);
        logger.log(_tag, 'Stack: $st');
        rethrow;
      }

      final elapsed = DateTime.now().difference(authenticateStart).inMilliseconds;
      logger.log(_tag, 'FlutterWebAuth2.authenticate returned after ${elapsed}ms');
      logger.log(_tag, 'Raw callback result: $result');

      if (defaultTargetPlatform == TargetPlatform.android) {
        logger.log(_tag, '[Android] authenticate() returned — this means CallbackActivity received the intent and resolved the Future');
        logger.log(_tag, '[Android] If the Chrome Custom Tab is still visible at this point, the issue is NOT in Dart code — it is a CCT task/back-stack issue in the native layer');
        logger.log(_tag, '[Android] Check: does CallbackActivity have android:launchMode="singleTop" and android:taskAffinity="" in AndroidManifest.xml?');
        logger.log(_tag, '[Android] Known cause: singleTop + taskAffinity="" can put CallbackActivity in a different task than MainActivity, so finish() does not bring the app forward or close the CCT');
      }

      // Parse the redirect URI that came back from the auth browser.
      Uri redirectUri;
      try {
        redirectUri = Uri.parse(result);
        logger.log(_tag, 'Parsed redirect URI — scheme=${redirectUri.scheme}  host=${redirectUri.host}  port=${redirectUri.port}  path=${redirectUri.path}');
        logger.log(_tag, 'Redirect query parameter keys: ${redirectUri.queryParameters.keys.toList()}');
      } catch (e) {
        logger.error(_tag, 'Failed to parse callback result as URI', e);
        rethrow;
      }

      // Log every query parameter (value truncated where sensitive).
      redirectUri.queryParameters.forEach((k, v) {
        final display = (k == 'code' || k == 'id_token' || k == 'access_token')
            ? '${v.substring(0, v.length.clamp(0, 8))}…[len=${v.length}]'
            : v;
        logger.log(_tag, '  query[$k] = $display');
      });

      final error = redirectUri.queryParameters['error'];
      if (error != null) {
        final desc = redirectUri.queryParameters['error_description']
                ?.replaceAll('+', ' ') ??
            error;
        final errorUri = redirectUri.queryParameters['error_uri'];
        logger.error(_tag, 'OAuth error in redirect — error=$error  description=$desc  error_uri=$errorUri');
        throw AuthException(desc);
      }

      final code = redirectUri.queryParameters['code'];
      if (code == null) {
        logger.error(_tag, 'No "code" parameter in redirect. All keys present: ${redirectUri.queryParameters.keys.toList()}');
        throw const AuthException('No authorization code in redirect');
      }

      final sessionState = redirectUri.queryParameters['session_state'];
      logger.log(_tag, 'Authorization code received — length=${code.length}  prefix=${code.substring(0, code.length.clamp(0, 8))}…  session_state=${sessionState ?? 'null'}');

      logger.log(_tag, 'Starting code exchange at token endpoint');
      final tokenResult = await _exchangeCode(code, codeVerifier);
      logger.log(_tag, 'Code exchange succeeded — accessToken present=${tokenResult.accessToken.isNotEmpty}  refreshToken present=${tokenResult.refreshToken != null}  expiry=${tokenResult.accessTokenExpirationDateTime}  idToken present=${tokenResult.idToken != null}');
      logger.log(_tag, '─── authorize() END — success ───');
      return tokenResult;
    } on AppException catch (e) {
      logger.error(_tag, 'authorize() failed with AppException: $e');
      logger.log(_tag, '─── authorize() END — AppException ───');
      rethrow;
    } catch (e, st) {
      logger.error(_tag, 'authorize() failed with unexpected error: $e', e);
      logger.log(_tag, 'Stack: $st');
      logger.log(_tag, '─── authorize() END — unexpected error ───');
      throw AuthException('Microsoft authorization failed: $e', cause: e);
    }
  }

  Future<OAuthTokenResult> _exchangeCode(
      String code, String codeVerifier) async {
    logger.log(_tag, '_exchangeCode() — endpoint=$_tokenEndpoint  redirect_uri=$_redirectUri');
    logger.log(_tag, '_exchangeCode() — code_verifier length=${codeVerifier.length}');

    final body = {
      'client_id': MicrosoftOAuthConstants.clientId,
      'code': code,
      'code_verifier': codeVerifier,
      'grant_type': 'authorization_code',
      'redirect_uri': _redirectUri,
      'scope': MicrosoftOAuthConstants.scopes.join(' '),
    };
    logger.log(_tag, '_exchangeCode() POST body keys: ${body.keys.toList()}');

    Response response;
    try {
      response = await _dio.post(
        _tokenEndpoint,
        data: body,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } on DioException catch (e) {
      logger.error(_tag, '_exchangeCode() DioException — status=${e.response?.statusCode}  type=${e.type}');
      logger.log(_tag, '_exchangeCode() DioException response body: ${e.response?.data}');
      rethrow;
    }

    logger.log(_tag, '_exchangeCode() response status=${response.statusCode}');

    final data = response.data as Map<String, dynamic>;
    logger.log(_tag, '_exchangeCode() response keys: ${data.keys.toList()}');

    if (data.containsKey('error')) {
      logger.error(_tag, '_exchangeCode() token error=${data['error']}  description=${data['error_description']}');
      throw AuthException(data['error_description']?.toString() ?? data['error'].toString());
    }

    final hasAccessToken  = data.containsKey('access_token');
    final hasRefreshToken = data.containsKey('refresh_token');
    final hasIdToken      = data.containsKey('id_token');
    final expiresIn       = data['expires_in'] as int?;
    final tokenType       = data['token_type'];
    final scope           = data['scope'];
    logger.log(_tag, '_exchangeCode() access_token=$hasAccessToken  refresh_token=$hasRefreshToken  id_token=$hasIdToken  expires_in=$expiresIn  token_type=$tokenType');
    logger.log(_tag, '_exchangeCode() granted scope: $scope');

    if (!hasAccessToken) {
      logger.error(_tag, '_exchangeCode() MISSING access_token in response — full keys: ${data.keys.toList()}');
      throw const AuthException('Token response missing access_token');
    }

    return OAuthTokenResult(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String?,
      accessTokenExpirationDateTime: expiresIn != null
          ? DateTime.now().add(Duration(seconds: expiresIn))
          : null,
      idToken: data['id_token'] as String?,
    );
  }

  Future<OAuthTokenResult?> refreshAccessToken(String accountId) async {
    logger.log(_tag, 'refreshAccessToken() — accountId=${accountId.substring(0, 8)}…');
    try {
      final refreshToken = await tokenStorage.getRefreshToken(accountId);
      if (refreshToken == null) {
        logger.log(_tag, 'refreshAccessToken() — no stored refresh token, returning null');
        return null;
      }
      logger.log(_tag, 'refreshAccessToken() — stored refresh token found, exchanging…');

      final response = await _dio.post(
        _tokenEndpoint,
        data: {
          'client_id': MicrosoftOAuthConstants.clientId,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
          'scope': MicrosoftOAuthConstants.scopes.join(' '),
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data as Map<String, dynamic>;
      logger.log(_tag, 'refreshAccessToken() — response status=${response.statusCode}  keys=${data.keys.toList()}');

      if (data.containsKey('error')) {
        logger.error(_tag, 'refreshAccessToken() token error=${data['error']}  description=${data['error_description']}');
        throw const TokenExpiredException();
      }

      final expiresIn = data['expires_in'] as int?;
      final hasNewRefresh = data.containsKey('refresh_token');
      logger.log(_tag, 'refreshAccessToken() — new access_token=${data.containsKey('access_token')}  new_refresh_token=$hasNewRefresh  expires_in=$expiresIn');

      return OAuthTokenResult(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String? ?? refreshToken,
        accessTokenExpirationDateTime: expiresIn != null
            ? DateTime.now().add(Duration(seconds: expiresIn))
            : null,
      );
    } catch (e) {
      logger.error(_tag, 'refreshAccessToken() failed: $e', e);
      throw const TokenExpiredException();
    }
  }

  Future<void> revokeTokens(String accountId) async {
    logger.log(_tag, 'revokeTokens() — accountId=${accountId.substring(0, 8)}…');
    await tokenStorage.deleteTokens(accountId);
    logger.log(_tag, 'revokeTokens() — done');
  }
}
