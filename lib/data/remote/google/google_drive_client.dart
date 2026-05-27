import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../local/secure_storage/token_storage_service.dart';
import 'google_auth_service.dart';

class GoogleDriveClient {
  GoogleDriveClient({
    required this.tokenStorage,
    required this.authService,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: GoogleDriveEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
    _setupInterceptors();
  }

  final TokenStorageService tokenStorage;
  final GoogleAuthService authService;
  late final Dio _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accountId = options.extra['accountId'] as String?;
          if (accountId != null) {
            final isValid = await tokenStorage.isTokenValid(accountId);
            logger.log('DriveClient', '→ ${options.path} tokenValid=$isValid');
            if (!isValid) {
              logger.log('DriveClient', 'Token invalid — attempting refresh…');
              try {
                final refreshed = await authService.refreshAccessToken(accountId);
                if (refreshed != null) {
                  await tokenStorage.saveTokens(
                    accountId: accountId,
                    accessToken: refreshed.accessToken,
                    refreshToken: refreshed.refreshToken,
                    expiry: refreshed.accessTokenExpirationDateTime,
                  );
                  logger.log('DriveClient', 'Token refreshed successfully');
                } else {
                  logger.error('DriveClient', 'Refresh returned null (no refresh token stored)');
                }
              } catch (e) {
                logger.error('DriveClient', 'Token refresh threw', e);
              }
            }
            final token = await tokenStorage.getAccessToken(accountId);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              logger.error('DriveClient', 'No access token available for request');
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          logger.error('DriveClient', 'HTTP error ${error.response?.statusCode} on ${error.requestOptions.path}');
          if (error.response?.statusCode == 401) {
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: const TokenExpiredException(),
            ));
            return;
          }
          if (error.response?.statusCode == 403) {
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: const NetworkException(
                'Google Drive access denied. Make sure this Google account is '
                'added as a test user in Google Cloud Console while the app is '
                'unverified, and that the Google Drive API is enabled.',
                statusCode: 403,
              ),
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
                retryAfterSeconds:
                    retryAfter != null ? int.tryParse(retryAfter) : null,
              ),
            ));
            return;
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    required String accountId,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
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

  Future<Response<T>> patch<T>(
    String path, {
    required String accountId,
    Object? data,
  }) async {
    try {
      return await _dio.patch<T>(
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
}
