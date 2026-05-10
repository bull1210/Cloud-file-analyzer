# Deployment Guide

Step-by-step instructions for building and installing CloudVault Analyzer on Android, iPhone, Windows, macOS, and Linux.

---

## Prerequisites (All Platforms)

1. Install **Flutter SDK** ≥ 3.16: https://docs.flutter.dev/get-started/install
2. Verify installation:
   ```bash
   flutter doctor
   ```
   Resolve all `[!]` issues before continuing.
3. Install dependencies and generate code:
   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Configure OAuth credentials (see [SETUP.md](SETUP.md)).

---

## Android

### Requirements

- Android Studio ≥ Hedgehog (or command-line tools)
- Android SDK API 21+
- A physical device with **Developer options → USB Debugging** enabled, OR an Android emulator

### Run in debug mode (quickest)

```bash
# List connected devices
flutter devices

# Run on the connected Android device
flutter run -d <device-id>
```

### Build a release APK (sideload on any Android phone)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

**Install on device over USB:**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Or transfer the APK file** to your phone via cable/email/cloud, then open it and tap **Install** (enable "Install from unknown sources" in Android settings first).

### Build an AAB (for Google Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Signing for release

1. Generate a keystore (one-time):
   ```bash
   keytool -genkey -v \
     -keystore ~/cloudvault-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias cloudvault
   ```

2. Create `android/key.properties` (this file is in `.gitignore`):
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=cloudvault
   storeFile=<absolute-path-to>/cloudvault-release.jks
   ```

3. Edit `android/app/build.gradle` to reference `key.properties` (see Flutter docs: https://docs.flutter.dev/deployment/android).

### Android Platform Files Setup

When you first run `flutter create .` (or if platform folders are missing), add Android support:

```bash
flutter create --platforms=android .
```

Then in `android/app/src/main/AndroidManifest.xml` add the OAuth redirect activity and internet permission — see [SETUP.md](SETUP.md#step-6-configure-android-redirect-uri).

Also set the correct application ID in `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        applicationId "com.cloudvault.app"
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

---

## iPhone / iOS

### Requirements

- **macOS computer** (iOS builds require Xcode on macOS)
- Xcode ≥ 15
- Apple Developer account (free account works for device testing; paid ($99/yr) required for App Store / TestFlight)
- CocoaPods: `sudo gem install cocoapods`

### Add iOS support (first time)

```bash
flutter create --platforms=ios .
cd ios && pod install && cd ..
```

### Set Bundle ID

In Xcode: open `ios/Runner.xcworkspace` → select **Runner** target → **Signing & Capabilities** → set Bundle Identifier to `com.cloudvault.app`.

