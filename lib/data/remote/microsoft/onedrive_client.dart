import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../local/secure_storage/token_storage_service.dart';
import 'microsoft_auth_service.dart';

class OneDriveClient {
  OneDriveClient({
    required this.tokenStorage,
    required this.authService,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: OneDriveEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
    _setupInterceptors();
  }

  final TokenStorageService tokenStorage;
  final MicrosoftAuthService authService;
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
                final refreshed =
                    await authService.refreshAccessToken(accountId);
                if (refreshed != null) {
                  await tokenStorage.saveTokens(
                    accountId: accountId,
                    accessToken: refreshed.accessToken,
                    refreshToken: refreshed.refreshToken,
                    expiry: refreshed.accessTokenExpirationDateTime,
                  );
                }
              } catch (_) {}
            }
            final token = await tokenStorage.getAccessToken(accountId);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
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
                'OneDrive access denied. Check that the app registration in '
                'Azure has the Files.Read and User.Read permissions granted.',
                statusCode: 403,
              ),
            ));
            return;
          }
          if (error.response?.statusCode == 429) {
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: DioExceptionType.badResponse,
              error: const RateLimitException(),
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

  Future<Response<T>> delete<T>(String path, {required String accountId}) async {
    try {
      return await _dio.delete<T>(
        path,
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
