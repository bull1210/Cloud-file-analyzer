# iCloud / Sign in with Apple — iOS Simulator Testing Guide

This guide covers every step to test iCloud authentication on the iOS Simulator from a Windows development machine using a remote Mac (or directly on a Mac). It also documents current limitations clearly so you know exactly what is testable right now vs. what requires future work.

---

## What is and is not testable on the simulator

| Feature | Simulator | Real device | Notes |
|---|---|---|---|
| Sign in with Apple (auth sheet) | Yes — iOS 14+ | Yes | Core of this guide |
| Identity token parsing (email, name) | Yes | Yes | First sign-in only |
| Account saved to local DB | Yes | Yes | Full flow |
| iCloud Drive file scanning | **No** | **No** | No public REST API exists yet |
| Token refresh | **No** | **No** | Apple tokens expire in 10 min, cannot be refreshed |
| Re-authentication prompt | Yes | Yes | User must sign in again after 10 min |

> The goal of simulator testing is to verify the **Sign in with Apple auth flow** and account creation. File scanning for iCloud is blocked on all platforms until a native NSMetadataQuery integration is built.

---

## Prerequisites

| Requirement | Minimum version | Check command |
|---|---|---|
| Mac (Xcode only runs on macOS) | macOS 13 Ventura+ | `sw_vers` |
| Xcode | 14.0+ | `xcode-select --version` |
| iOS Simulator runtime | iOS 14.0+ | Xcode → Settings → Platforms |
| Flutter SDK | 3.22+ | `flutter --version` |
| Apple Developer account | Free (for simulator) | developer.apple.com |
| CocoaPods | 1.12+ | `pod --version` |

> A **free** Apple Developer account is sufficient for simulator testing. You only need the paid ($99/year) membership to run on a real device or to submit to the App Store.

---

## Step 1 — Fix the bundle ID mismatch (critical)

**The Xcode project currently has a bundle ID mismatch that will prevent Sign in with Apple from working.**

- Xcode project (`project.pbxproj`): `com.cloudvault.cloudvaultAnalyzer`
- Constants and Apple configuration: `com.cloudvault.app`

You must make these identical before proceeding. The recommended value is `com.cloudvault.app` (matches the Apple constants, Microsoft redirect URI, and iCloud container ID). Pick one and align everything.

### 1a — Fix the bundle ID in Xcode

1. On your Mac, open a terminal and navigate to the project:
   ```bash
   cd /path/to/cloud-file-analyzer
   ```
2. Open the iOS workspace (always use `.xcworkspace`, never `.xcodeproj`):
   ```bash
   open ios/Runner.xcworkspace
   ```
3. In Xcode, click the **Runner** project in the file navigator (left sidebar, top item).
4. Select the **Runner** target (not the project, the target below it).
5. Go to the **General** tab.
6. Under **Identity**, change **Bundle Identifier** from `com.cloudvault.cloudvaultAnalyzer` to:
   ```
   com.cloudvault.app
   ```
7. Also select the **RunnerTests** target and update its bundle identifier to:
   ```
   com.cloudvault.app.RunnerTests
   ```

### 1b — Fix the Google iOS redirect URI

Open `lib/core/constants/oauth_constants.dart` and confirm this line matches the bundle ID you chose:

```dart
static const String redirectUriIos = 'com.cloudvault.app:/oauth2redirect';
```

If you chose a different bundle ID, update this string to match.

---

## Step 2 — Register the App ID in Apple Developer Portal

> Skip this step if you already have `com.cloudvault.app` registered with Sign in with Apple enabled.

1. Go to https://developer.apple.com and sign in with your Apple ID.
2. Click **Account** → **Certificates, Identifiers & Profiles**.
3. In the left sidebar click **Identifiers**.
4. Click the **+** button to add a new identifier.
5. Select **App IDs** and click **Continue**.
6. Select **App** and click **Continue**.
7. Fill in:
   - **Description:** `CloudVault Analyzer`
   - **Bundle ID:** Explicit → `com.cloudvault.app`
8. Scroll down the capabilities list to **Sign In with Apple** and check the checkbox next to it.
9. Click **Continue** then **Register**.

The App ID is now registered with the Sign in with Apple entitlement.

> For a **free** account, you can register App IDs but cannot create distribution certificates or provisioning profiles. Simulator testing with automatic signing still works.

---

## Step 3 — Add the Sign in with Apple capability in Xcode

This creates the required `.entitlements` file and adds the `com.apple.developer.applesignin` entitlement automatically.

1. In Xcode, make sure you have the **Runner** workspace open (`ios/Runner.xcworkspace`).
2. Click the **Runner** project in the file navigator.
3. Select the **Runner** target.
4. Click the **Signing & Capabilities** tab.
5. Click **+ Capability** (the `+` button near the top-left of the tab).
6. In the search box type `Sign In with Apple` and double-click it.

