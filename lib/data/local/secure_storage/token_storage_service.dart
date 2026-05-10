import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';

class TokenStorageService {
  TokenStorageService() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    wOptions: WindowsOptions(),
  );

  final FlutterSecureStorage _storage;

  // In-memory cache — avoids Windows Credential Manager write-then-read race
  final _cache = <String, String>{};

  String _accessKey(String accountId) => 'cv_access_$accountId';
  String _refreshKey(String accountId) => 'cv_refresh_$accountId';
  String _expiryKey(String accountId) => 'cv_expiry_$accountId';
  String _idTokenKey(String accountId) => 'cv_idtoken_$accountId';

  Future<void> saveTokens({
    required String accountId,
    required String accessToken,
    String? refreshToken,
    DateTime? expiry,
    String? idToken,
  }) async {
    logger.log('TokenStorage',
        'saveTokens id=${accountId.substring(0, 8)}… '
        'hasAccess=${accessToken.isNotEmpty} '
        'hasRefresh=${refreshToken != null} '
        'expiry=$expiry');
    try {
      // Update in-memory cache first so reads are immediately consistent
      _cache[_accessKey(accountId)] = accessToken;
      if (refreshToken != null) _cache[_refreshKey(accountId)] = refreshToken;
      if (expiry != null) {
        _cache[_expiryKey(accountId)] =
            expiry.millisecondsSinceEpoch.toString();
      }
      if (idToken != null) _cache[_idTokenKey(accountId)] = idToken;

      // Persist to secure storage (Credential Manager) in background
      await Future.wait([
        _storage.write(key: _accessKey(accountId), value: accessToken),
        if (refreshToken != null)
          _storage.write(key: _refreshKey(accountId), value: refreshToken),
        if (expiry != null)
          _storage.write(
            key: _expiryKey(accountId),
            value: expiry.millisecondsSinceEpoch.toString(),
          ),
        if (idToken != null)
          _storage.write(key: _idTokenKey(accountId), value: idToken),
      ]);
      logger.log('TokenStorage', 'saveTokens OK (cache + storage)');
    } catch (e) {
      logger.error('TokenStorage', 'saveTokens FAILED', e);
      throw StorageException('Failed to save tokens securely', cause: e);
    }
  }

  Future<String?> getAccessToken(String accountId) async {
    final cached = _cache[_accessKey(accountId)];
    if (cached != null) return cached;
    try {
      final value = await _storage.read(key: _accessKey(accountId));
      if (value != null) _cache[_accessKey(accountId)] = value;
      return value;
    } catch (e) {
      throw StorageException('Failed to read access token', cause: e);
    }
  }

  Future<String?> getRefreshToken(String accountId) async {
    final cached = _cache[_refreshKey(accountId)];
    if (cached != null) return cached;
    try {
      final value = await _storage.read(key: _refreshKey(accountId));
      if (value != null) _cache[_refreshKey(accountId)] = value;
      return value;
    } catch (e) {
      throw StorageException('Failed to read refresh token', cause: e);
    }
  }

  Future<DateTime?> getTokenExpiry(String accountId) async {
    final cached = _cache[_expiryKey(accountId)];
    final raw = cached ?? await _storage.read(key: _expiryKey(accountId));
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
  }

  Future<bool> isTokenValid(String accountId) async {
    final token = await getAccessToken(accountId);
    if (token == null) {
      logger.log('TokenStorage', 'isTokenValid=false (no access token)');
      return false;
    }
    final expiry = await getTokenExpiry(accountId);
    if (expiry == null) {
      logger.log('TokenStorage', 'isTokenValid=true (no expiry stored)');
      return true;
    }
    final valid = expiry.isAfter(DateTime.now().add(const Duration(minutes: 5)));
    logger.log('TokenStorage',
        'isTokenValid=$valid expiry=$expiry now=${DateTime.now()}');
    return valid;
  }

  Future<void> deleteTokens(String accountId) async {
    _cache.remove(_accessKey(accountId));
    _cache.remove(_refreshKey(accountId));
    _cache.remove(_expiryKey(accountId));
    _cache.remove(_idTokenKey(accountId));
    try {
      await Future.wait([
        _storage.delete(key: _accessKey(accountId)),
        _storage.delete(key: _refreshKey(accountId)),
        _storage.delete(key: _expiryKey(accountId)),
        _storage.delete(key: _idTokenKey(accountId)),
      ]);
    } catch (e) {
      throw StorageException('Failed to delete tokens', cause: e);
    }
  }

  Future<void> deleteAllTokens() async {
    _cache.clear();
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException('Failed to clear all tokens', cause: e);
    }
  }
}
