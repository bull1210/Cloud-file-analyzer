# OAuth Setup Guide

This document explains how to register CloudVault Analyzer with Google Cloud Console and the Azure Portal so that OAuth 2.0 sign-in works on every platform.

After completing both sections, edit `lib/core/constants/oauth_constants.dart` with your real credentials.

---

## Part 1 — Google Drive (Google Cloud Console)

### Step 1: Create a project

  1. Go to https://console.cloud.google.com
  2. Click the project dropdown (top-left, next to "Google Cloud")
  3. Click New Project → give it a name (e.g. CloudVault Analyzer) → Create
  4. Make sure that project is selected before continuing

  ---
  Step 2 — Enable Required APIs

  1. Go to APIs & Services → Library
  2. Search and enable each of these:
    - Google Drive API
    - Gmail API
    - Google Calendar API
  3. Click each → Enable

  ---
  Step 3 — Configure OAuth Consent Screen (do this before creating credentials)

  1. Go to APIs & Services → OAuth consent screen
  2. Choose External → Create
  3. Fill in:
    - App name: CloudVault Analyzer
    - User support email: your email
    - Developer contact email: your email
  4. Click Save and Continue
  5. Scopes page → click Add or Remove Scopes, add:
    - .../auth/drive
    - .../auth/gmail.readonly (or .modify)
    - .../auth/calendar.readonly
  6. Click Save and Continue
  7. Test users → add your Gmail address → Save and Continue
  8. Review summary → Back to Dashboard

  ---
  Step 4 — Create OAuth Client ID (Android)

  1. Go to APIs & Services → Credentials
  2. Click + Create Credentials → OAuth client ID
  3. Application type: Android
  4. Name: e.g. CloudVault Android
  5. Package name: com.cloudvault.app (must match your applicationId exactly)
  6. SHA-1 certificate fingerprint — run this to get it:
  keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass
  android
  6. Copy the SHA1: line and paste it in
  7. Click Create
  8. Download the JSON → rename it google-services.json → place it at:
  android/app/google-services.json

clientid - YOUR_GOOGLE_CLIENT_ID_ANDROID.apps.googleusercontent.com

  ---
  Step 5 — Create OAuth Client ID (Web — needed for token exchange)

  1. + Create Credentials → OAuth client ID again
  2. Application type: Web application
  3. Name: e.g. CloudVault Web
  4. Leave redirect URIs empty for now (add later if using web login)
  5. Click Create
  6. Copy the Client ID and Client Secret — you'll need these in your Flutter app's config

clinetid - YOUR_GOOGLE_CLIENT_ID_WEB.apps.googleusercontent.com
clientsecret - YOUR_GOOGLE_CLIENT_SECRET_WEB


desktop app 
clientid - YOUR_GOOGLE_CLIENT_ID_DESKTOP.apps.googleusercontent.com
secret - YOUR_GOOGLE_CLIENT_SECRET_DESKTOP

  ---
  Step 6 — Wire up google-services.json in Gradle

  In android/app/build.gradle, the plugin line should already be present:
  id "com.google.gms.google-services"

  In android/settings.gradle, add to the plugins block:
  id "com.google.gms.google-services" version "4.4.2" apply false

  ---
  Step 7 — Publish (when ready for real users)

  While in Testing mode only your test users can sign in. To allow anyone:
  - Go to OAuth consent screen → Publish App → Confirm
  - This triggers Google's verification process for sensitive scopes

  ---
  After placing google-services.json, re-run flutter build apk --release. Let me know what OAuth library you're using
  (google_sign_in, googleapis_auth, etc.) and I can help wire up the client IDs in code.
  
#### iOS client

1. Application type: **iOS**
2. Name: `CloudVault iOS`
3. Bundle ID: `com.cloudvault.app`
4. **Create** → copy the **Client ID**

