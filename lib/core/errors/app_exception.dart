sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

final class TokenExpiredException extends AuthException {
  const TokenExpiredException() : super('Session expired. Please sign in again.');
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause, this.statusCode});

  final int? statusCode;
}

final class RateLimitException extends NetworkException {
  const RateLimitException({int? retryAfterSeconds})
      : retryAfter = retryAfterSeconds,
        super('API rate limit reached. Please wait before retrying.', statusCode: 429);

  final int? retryAfter;
}

final class ScanException extends AppException {
  const ScanException(super.message, {super.cause});
}

final class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

final class ExportException extends AppException {
  const ExportException(super.message, {super.cause});
}
