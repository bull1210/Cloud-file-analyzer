import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../local/secure_storage/token_storage_service.dart';
import 'terabox_auth_service.dart';

class TeraboxClient {
  TeraboxClient({
    required this.tokenStorage,
    required this.authService,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://openapi.terabox.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
    _setupInterceptors();
  }

  final TokenStorageService tokenStorage;
  final TeraboxAuthService authService;
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
                logger.error('TeraboxClient', 'Token refresh threw', e);
              }
            }
            final token = await tokenStorage.getAccessToken(_currentAccountId!);
            if (token != null) {
              options.queryParameters['access_token'] = token;
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          logger.error('TeraboxClient',
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
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
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