> The iOS Client ID is also your **reversed client ID** for the URL scheme: `com.googleusercontent.apps.YOUR_CLIENT_ID` (replace dots with nothing, it's already reversed by Google).

#### Desktop client (Windows / macOS / Linux)

1. Application type: **Desktop app**
2. Name: `CloudVault Desktop`
3. **Create** → copy the **Client ID** and **Client Secret**

> Desktop uses a loopback redirect (`http://127.0.0.1`). `flutter_appauth` picks a random free port automatically.

### Step 5: Update oauth_constants.dart

```dart
// lib/core/constants/oauth_constants.dart

class GoogleOAuthConstants {
  static const String clientIdAndroid =
      'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';
  static const String clientIdIos =
      'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';
  static const String clientIdDesktop =
      'YOUR_DESKTOP_CLIENT_ID.apps.googleusercontent.com';
  static const String clientSecretDesktop = 'YOUR_DESKTOP_CLIENT_SECRET';
  ...
}
```

### Step 6: Configure Android redirect URI

Open `android/app/src/main/AndroidManifest.xml` and add inside `<application>`:

```xml
<activity
    android:name="net.openid.appauth.RedirectUriReceiverActivity"
    android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <!-- Must match GoogleOAuthConstants.redirectUriAndroid -->
    <data android:scheme="com.cloudvault.app"/>
  </intent-filter>
</activity>
```

### Step 7: Configure iOS URL scheme

In `ios/Runner/Info.plist`, add inside the root `<dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Google reversed client ID for iOS -->
      <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
      <!-- App's own scheme for the custom redirect -->
      <string>com.cloudvault.app</string>
    </array>
  </dict>
</array>
```

---

## Part 2 — Microsoft OneDrive (Azure Portal)

### Step 1: Register the app

1. Go to [portal.azure.com](https://portal.azure.com)
2. Search for **App registrations** → **New registration**
3. Name: `CloudVault Analyzer`
4. Supported account types: **Accounts in any organizational directory and personal Microsoft accounts**
5. Redirect URI: leave blank for now → **Register**
6. Copy the **Application (client) ID** — this is `MicrosoftOAuthConstants.clientId`

### Step 2: Add API permissions

1. In your app registration → **API permissions** → **Add a permission**
2. **Microsoft Graph** → **Delegated permissions** → add:
   - `Files.Read`
   - `User.Read`
   - `offline_access`
   - `openid`
3. Click **Add permissions**
4. Click **Grant admin consent** (if you have admin rights; otherwise users will consent on first sign-in)

### Step 3: Add redirect URIs

1. **Authentication** → **Add a platform**

#### Mobile (Android & iOS)

- Platform: **Mobile and desktop applications**
- Add custom redirect URIs:
  - `msauth.com.cloudvault.app://auth`

#### Desktop (Windows / macOS / Linux)

- Under the same **Mobile and desktop applications** section, also add:
  - `https://login.microsoftonline.com/common/oauth2/nativeclient`

2. Under **Advanced settings** → enable **Allow public client flows** → **Yes** → **Save**

### Step 4: Update oauth_constants.dart

```dart
class MicrosoftOAuthConstants {
  static const String clientId = 'YOUR_AZURE_APP_CLIENT_ID_GUID';
  ...
}
```

The `authority` and scopes are already correctly set in the constants file.

---

---

## Part 3 — Apple iCloud (Apple Developer Portal)

> **Platform support:** Sign in with Apple works on iOS and macOS only. iCloud Drive file scanning is iOS/macOS only (no public REST API). Attempting to add an iCloud account on Windows, Android, or Linux will show a clear error.

### Step 1: Apple Developer account

You need a paid Apple Developer Program membership ($99/yr) to enable Sign in with Apple on real devices and to distribute through the App Store. A free account lets you test on a simulator only.

### Step 2: Create / configure an App ID

1. Go to [developer.apple.com](https://developer.apple.com) → **Account** → **Certificates, IDs & Profiles** → **Identifiers**
2. Click **+** → select **App IDs** → type **App** → **Continue**
3. Description: `CloudVault Analyzer`
4. Bundle ID (Explicit): `com.cloudvault.app`
5. In the **Capabilities** list, tick **Sign In with Apple** → **Continue** → **Register**

### Step 3: Enable Sign In with Apple in Xcode (iOS)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target → **Signing & Capabilities** tab
3. Click **+ Capability** → search for and add **Sign In with Apple**
4. This adds the `com.apple.developer.sign-in-with-apple` entitlement automatically

### Step 4: Enable Sign In with Apple in Xcode (macOS)

1. Open `macos/Runner.xcworkspace` in Xcode
2. Select the **Runner** target → **Signing & Capabilities** tab
3. Click **+ Capability** → add **Sign In with Apple**
4. Also ensure **Outgoing Connections (Client)** is checked under **App Sandbox**

### Step 5: Register an iCloud Container (for future file scanning)

> Required only when native iCloud Drive scanning is implemented. Skip now unless you need it.

1. **Identifiers** → **+** → select **iCloud Containers** → **Continue**
2. Description: `CloudVault iCloud`
3. Identifier: `iCloud.com.cloudvault.app` (must match `AppleOAuthConstants.iCloudContainerId`)
4. **Register**
5. In your App ID → **Edit** → **iCloud** → enable → select the container just created

### Step 6: Update oauth_constants.dart

No client ID or secret is required for Sign in with Apple — the native SDK manages the JWT exchange internally. The only value to confirm in `oauth_constants.dart` is:

```dart
class AppleOAuthConstants {
  static const String bundleId = 'com.cloudvault.app';          // must match Xcode bundle ID
  static const String iCloudContainerId = 'iCloud.com.cloudvault.app'; // for future scanning
}
```

### Step 7: iOS Info.plist — no extra changes needed

The `sign_in_with_apple` package handles the `ASWebAuthenticationSession` flow automatically. No custom URL scheme is required for Sign in with Apple on iOS/macOS.

---

## Verification Checklist

| Item | Google | Microsoft | Apple |
|------|--------|-----------|-------|
| API / capability enabled | Drive API ✓ | Graph API via permissions ✓ | Sign In with Apple capability ✓ |
| Consent screen / registration | ✓ | N/A | App ID registered ✓ |
| Client ID in `oauth_constants.dart` | Android + iOS + Desktop | Single client ID | Bundle ID only (no secret) |
| Redirect URI in AndroidManifest.xml | `com.cloudvault.app:/oauth2redirect` | `msauth.com.cloudvault.app://auth` | N/A |
| URL scheme in iOS Info.plist | reversed client ID + `com.cloudvault.app` | `msauth.com.cloudvault.app` | N/A |
| Xcode capability added | N/A | N/A | Sign In with Apple (iOS + macOS) |
| Test user added (Google dev mode) | ✓ | N/A | N/A |
| Public client flow enabled | N/A | ✓ | N/A |

---

## Keeping Credentials Safe

- **Never** commit real credentials to git. The constants file is tracked; use one of these patterns:
  - Create `lib/core/constants/secrets.dart` (listed in `.gitignore`) and import from there.
  - Use `--dart-define` build flags:
    ```bash
    flutter run --dart-define=GOOGLE_CLIENT_ID_ANDROID=xxxx
    ```
  - Store in CI/CD environment variables and inject at build time.