You should now see a **Sign In with Apple** section appear in the Signing & Capabilities tab. Xcode automatically creates `ios/Runner/Runner.entitlements` with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
</dict>
</plist>
```

Verify this file was created at `ios/Runner/Runner.entitlements`. If it does not appear in Xcode's file navigator, right-click the `Runner` folder → **Add Files to "Runner"** and select the file.

---

## Step 4 — Configure code signing in Xcode

### For simulator testing (recommended — no provisioning profile needed)

1. In the **Signing & Capabilities** tab, under **Signing**, check **Automatically manage signing**.
2. Set **Team** to your Apple Developer account (free or paid).
   - If no team appears, click **Add an Account** and sign in with your Apple ID.
3. For **Debug** configuration the signing identity will be set automatically.

> On the simulator, Sign in with Apple does not require a provisioning profile. Automatic signing with any team is sufficient.

### What correct signing looks like

After setting the team correctly you should see:

```
Signing Certificate   Apple Development: your@email.com (XXXXXXXXXX)
Provisioning Profile  Xcode Managed Profile
```

If you see a red error like `"Sign in with Apple" requires a paid Apple Developer account`, this means the capability was added but the entitlement is not yet associated with your App ID. Re-check Step 2 to confirm Sign in with Apple is enabled for `com.cloudvault.app`.

---

## Step 5 — Set up the iOS Simulator

Sign in with Apple on the simulator **requires** an Apple ID to be signed in to the simulator's Settings app. Without this, the system sheet will not appear.

### 5a — Download a simulator runtime

1. In Xcode go to **Settings → Platforms**.
2. Click the **+** button at the bottom.
3. Download **iOS 17** (or any iOS 14+ runtime — iOS 17 is recommended).
4. Wait for the download to complete.

### 5b — Create a simulator device

1. Open the Simulator app (from Xcode menu: **Xcode → Open Developer Tool → Simulator**).
2. From the Simulator menu: **File → New Simulator**.
3. Choose:
   - **Name:** `iPhone 15 iOS 17` (or any descriptive name)
   - **Device Type:** iPhone 15 (or iPhone 14 / 15 Pro)
   - **OS Version:** iOS 17.x
4. Click **Create**.

### 5c — Sign into Apple ID in the simulator

This is the most commonly missed step.

1. Boot the simulator: in Xcode, select the simulator device from the scheme menu (top bar) and click **Run**, or from Xcode menu **Product → Run**.
2. In the booted simulator, open the **Settings** app (grey gear icon).
3. Tap the top banner: **Sign in to your iPhone**.
4. Enter your Apple ID email and password.
   - Use the same Apple ID registered in Apple Developer Portal.
   - If you have two-factor authentication (you should), the verification code will be sent to your real device or Mac.
5. Tap **Sign In** and wait for the sync to complete (30–60 seconds).
6. You should now see your name at the top of Settings.

> If you skip this step and try Sign in with Apple, the system sheet appears momentarily then dismisses with no result, and the app receives a cancellation error.

---

## Step 6 — Install Flutter dependencies

On your Mac, in the project root:

```bash
# Install Dart/Flutter packages
flutter pub get

# Install CocoaPods dependencies (required after pub get on iOS)
cd ios
pod install
cd ..
```

If `pod install` fails with a version conflict, try:

```bash
cd ios
pod repo update
pod install
cd ..
```

---

## Step 7 — Run on the simulator

List available simulators to find the device ID:

```bash
xcrun simctl list devices | grep "iPhone"
```

Example output:
```
iPhone 15 (A1B2C3D4-...) (Booted)
```

Run the Flutter app:

```bash
flutter run -d "iPhone 15"
# or use the device ID directly:
flutter run -d A1B2C3D4-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

Alternatively, from Xcode: select the simulator in the scheme picker and press **Cmd+R**.

---

## Step 8 — Test the Sign in with Apple flow

### First sign-in (full flow)

1. In the app, tap **Add Account**.
2. Tap **Continue with iCloud (iOS / macOS)**.
3. The system **Sign in with Apple** sheet slides up from the bottom of the screen. It shows:
   - Your name (from your Apple ID)
   - Your email with two options:
     - **Share My Email** — sends your real Apple ID email to the app
     - **Hide My Email** — sends a randomised relay address (`xxxx@privaterelay.appleid.com`)
4. Tap **Continue**.
5. Biometric / passcode prompt (in the simulator, you can set a passcode via Settings → Face ID & Passcode, or skip authentication by clicking the "Home" button shortcut).
6. The app receives the credential, parses the identity token, and saves the account to the local database.
7. The account should now appear in the Cloud Storage screen as `iCloud – your@email.com`.

### Subsequent sign-ins (re-auth)

