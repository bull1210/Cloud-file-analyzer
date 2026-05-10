import 'dart:convert';

import '../../../core/errors/app_exception.dart';

class ICloudUserInfo {
  const ICloudUserInfo({
    required this.email,
    required this.displayName,
  });

  final String email;
  final String displayName;
}

class ICloudApi {
  ICloudApi();

  /// Extracts user info from the Apple identity token (JWT).
  /// Apple only includes email and name on the very first sign-in; subsequent
  /// sign-ins omit them. The caller must persist these values in the DB and
  /// fall back to cached values when the token omits them.
  ICloudUserInfo getUserInfoFromIdToken(String? idToken) {
    if (idToken == null) return const ICloudUserInfo(email: '', displayName: '');

    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return const ICloudUserInfo(email: '', displayName: '');
      final padded = base64Url.normalize(parts[1]);
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(padded))) as Map<String, dynamic>;

      final email = payload['email'] as String? ?? '';
      // 'name' claim is non-standard; Apple omits it from identity tokens.
      // The full name is returned separately in the credential object and must
      // be persisted by the caller on first sign-in.
      return ICloudUserInfo(email: email, displayName: email);
    } catch (_) {
      return const ICloudUserInfo(email: '', displayName: '');
    }
  }

  /// Validates that the provider is reachable before wiping existing data.
  /// iCloud Drive has no public REST API; native iOS/macOS scanning via
  /// NSMetadataQuery is planned for a future update.
  Future<void> testConnection() async {
    throw const ScanException(
      'iCloud Drive scanning is not yet available on this platform.\n'
      'Native scanning on iOS and macOS is planned for a future release.\n'
      'Your account is connected — re-try once native support ships.',
    );
  }
}
