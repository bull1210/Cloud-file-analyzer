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

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accountId = options.extra['accountId'] as String?;
          if (accountId != null) {
            final isValid = await tokenStorage.isTokenValid(accountId);
            if (!isValid) {
              try {
                final refreshed = await authService.refreshAccessToken(accountId);
                if (refreshed != null) {
                  await tokenStorage.saveTokens(
                    accountId: accountId,
                    accessToken: refreshed.accessToken,
                    refreshToken: refreshed.refreshToken,
                    expiry: refreshed.accessTokenExpirationDateTime,
                  );
                }
              } catch (e) {
                logger.error('DropboxClient', 'Token refresh threw', e);
              }
            }
            final token = await tokenStorage.getAccessToken(accountId);
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

  Future<Response<T>> post<T>(String path, {required String accountId, Object? data}) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        options: Options(extra: {'accountId': accountId}),
      );
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
  Future<Response<T>> postEmpty<T>(String path, {required String accountId}) =>
      post<T>(path, accountId: accountId, data: 'null');
}
