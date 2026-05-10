// OAuth client IDs and configuration.
// Replace placeholder values with your actual credentials from:
//   Google: console.cloud.google.com
//   Microsoft: portal.azure.com
//
// DO NOT commit real credentials. Use environment variables or a
// gitignored secrets.dart file in production.

class GoogleOAuthConstants {
  GoogleOAuthConstants._();

  // Create at: console.cloud.google.com → APIs & Services → Credentials
  // Android client type — SHA-1 + package name registered in Google Console
  static const String clientIdAndroid = 'YOUR_GOOGLE_CLIENT_ID_ANDROID.apps.googleusercontent.com';
  static const String clientIdIos = 'YOUR_GOOGLE_CLIENT_ID_IOS.apps.googleusercontent.com';
  // Desktop App client type — loopback redirect
  static const String clientIdDesktop = 'YOUR_GOOGLE_CLIENT_ID_DESKTOP.apps.googleusercontent.com';
  static const String clientSecretDesktop = 'YOUR_GOOGLE_CLIENT_SECRET_DESKTOP';

  // Scopes: drive gives full metadata + trash access needed for duplicate deletion.
  // Re-auth is required for accounts previously authorised with drive.metadata.readonly.
  static const List<String> scopes = [
    'openid',
    'email',
    'profile',
    'https://www.googleapis.com/auth/drive',
  ];

  // Android: reversed client ID scheme — required by Google for sensitive scopes
  // in native apps. Derived automatically from clientIdAndroid.
  static String get redirectUriAndroid {
    final prefix = clientIdAndroid.replaceAll('.apps.googleusercontent.com', '');
    return 'com.googleusercontent.apps.$prefix:/oauth2redirect';
  }

  static String get callbackSchemeAndroid {
    final prefix = clientIdAndroid.replaceAll('.apps.googleusercontent.com', '');
    return 'com.googleusercontent.apps.$prefix';
  }

  static const String redirectUriIos = 'com.cloudvault.app:/oauth2redirect';
  // Desktop: loopback redirect — requires Desktop App OAuth client type in Google Console
  static const String redirectUriDesktop = 'http://localhost';

  static const String discoveryUrl =
      'https://accounts.google.com/.well-known/openid-configuration';
}

class DropboxOAuthConstants {
  DropboxOAuthConstants._();

  // Create at: www.dropbox.com/developers/apps → Create App → Scoped access
  // Required permissions: files.metadata.read, account_info.read
  static const String appKey = 'YOUR_DROPBOX_APP_KEY';

  static const List<String> scopes = [
    'files.metadata.read',
    'account_info.read',
  ];

  static const String redirectUriDesktop = 'http://localhost';
  static const String redirectUriMobile = 'cloudvaultapp://oauth/dropbox';

  static const String authUrl = 'https://www.dropbox.com/oauth2/authorize';
  static const String tokenUrl = 'https://api.dropboxapi.com/oauth2/token';
}

class TeraboxOAuthConstants {
  TeraboxOAuthConstants._();

  // Create at: developer.terabox.com → My Apps → Create App
  static const String clientId = 'YOUR_TERABOX_CLIENT_ID';
  static const String clientSecret = 'YOUR_TERABOX_CLIENT_SECRET';

  static const String redirectUriDesktop = 'http://localhost';
  static const String redirectUriMobile = 'cloudvaultapp://oauth/terabox';

  static const String authUrl = 'https://openapi.terabox.com/oauth/authorize';
  static const String tokenUrl = 'https://openapi.terabox.com/oauth/token';
}

class MegaOAuthConstants {
  MegaOAuthConstants._();
  // MEGA uses email + password auth — no OAuth client ID needed.
  // Authentication uses MEGA's direct API at g.api.mega.co.nz.
}

class AppleOAuthConstants {
  AppleOAuthConstants._();

  // Register at: developer.apple.com → Certificates, IDs & Profiles → Identifiers
  // Create an App ID with "Sign In with Apple" capability enabled.
  // The bundle ID must match the one used in Xcode (com.cloudvault.app).
  //
  // For macOS: enable the "Sign In with Apple" entitlement in Xcode.
  // For iOS:   add the "Sign In with Apple" capability in the Signing & Capabilities tab.
  //
  // No client secret is required — the native SDK handles the JWT exchange.
  static const String bundleId = 'com.cloudvault.app';

  // iCloud container ID — used when native iCloud Drive scanning is implemented.
  // Register at: developer.apple.com → Identifiers → + → iCloud Containers.
  static const String iCloudContainerId = 'iCloud.com.cloudvault.app';
}

class MicrosoftOAuthConstants {
  MicrosoftOAuthConstants._();

  // Create at: portal.azure.com → Azure AD → App registrations
  static const String clientId = 'YOUR_MICROSOFT_CLIENT_ID';

  // Covers both personal Microsoft accounts and work/school accounts
  static const String authority =
      'https://login.microsoftonline.com/common';

  // Scopes: Files.ReadWrite enables trashing duplicates via the Graph API.
  // Re-auth is required for accounts previously authorised with Files.Read only.
  static const List<String> scopes = [
    'openid',
    'offline_access',
    'https://graph.microsoft.com/Files.ReadWrite',
    'https://graph.microsoft.com/User.Read',
  ];

  static const String redirectUriMobile = 'msauth.com.cloudvault.app://auth';
  // Desktop: loopback redirect — register http://localhost under Mobile and desktop apps in Azure
  static const String redirectUriDesktop = 'http://localhost';
}
