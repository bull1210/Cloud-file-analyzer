import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../local/secure_storage/token_storage_service.dart';
import 'dropbox_auth_service.dart';

class DropboxClient {
  DropboxClient({
    required this.tokenStorage,
    required this.authService,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.dropboxapi.com/2',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      contentType: 'application/json',
    ));
    _setupInterceptors();
  }

  final TokenStorageService tokenStorage;
  final DropboxAuthService authService;
  late final Dio _dio;

  String? _currentAccountId;

  void setAccount(String accountId) => _currentAccountId = accountId;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_currentAccountId != null) {
            final isValid = await tokenStorage.isTokenValid(_currentAccountId!);
            if (!isValid) {
              try {
                final refreshed = await authService.refreshAccessToken(_currentAccountId!);
                if (refreshed != null) {
                  await tokenStorage.saveTokens(
                    accountId: _currentAccountId!,
                    accessToken: refreshed.accessToken,
                    refreshToken: refreshed.refreshToken,
                    expiry: refreshed.accessTokenExpirationDateTime,
                  );
                }
              } catch (e) {
                logger.error('DropboxClient', 'Token refresh threw', e);
              }
            }
            final token = await tokenStorage.getAccessToken(_currentAccountId!);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          logger.error('DropboxClient',
              'HTTP ${error.response?.statusCode} on ${error.requestOptions.uri}');
          if (error.response?.statusCode == 401) {
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: const TokenExpiredException(),
            ));
            return;
          }
          if (error.response?.statusCode == 429) {
            final retryAfter = error.response?.headers.value('Retry-After');
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: RateLimitException(
                retryAfterSeconds: retryAfter != null ? int.tryParse(retryAfter) : null,
              ),
            ));
            return;
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> post<T>(String path, {Object? data}) async {
    try {
      return await _dio.post<T>(path, data: data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw NetworkException(
        e.message ?? 'Network error',
        cause: e,
        statusCode: e.response?.statusCode,
      );
    }
  }

  // Dropbox API v2 requires every POST to carry a JSON body.
  // For no-argument endpoints (e.g. users/get_current_account) the body must be
  // the JSON null literal — an empty body with Content-Type: application/json
  // is rejected with HTTP 400.
  Future<Response<T>> postEmpty<T>(String path) => post<T>(path, data: 'null');
}