On re-authentication Apple does **not** send the email or name again — only the `userIdentifier` (a stable opaque string). The app falls back to whatever was stored from the first sign-in. This is expected and documented behaviour.

### Expected log output

After a successful sign-in, search `Documents/cloudvault_debug.log` for these lines:

```
[AppleAuth] authorize() — platform=iOS  isApplePlatform=true
[AppleAuth] getAppleIDCredential() called
[AppleAuth] credential received — userIdentifier present=true  identityToken present=true  email=your@email.com  fullName=Your Name
[AppleAuth] authorize() — success
[AuthRepo] loginApple() — accountId=xxxxxxxx  email=your@email.com  displayName=your@email.com
```

---

## Step 9 — Verify account saved correctly

After the auth sheet closes:

1. The account card should appear in the **Cloud Storage** screen.
2. The card shows `iCloud – your@email.com` with a **Not Synced** badge.
3. Tapping **Sync** will immediately show an error:
   ```
   iCloud Drive scanning is not yet available on this platform.
   ```
   This is expected — auth works, scanning is blocked pending a native NSMetadataQuery implementation.

---

## Troubleshooting

### "Sign in with Apple is only available on iOS and macOS"

This error fires on Android/Windows. The check is in `AppleAuthService._isApplePlatform`. Make sure you are running on the iOS Simulator, not Chrome or Android.

### System sheet appears then immediately dismisses with no error

The simulator does not have an Apple ID signed in. Repeat Step 5c.

### "Sign in with Apple capability" Xcode error (red warning)

The `.entitlements` file is missing or the capability was not added correctly. Repeat Step 3. Verify `ios/Runner/Runner.entitlements` exists and is referenced in the Xcode project build settings under `CODE_SIGN_ENTITLEMENTS`.

### Build error: `No such module 'AuthenticationServices'`

This means the iOS deployment target is below 13.0. The current project sets `IPHONEOS_DEPLOYMENT_TARGET = 13.0` which is correct. If you see this error, clean the build folder (**Cmd+Shift+K**) and rebuild.

### `pod install` error: `sign_in_with_apple requires iOS 13.0`

Run:
```bash
cd ios
pod deintegrate
pod install
```

### Bundle ID mismatch error at runtime

Xcode shows: `The bundle ID "com.cloudvault.cloudvaultAnalyzer" does not match the bundle ID registered with Apple.`  
Fix: repeat Step 1 to align the Xcode bundle ID with `com.cloudvault.app`.

### "No team" — cannot sign

You need to be signed into Xcode with your Apple ID:  
**Xcode → Settings → Accounts → + → Sign in with Apple ID**

### Simulator not listed in `flutter devices`

The simulator must be **booted** (running) before Flutter can see it. Start it from Xcode or:
```bash
open -a Simulator
```

### `flutter run` fails with CocoaPods error

```bash
cd ios && pod install && cd ..
flutter clean
flutter run -d "iPhone 15"
```

---

## Token expiry behaviour during testing

Apple identity tokens are valid for **10 minutes**. When the token expires:

1. The next API call that checks the token will fail.
2. The app shows a **Session expired** error (mapped from the 401 response).
3. The user must tap **Re-auth** and sign in again.

Since `AppleAuthService.refreshAccessToken()` always returns `null` (Apple provides no refresh mechanism), re-authentication is the only recovery path. This is intentional and documented in `CLAUDE.md`.

---

## Files changed or verified by this setup

| File | Change required |
|---|---|
| `ios/Runner.xcworkspace` | Open in Xcode; do not open `.xcodeproj` directly |
| Xcode → Runner target → General → Bundle Identifier | Change to `com.cloudvault.app` |
| Xcode → Runner target → Signing & Capabilities | Add **Sign In with Apple** capability |
| `ios/Runner/Runner.entitlements` | Auto-created by Xcode when capability is added |
| `lib/core/constants/oauth_constants.dart` | No change needed — `bundleId = 'com.cloudvault.app'` is already correct |
| `ios/Runner/Info.plist` | No change needed for auth — `com.cloudvault.app` scheme already registered |

---

## What needs to be built before full iCloud scanning works

Sign in with Apple is functioning. The remaining gap is scanning:

1. **Native iOS/macOS file enumeration** — iCloud Drive files must be listed using `NSMetadataQuery` (a native iOS/macOS API) inside a Flutter platform channel. No Dart-only solution exists.
2. **iCloud container entitlement** — Add `com.apple.developer.icloud-container-identifiers` = `iCloud.com.cloudvault.app` to the entitlements file.
3. **iCloud Documents capability** — Add **iCloud** capability in Xcode with the container ID `iCloud.com.cloudvault.app`.
4. **Platform channel implementation** — A Swift `FlutterMethodChannel` handler that calls `NSMetadataQuery` for the iCloud container and returns file metadata to Dart.

These are tracked as future work and do not block auth testing.