Add the OAuth URL scheme in `ios/Runner/Info.plist` — see [SETUP.md](SETUP.md#step-7-configure-ios-url-scheme).

### Enable iCloud / Sign In with Apple capabilities (required for iCloud accounts)

In Xcode → Runner target → **Signing & Capabilities**:

1. **+ Capability** → add **Sign In with Apple**
2. **+ Capability** → add **iCloud** → tick **CloudKit** and select the `iCloud.com.cloudvault.app` container

Your `ios/Runner/Runner.entitlements` should contain:

```xml
<key>com.apple.developer.sign-in-with-apple</key>
<string>enabled</string>
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.cloudvault.app</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudDocuments</string>
</array>
```

### Run on a connected iPhone (debug)

1. Connect iPhone via USB and trust the Mac.
2. In Xcode, select your device as target, then:
   ```bash
   flutter run -d <device-id>
   ```
   Or press ▶ in Xcode.

### Build for device testing (no App Store)

```bash
flutter build ios --release --no-codesign
```

Then in Xcode: **Product → Archive → Distribute App → Development**.

### Build IPA for distribution (TestFlight / App Store)

1. In Xcode: **Product → Archive**
2. Click **Distribute App**
3. Choose **TestFlight & App Store** (requires paid developer account)
4. Follow the wizard → upload to App Store Connect

### Install on iPhone via AltStore (no developer account, for personal use)

1. Build: `flutter build ios --release --no-codesign`
2. Open `build/ios/archive/Runner.xcarchive` in Xcode
3. Export as Ad Hoc → choose your device
4. Install the `.ipa` via AltStore (https://altstore.io)

---

## Windows

### Requirements

- Windows 10/11
- Visual Studio 2022 with **Desktop development with C++** workload
- Flutter Windows SDK

### Add Windows support (first time)

```bash
flutter create --platforms=windows .
```

### Run in debug mode

```bash
flutter run -d windows
```

### Build release executable

```bash
flutter build windows --release
```

Output: `build\windows\x64\runner\Release\`

The folder contains `cloudvault_analyzer.exe` and all required DLLs. Copy the entire `Release\` folder to distribute.

### Create an installer (optional)

Use [Inno Setup](https://jrsoftware.org/isinfo.php) or [MSIX packaging](https://docs.flutter.dev/deployment/windows):

```bash
# Package as MSIX (Microsoft Store format)
dart pub global activate msix
dart run msix:create
```

### Windows OAuth Note

On Windows, `flutter_appauth` uses the loopback redirect (`http://127.0.0.1`). No extra system configuration is required — the app opens the browser and catches the response on a local port.

---

## macOS

### Requirements

- macOS 12+
- Xcode ≥ 15
- CocoaPods

### Add macOS support (first time)

```bash
flutter create --platforms=macos .
cd macos && pod install && cd ..
```

Enable network access in `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

### Enable iCloud / Sign In with Apple capabilities (required for iCloud accounts)

In Xcode → Runner target → **Signing & Capabilities**:

1. **+ Capability** → add **Sign In with Apple**
2. **+ Capability** → add **iCloud** → tick **CloudKit** and select `iCloud.com.cloudvault.app`

Add to both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.developer.sign-in-with-apple</key>
<string>enabled</string>
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.cloudvault.app</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudDocuments</string>
</array>
```

### Run in debug mode

```bash
flutter run -d macos
```

### Build release app bundle

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/cloudvault_analyzer.app`

Drag the `.app` bundle to `/Applications` to install.

### Distribute (outside App Store)

```bash
# Code sign for distribution outside App Store
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  build/macos/Build/Products/Release/cloudvault_analyzer.app

# Create DMG
hdiutil create -volname "CloudVault Analyzer" \
  -srcfolder build/macos/Build/Products/Release/cloudvault_analyzer.app \
  -ov -format UDZO CloudVaultAnalyzer.dmg
```

---

## Linux

### Requirements

- Ubuntu 20.04+ / Fedora 37+ / Debian 11+
- Required packages:
  ```bash
  # Ubuntu/Debian
  sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev

  # Fedora
  sudo dnf install clang cmake ninja-build gtk3-devel
  ```

### Add Linux support (first time)

```bash
flutter create --platforms=linux .
```

### Run in debug mode

```bash
flutter run -d linux
```

### Build release binary

```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`

The `bundle/` directory is self-contained. Copy it anywhere and run:
```bash
./cloudvault_analyzer
```

### Create a .deb package (Ubuntu/Debian)

```bash
# Install packaging tool
sudo apt-get install ruby-dev && sudo gem install fpm

# Build the package
fpm -s dir -t deb \
  -n cloudvault-analyzer \
  -v 1.0.0 \
  --prefix /opt/cloudvault \
  build/linux/x64/release/bundle/=.

# Install
sudo dpkg -i cloudvault-analyzer_1.0.0_amd64.deb
```

---

## Environment Summary

| Platform | Build Command | Output |
|----------|--------------|--------|
| Android APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| Android AAB | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |
| iOS | Xcode Archive | `.ipa` via Xcode Organizer |
| Windows | `flutter build windows --release` | `build\windows\x64\runner\Release\` |
| macOS | `flutter build macos --release` | `build/macos/.../cloudvault_analyzer.app` |
| Linux | `flutter build linux --release` | `build/linux/x64/release/bundle/` |

---

## Continuous Integration

Example GitHub Actions workflow (`.github/workflows/build.yml`):

```yaml
name: Build
on: [push, pull_request]

jobs:
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter build windows --release
      - uses: actions/upload-artifact@v4
        with:
          name: windows-build
          path: build\windows\x64\runner\Release\
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `flutter doctor` shows missing tools | Install the listed tools and re-run |
| Android build fails: `SDK not found` | Set `ANDROID_HOME` env var or install via Android Studio |
| iOS: `code signing error` | Set team in Xcode → Runner target → Signing |
| `build_runner` fails | Delete `.dart_tool/` and run again |
| OAuth redirect not working on Android | Check `AndroidManifest.xml` redirect activity and scheme |
| OAuth redirect not working on iOS | Check `Info.plist` URL schemes match your client IDs |
| Windows: `flutter_secure_storage` errors | Ensure app runs with user permissions (not elevated) |
| Linux: `libsecret` errors | Install `libsecret-1-dev` and re-build |
| iCloud sign-in fails on iOS | Ensure "Sign In with Apple" capability is added in Xcode and the bundle ID matches |
| iCloud sign-in fails on macOS | Add capability in Xcode + `com.apple.security.network.client` entitlement |
| "iCloud not available on this platform" | Expected on Windows / Android / Linux — iCloud requires an Apple device |
| `sign_in_with_apple` pod not found | Run `cd ios && pod install` (or `macos`) after `flutter pub get` |
