# CloudVault Analyzer — OAuth & Cloud Provider Setup Guide

This document covers every step required to register and configure each cloud provider so that CloudVault Analyzer can authenticate and scan file metadata.  
All credential values go into **`lib/core/constants/oauth_constants.dart`** unless otherwise noted.

---

## Table of Contents

1. [Google Drive](#1-google-drive)
2. [Microsoft OneDrive](#2-microsoft-onedrive)
3. [Dropbox](#3-dropbox)
4. [TeraBox](#4-terabox)
5. [MEGA](#5-mega)
6. [iCloud Drive](#6-icloud-drive)
7. [Android Manifest — full reference](#7-android-manifest-full-reference)
8. [iOS Info.plist — full reference](#8-ios-infoplist-full-reference)
9. [Credential status at a glance](#9-credential-status-at-a-glance)

---

## 1. Google Drive

**Portal:** https://console.cloud.google.com  
**Auth mechanism:** OAuth 2.0 PKCE (desktop) · Google Sign-In / Play Services (Android/iOS)

### 1.1 Create a Google Cloud project

1. Open the Cloud Console and click **Select a project → New Project**.
2. Name it (e.g. `CloudVault`) and click **Create**.
3. From the left sidebar go to **APIs & Services → Library**.
4. Search for **Google Drive API** and click **Enable**.

### 1.2 Configure the OAuth consent screen

1. Go to **APIs & Services → OAuth consent screen**.
2. Choose **External** (works for any Google account) and click **Create**.
3. Fill in:
   - **App name:** `CloudVault Analyzer`
   - **User support email:** your email
   - **Developer contact:** your email
4. Click **Save and Continue**.
5. On the **Scopes** step click **Add or Remove Scopes** and add:
   - `openid`
   - `email`
   - `profile`
   - `https://www.googleapis.com/auth/drive` ← required for full metadata + trash
6. Click **Save and Continue** through the remaining steps.
7. On the **Test users** step add your own Google account so you can test before the app is published.

> **Note:** The `drive` scope is a sensitive scope. Google will show a warning screen during login until the app is verified. For personal/team use this is fine; for production publish, submit for OAuth verification.

### 1.3 Create OAuth 2.0 client IDs

You need **three** separate client IDs: Android, iOS, and Desktop.

#### Android client

1. Go to **APIs & Services → Credentials → Create Credentials → OAuth client ID**.
2. Application type: **Android**.
3. **Package name:** `com.cloudvault.app`
4. **SHA-1 certificate fingerprint** — run this command and copy the `SHA1:` line:
   ```
   # Debug keystore (development)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

   # Release keystore (production)
   keytool -list -v -keystore <path-to-your-release.keystore> -alias <alias>
   ```
5. Click **Create**.
6. Copy the **Client ID** (format: `NUMBERS-HASH.apps.googleusercontent.com`).
7. Paste it into `oauth_constants.dart`:
   ```dart
   static const String clientIdAndroid = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
   ```
8. Derive the redirect URI (done automatically in code):
   ```
   com.googleusercontent.apps.NUMBERS-HASH:/oauth2redirect
   ```
   No redirect URI needs to be entered manually — Google derives it from the client ID.

#### iOS client

1. Go to **Credentials → Create Credentials → OAuth client ID**.
2. Application type: **iOS**.
3. **Bundle ID:** `com.cloudvault.app`
4. Click **Create**.
5. Copy the **Client ID** (same format as Android).
6. Paste into `oauth_constants.dart`:
   ```dart
   static const String clientIdIos = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';
   ```
7. Derive the **reversed client ID** by reversing the ID prefix:
   - Client ID: `123456789-abcdef.apps.googleusercontent.com`
   - Reversed: `com.googleusercontent.apps.123456789-abcdef`
8. Open `ios/Runner/Info.plist` and replace the placeholder:
   ```xml
   <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
   ```
   with your actual reversed client ID, e.g.:
   ```xml
   <string>com.googleusercontent.apps.123456789-abcdef</string>
   ```

#### Desktop client (Windows / Linux / macOS)

1. Go to **Credentials → Create Credentials → OAuth client ID**.
2. Application type: **Desktop app**.
3. Name it `CloudVault Desktop`.
4. Click **Create**.
5. Copy both the **Client ID** and **Client Secret**.
6. Paste into `oauth_constants.dart`:
   ```dart
   static const String clientIdDesktop     = 'YOUR_DESKTOP_CLIENT_ID.apps.googleusercontent.com';
   static const String clientSecretDesktop = 'YOUR_CLIENT_SECRET';
   ```

> **Security warning:** Do NOT commit the desktop client secret to a public repository.  
> Move it to a gitignored `lib/core/constants/secrets.dart` file before pushing publicly.

### 1.4 Android manifest — Google

The Android manifest already contains the Google intent filter (derived from `clientIdAndroid`).  
If you change the Android client ID, update the scheme in `AndroidManifest.xml`:

```xml
<data android:scheme="com.googleusercontent.apps.NUMBERS-HASH"/>
```

Replace `NUMBERS-HASH` with the prefix of your new Android client ID.

### 1.5 Verify

Run the app on Android, tap **Add Account → Google Drive**, and confirm the Google sign-in picker appears. On Windows desktop, a browser window should open pointing to `accounts.google.com`.

---

## 2. Microsoft OneDrive

**Portal:** https://portal.azure.com  
**Auth mechanism:** OAuth 2.0 PKCE (all platforms) via `flutter_web_auth_2`

> **Current status:** The client ID `ea140dbc-6f35-4ebb-afc8-24ea54e763d7` is already registered and committed. Follow the steps below only if you need to rotate or create a new app registration.

### 2.1 Create an App Registration

1. Sign in to the Azure Portal.
2. Search for **Azure Active Directory** (or **Microsoft Entra ID** in newer portals).
3. Go to **App registrations → New registration**.
4. Fill in:
   - **Name:** `CloudVault Analyzer`
   - **Supported account types:** `Accounts in any organizational directory and personal Microsoft accounts` (the "common" tenant)
   - **Redirect URI:** leave blank for now
5. Click **Register**.
6. On the **Overview** page copy the **Application (client) ID**.
7. Paste it into `oauth_constants.dart`:
   ```dart
   static const String clientId = 'YOUR_APPLICATION_CLIENT_ID';
   ```

> Microsoft PKCE public clients do not use a client secret — do not create one.

### 2.2 Add redirect URIs

1. From your app registration go to **Authentication → Add a platform → Mobile and desktop applications**.
2. Add **both** of the following URIs:
   ```
   http://localhost
   msauth.com.cloudvault.app://auth
   ```
3. Under **Advanced settings** set **Allow public client flows** to **Yes**.
4. Click **Save**.

### 2.3 Add API permissions

1. Go to **API permissions → Add a permission → Microsoft Graph → Delegated permissions**.
2. Search for and select:
   - `openid`
   - `offline_access`
   - `Files.ReadWrite`
   - `User.Read`
3. Click **Add permissions**.
4. Click **Grant admin consent** if you are the tenant admin (optional for personal accounts — users will consent at login).

### 2.4 Android manifest — Microsoft

The `CallbackActivity` intent filter for `msauth.com.cloudvault.app` is already present. Verify it matches:

```xml
<intent-filter android:label="microsoft_auth_redirect">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data
        android:scheme="msauth.com.cloudvault.app"
        android:host="auth"/>
</intent-filter>
```

> **Known Android bug:** The Chrome Custom Tab does not close after authentication on Android.  
> Fix: change `android:launchMode` of `CallbackActivity` from `singleTop` to `singleTask` and remove `android:taskAffinity=""`. See [Android Manifest full reference](#7-android-manifest-full-reference).

### 2.5 iOS plist — Microsoft

`ios/Runner/Info.plist` already registers the `msauth.com.cloudvault.app` URL scheme:

```xml
<string>msauth.com.cloudvault.app</string>
```

No changes required unless you rename the bundle ID.

### 2.6 Verify

Run on Android or Windows, tap **Add Account → Microsoft OneDrive**, and confirm the Microsoft login page opens. After signing in, the account should appear in the list.

---

## 3. Dropbox

**Portal:** https://www.dropbox.com/developers/apps  
**Auth mechanism:** OAuth 2.0 PKCE + offline access via `flutter_web_auth_2`

### 3.1 Create a Dropbox app

1. Go to the Dropbox App Console.
2. Click **Create app**.
3. Choose:
   - **API:** `Scoped access`
   - **Access type:** `Full Dropbox` (or `App folder` for restricted access)
   - **Name:** `CloudVault Analyzer`
4. Click **Create app**.

### 3.2 Configure permissions

1. On the app page go to the **Permissions** tab.
2. Enable:
   - `files.metadata.read` — required for listing files
   - `account_info.read` — required for the user profile (email, name)
3. Click **Submit**.

### 3.3 Configure redirect URIs

1. Go to the **Settings** tab.
2. Under **OAuth 2 → Redirect URIs** add:
   ```
   http://localhost
   cloudvaultapp://oauth/dropbox
   ```
3. Set **Allow implicit grant:** `Disallow` (we use PKCE/code flow).

### 3.4 Copy the App Key

1. On the **Settings** tab copy the **App key** (not the App secret — PKCE doesn't need it).
2. Paste into `oauth_constants.dart`:
   ```dart
   static const String appKey = 'YOUR_DROPBOX_APP_KEY';
   ```

### 3.5 Android manifest — Dropbox

The `cloudvaultapp` custom scheme is **not yet present** in `AndroidManifest.xml`.  
Add the following intent filter inside the `CallbackActivity` block:

```xml
<!-- Dropbox + TeraBox: shared custom scheme, different paths -->
<intent-filter android:label="cloudvaultapp_redirect">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="cloudvaultapp"/>
</intent-filter>
```

> This single filter handles both Dropbox (`cloudvaultapp://oauth/dropbox`) and TeraBox (`cloudvaultapp://oauth/terabox`) because `flutter_web_auth_2` matches on scheme only.

### 3.6 iOS plist — Dropbox

Add `cloudvaultapp` to the URL schemes in `ios/Runner/Info.plist` inside the existing `CFBundleURLSchemes` array:

```xml
<string>cloudvaultapp</string>
```

### 3.7 Verify

Run on Android or Windows, tap **Add Account → Dropbox**, and confirm the Dropbox login page opens in a browser. After authorising, the account should appear.

---

## 4. TeraBox

**Portal:** https://developer.terabox.com  
**Auth mechanism:** OAuth 2.0 PKCE via `flutter_web_auth_2`

### 4.1 Register a TeraBox developer app

1. Sign in to the TeraBox developer portal with a TeraBox account.
2. Go to **My Apps → Create App**.
3. Fill in the app name and description.
4. Set the **Redirect URI** to:
   ```
   http://localhost
   cloudvaultapp://oauth/terabox
   ```
5. Submit the app for review (TeraBox may require manual approval).

### 4.2 Copy credentials

Once approved, copy the **App ID** and **App Secret** from the app detail page.  
Paste into `oauth_constants.dart`:

```dart
static const String clientId     = 'YOUR_TERABOX_APP_ID';
static const String clientSecret = 'YOUR_TERABOX_APP_SECRET';
```

### 4.3 Permissions / scopes

TeraBox uses fixed scopes defined in the auth request:
- `basic` — user profile
- `netdisk` — file metadata access

No additional configuration in the portal is needed for these scopes.

### 4.4 Android manifest — TeraBox

TeraBox shares the `cloudvaultapp` scheme with Dropbox.  
Adding the intent filter described in [section 3.5](#35-android-manifest--dropbox) covers both providers — no additional entry is needed.

### 4.5 iOS plist — TeraBox

Adding `cloudvaultapp` to `CFBundleURLSchemes` as described in [section 3.6](#36-ios-plist--dropbox) covers both Dropbox and TeraBox.

### 4.6 Verify

Run on Windows, tap **Add Account → TeraBox**, and confirm the TeraBox login page opens. On mobile, verify the browser redirects back to the app after authorisation.

---

## 5. MEGA

**No developer portal required.**  
MEGA does not provide an OAuth API. Authentication uses your MEGA account email and password directly.

### 5.1 How it works

1. The user enters their MEGA email and password in the in-app form.
2. Credentials are stored in the device keychain/keystore via `flutter_secure_storage`.
3. File listing uses MEGA's REST API with those stored credentials as a session token.

### 5.2 Configuration

No values need to be added to `oauth_constants.dart`. There is a dedicated `MegaOAuthConstants` class but it contains no fields — it is a placeholder for future API keys if MEGA introduces OAuth.

### 5.3 Limitation

Full file scanning requires the `mega_sdk` package (or a compatible implementation) for MEGA's proprietary AES/RSA key derivation. The current implementation stores credentials but scanning is not yet fully implemented.

---

## 6. iCloud Drive

**Platform restriction:** iOS and macOS only. Not available on Windows, Android, or Linux.

### 6.1 Prerequisites

- An active **Apple Developer Program** membership (paid, $99/year).
- Xcode installed on a Mac.
- Bundle ID `com.cloudvault.app` registered in Apple Developer Portal.

### 6.2 Apple Developer Portal setup

1. Go to https://developer.apple.com → **Certificates, Identifiers & Profiles**.
2. Select **Identifiers → App IDs**.
3. Find or create `com.cloudvault.app`.
4. Enable the capability **Sign In with Apple**.
5. Click **Save**.

### 6.3 Xcode capability setup

**iOS:**
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Click **+ Capability** and add **Sign In with Apple**.

**macOS:**
1. Open `macos/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Click **+ Capability** and add **Sign In with Apple**.

### 6.4 Code configuration

No client ID or secret is needed in `oauth_constants.dart` — the native `sign_in_with_apple` package handles the Apple JWT exchange. The only constant is:

```dart
static const String bundleId = 'com.cloudvault.app';
```

This must match the bundle identifier in Xcode exactly.

### 6.5 Limitations

- Apple identity tokens expire in **10 minutes** and cannot be refreshed programmatically. Users must re-authenticate manually when prompted.
- Apple sends `email` and `name` only on the **first** sign-in. Subsequent sign-ins return only the `sub` (user identifier). The app persists whatever is available from the first sign-in.
- iCloud Drive has **no public REST API** for third-party apps. The scan feature for iCloud is blocked pending a native iOS/macOS implementation.

---

## 7. Android Manifest — Full Reference

The complete `android/app/src/main/AndroidManifest.xml` `CallbackActivity` block should look like this after all providers are configured:

```xml
<!-- OAuth callback handler (flutter_web_auth_2) -->
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:launchMode="singleTask">
    <!--
      singleTask (not singleTop) is required so that CallbackActivity is always
      rooted in the app's own task. With singleTop + taskAffinity="", the activity
      can end up in a different task, causing the Chrome Custom Tab to stay visible
      after authentication completes even though the Dart Future has resolved.
    -->

    <!-- Google: reversed client ID scheme -->
    <intent-filter android:label="google_auth_redirect">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="com.googleusercontent.apps.191669135013-dou7mfpa1ld7tqc0goj9m936n5tot661"/>
    </intent-filter>

    <!-- Microsoft: msauth scheme -->
    <intent-filter android:label="microsoft_auth_redirect">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data
            android:scheme="msauth.com.cloudvault.app"
            android:host="auth"/>
    </intent-filter>

    <!-- Dropbox + TeraBox: shared custom scheme, flutter_web_auth_2 matches on scheme only -->
    <intent-filter android:label="cloudvaultapp_redirect">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="cloudvaultapp"/>
    </intent-filter>

</activity>
```

**Changes from the current manifest:**
| What changed | Why |
|---|---|
| `android:launchMode="singleTask"` (was `singleTop`) | Keeps `CallbackActivity` in the app task so the CCT closes after auth |
| Removed `android:taskAffinity=""` | Removes task-affinity override that was misrouting the activity |
| Added `cloudvaultapp` intent filter | Required for Dropbox and TeraBox callbacks on Android (was missing) |

---

## 8. iOS Info.plist — Full Reference

The complete `CFBundleURLSchemes` array in `ios/Runner/Info.plist` should be:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Google iOS reversed client ID — replace with your actual iOS client ID prefix -->
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID_PREFIX</string>

            <!-- App's own scheme — used by Microsoft (mobile redirect) and general deep links -->
            <string>com.cloudvault.app</string>

            <!-- Microsoft MSAL scheme -->
            <string>msauth.com.cloudvault.app</string>

            <!-- Dropbox and TeraBox custom scheme -->
            <string>cloudvaultapp</string>
        </array>
    </dict>
</array>
```

**Changes from the current plist:**
| What changed | Why |
|---|---|
| Added `cloudvaultapp` | Required for Dropbox and TeraBox OAuth callbacks on iOS (was missing) |

---

## 9. Credential Status at a Glance

| Provider | Field | File | Status |
|---|---|---|---|
| Google | `clientIdAndroid` | `oauth_constants.dart` | Filled — verify SHA-1 matches your keystore |
| Google | `clientIdIos` | `oauth_constants.dart` | **Placeholder** — fill from Google Console |
| Google | `clientIdDesktop` | `oauth_constants.dart` | Filled — **rotate before publishing publicly** |
| Google | `clientSecretDesktop` | `oauth_constants.dart` | Filled — **move to gitignored secrets file** |
| Microsoft | `clientId` | `oauth_constants.dart` | Filled — working |
| Dropbox | `appKey` | `oauth_constants.dart` | **Placeholder** — follow Section 3 |
| TeraBox | `clientId` | `oauth_constants.dart` | **Placeholder** — follow Section 4 |
| TeraBox | `clientSecret` | `oauth_constants.dart` | **Placeholder** — follow Section 4 |
| MEGA | — | — | No config needed |
| iCloud | — | — | iOS/macOS only; Xcode capability required |

**Android manifest gaps (fix before testing on Android):**
- `CallbackActivity` uses `singleTop` → must be `singleTask` (Microsoft CCT stays open bug)
- `cloudvaultapp` scheme intent filter missing → Dropbox and TeraBox callbacks will silently fail

**iOS plist gaps (fix before testing on iOS):**
- `cloudvaultapp` scheme missing → Dropbox and TeraBox callbacks will silently fail
- Google iOS reversed client ID is still a placeholder
