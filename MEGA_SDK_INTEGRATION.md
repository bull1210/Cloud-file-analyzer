# MEGA SDK Integration Guide

This document explains how to integrate MEGA file listing into CloudVault Analyzer across Windows, Android, and iOS. It covers two approaches — a pure-Dart HTTP API approach (recommended, works on all platforms from one codebase) and the official C++ MEGA SDK approach (per-platform native compilation, required for production-grade encryption support).

---

## Background — Why MEGA is different

Every other provider in this app (Google Drive, OneDrive, Dropbox) uses a standard REST API with Bearer tokens. MEGA is fundamentally different:

- All file metadata (names, sizes, folder structure) is **end-to-end encrypted** on MEGA's servers using AES-128.
- MEGA does not expose a simple REST API with plaintext responses. Every response from `g.api.mega.co.nz` returns encrypted node data.
- Decrypting node metadata requires deriving a **master key** from the user's password, then decrypting per-node keys, then decrypting metadata with those keys.
- There is **no official public SDK for Dart or Flutter**. Integration requires either implementing MEGA's crypto in Dart or compiling the official C++ SDK natively and bridging it via FFI.

---

## Approach comparison

| | Approach A — Dart HTTP API | Approach B — Official C++ SDK |
|---|---|---|
| Platforms | Windows, Android, iOS — same code | Separate native build per platform |
| Complexity | Medium — crypto implementation in Dart | Very high — C++ build toolchain per platform |
| Maintenance | Self-contained | Tracks official SDK releases |
| File content download | Not supported (metadata only) | Fully supported |
| Scanning file metadata | Fully supported | Fully supported |
| Recommended for this app | **Yes** | Only if file download is needed |

**Recommendation:** Use Approach A. The app only reads metadata (names, sizes, dates) — it never downloads file content. All required metadata can be decrypted in pure Dart using the `encrypt` and `pointycastle` packages already transitively available in Flutter.

---

## Approach A — Dart HTTP API (recommended)

### How MEGA's API works

All calls go to:
```
POST https://g.api.mega.co.nz/cs?id=<sequence_number>&ak=<app_key>
Body: JSON array of command objects
```

Each command is an object like `{"a": "us", ...}`. Multiple commands can be batched in one request. The response is a JSON array with one result per command.

### Step A1 — Register a MEGA app key

MEGA requires an `ak` (app key) parameter for API calls to identify the client.

1. Go to https://mega.io/developers and sign in with your MEGA account.
2. Click **Create Application**.
3. Fill in the app name (`CloudVault Analyzer`) and description.
4. Copy the generated **App Key** (a short alphanumeric string like `ZVhB3Tzb`).
5. Add it to `lib/core/constants/oauth_constants.dart`:

```dart
class MegaOAuthConstants {
  MegaOAuthConstants._();
  static const String appKey = 'YOUR_APP_KEY';
}
```

### Step A2 — Add the `encrypt` package

The `encrypt` package wraps `pointycastle` with a clean API for AES operations. Add it to `pubspec.yaml`:

```yaml
dependencies:
  encrypt: ^5.0.3
```

Then run:
```bash
flutter pub get
```

### Step A3 — Implement MEGA password key derivation

MEGA derives a 128-bit master key from the user's password using a proprietary algorithm (not a standard PBKDF). This is the key that decrypts the user's private key, which in turn decrypts every file's node key.

Create `lib/data/remote/mega/mega_crypto.dart`:

```dart
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class MegaCrypto {
  // Derives the 128-bit password key from the raw password string.
  // Algorithm: XOR 16-byte blocks of the UTF-8 password into a key,
  // then run 65536 rounds of AES-128-ECB encryption.
  static Uint8List derivePasswordKey(String password) {
    final passwordBytes = _stringToBytes(password);
    // Expand password bytes to a multiple of 16
    final plen = passwordBytes.length;
    final blocks = (plen + 15) ~/ 16;
    final expanded = Uint8List(blocks * 16);
    for (var i = 0; i < plen; i++) {
      expanded[i] = passwordBytes[i];
    }

    // XOR password blocks into a 16-byte key starting from a known constant
    var key = Uint8List.fromList([
      0x93, 0xC4, 0x67, 0xE3, 0x7D, 0xB0, 0xC7, 0xA4,
      0xD1, 0xBE, 0x3F, 0x81, 0x01, 0x52, 0xCB, 0x56,
    ]);

    for (var i = 0; i < blocks; i++) {
      final block = expanded.sublist(i * 16, i * 16 + 16);
      for (var j = 0; j < 16; j++) {
        key[j] ^= block[j];
      }
    }

    // 65536 rounds of AES-128-ECB encryption
    for (var i = 0; i < 65536; i++) {
      final encrypter = Encrypter(AES(Key(key), mode: AESMode.ecb, padding: null));
      key = Uint8List.fromList(encrypter.encryptBytes(key).bytes);
    }

    return key;
  }

  // Produces the 'uh' (user hash) parameter for the login request.
  // This is an 8-byte hash of the lowercase email, encrypted with the password key.
  static String computeUserHash(String email, Uint8List passwordKey) {
    final emailBytes = _stringToBytes(email.toLowerCase());
    var h32 = Uint8List(4);
    var h33 = Uint8List(4);

    for (var i = 0; i < emailBytes.length; i++) {
      if (i % 2 == 0) {
        h32[i % 4] ^= emailBytes[i];
      } else {
        h33[i % 4] ^= emailBytes[i];
      }
    }

    var block = Uint8List(16);
    block.setRange(0, 4, h32);
    block.setRange(4, 8, h33);

    final encrypter = Encrypter(AES(Key(passwordKey), mode: AESMode.ecb, padding: null));
    for (var i = 0; i < 16384; i++) {
      block = Uint8List.fromList(encrypter.encryptBytes(block).bytes);
    }

    // Take first 4 bytes + bytes 4-8 as the 8-byte hash
    final result = Uint8List(8);
    result.setRange(0, 4, block.sublist(0, 4));
    result.setRange(4, 8, block.sublist(4, 8));
    return _base64UrlEncode(result);
  }

  // Decrypts a node's AES key using the master key.
  static Uint8List decryptNodeKey(Uint8List encryptedKey, Uint8List masterKey) {
    final encrypter = Encrypter(AES(Key(masterKey), mode: AESMode.ecb, padding: null));
    return Uint8List.fromList(encrypter.decryptBytes(Encrypted(encryptedKey)));
  }

  // Decrypts node attributes (name, modification time).
  // Node attributes are AES-128-CBC encrypted with the node key.
  static Map<String, dynamic>? decryptNodeAttributes(
      Uint8List encryptedAttrs, Uint8List nodeKey) {
    try {
      final iv = IV(Uint8List(16)); // zero IV for node attributes
      final encrypter = Encrypter(AES(Key(nodeKey.sublist(0, 16)),
          mode: AESMode.cbc, padding: null));
      final decrypted = encrypter.decryptBytes(Encrypted(encryptedAttrs), iv: iv);

      // Attributes start with "MEGA{" prefix
      final raw = String.fromCharCodes(decrypted);
      final start = raw.indexOf('{');
      if (start < 0) return null;
      final jsonStr = raw.substring(start, raw.lastIndexOf('}') + 1);
      return _parseJson(jsonStr);
    } catch (_) {
      return null;
    }
  }

  static Uint8List _stringToBytes(String s) =>
      Uint8List.fromList(s.codeUnits);

  static String _base64UrlEncode(Uint8List bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final result = StringBuffer();
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result.write(chars[(b0 >> 2) & 0x3F]);
      result.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
      if (i + 1 < bytes.length) result.write(chars[((b1 << 2) | (b2 >> 6)) & 0x3F]);
      if (i + 2 < bytes.length) result.write(chars[b2 & 0x3F]);
    }
    return result.toString();
  }

  static Map<String, dynamic> _parseJson(String s) {
    // Minimal JSON parse — real implementation should use dart:convert
    import 'dart:convert';
    return jsonDecode(s) as Map<String, dynamic>;
  }
}
```

> **Note:** The `import 'dart:convert'` inside the method above is a placeholder to show where JSON parsing belongs — move it to the top of the file.

### Step A4 — Implement MegaAuthService with real API calls

Replace the stub in `lib/data/remote/mega/mega_auth_service.dart`:

```dart
// Step 1: login — POST [{"a":"us","user":email,"uh":userHash}]
// Response: {"k": encrypted_master_key, "privk": encrypted_private_key,
//            "csid": encrypted_session_id, "u": user_id}

// Step 2: decrypt master key
// encrypted_master_key is base64url → decrypt with password key (AES-ECB)

// Step 3: decrypt session ID
// encrypted_session_id → decrypt with RSA private key (optional for session-only auth)
// Simpler: use the session ID as returned by MEGA for subsequent calls
```

Full implementation is beyond the scope of this document but the commands are:
- Login: `{"a":"us","user":"<email>","uh":"<userHash>"}`
- Get user info: `{"a":"ug"}`
- List files: `{"a":"f","c":1,"r":1}` — returns the full file tree (encrypted)

### Step A5 — Implement file listing

The `f` command returns a flat list of nodes. Each node has:
- `h` — node handle (ID)
- `p` — parent handle
- `t` — type: 0=file, 1=folder, 2=root, 3=inbox, 4=trash
- `k` — encrypted node key (AES-128)
- `a` — encrypted attributes (name, modification time)
- `s` — file size (files only)
- `ts` — timestamp

Decryption flow per node:
```
1. base64url-decode node key → decrypt with master key (AES-ECB) → node key
2. base64url-decode attributes → decrypt with node key (AES-CBC, zero IV)
3. Strip "MEGA{" prefix → parse JSON → extract "n" (name), "c" (modification time)
```

### Step A6 — No platform-specific setup needed

The Dart HTTP API approach requires **no changes** to:
- `AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `windows/` native code
- Any Xcode capability

The only dependencies are the `encrypt` pub package and `dio` (already present).

---

## Approach B — Official MEGA C++ SDK

Use this only if you need file download, streaming, or features not available via the HTTP API. The official SDK is at: https://github.com/meganz/sdk

---

## Approach B — Windows

### Prerequisites

| Tool | Download |
|---|---|
| Visual Studio 2022 | https://visualstudio.microsoft.com — install with **Desktop development with C++** workload |
| vcpkg | https://github.com/microsoft/vcpkg |
| CMake 3.20+ | Bundled with Visual Studio or https://cmake.org |
| Git | https://git-scm.com |
| Python 3.x | https://python.org (needed by some SDK build scripts) |

### Step B-Win-1 — Clone the MEGA SDK

Open **Developer Command Prompt for VS 2022** (not PowerShell — the MSVC environment must be loaded):

```cmd
git clone --depth=1 https://github.com/meganz/sdk.git mega-sdk
cd mega-sdk
```

### Step B-Win-2 — Install dependencies via vcpkg

```cmd
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat
vcpkg install openssl:x64-windows
vcpkg install libsodium:x64-windows
vcpkg install curl:x64-windows
vcpkg install sqlite3:x64-windows
vcpkg install libuv:x64-windows
vcpkg install c-ares:x64-windows
vcpkg install cryptopp:x64-windows
vcpkg integrate install
cd ..
```

### Step B-Win-3 — Build the SDK as a DLL

```cmd
mkdir build-win
cd build-win
cmake .. ^
  -G "Visual Studio 17 2022" ^
  -A x64 ^
  -DCMAKE_TOOLCHAIN_FILE=..\vcpkg\scripts\buildsystems\vcpkg.cmake ^
  -DVCPKG_TARGET_TRIPLET=x64-windows ^
  -DENABLE_SDKLIB_SHARED=ON ^
  -DENABLE_SDKLIB_EXAMPLES=OFF ^
  -DENABLE_SDKLIB_TESTS=OFF ^
  -DUSE_OPENSSL=ON ^
  -DUSE_SODIUM=ON

cmake --build . --config Release
```

The output DLL will be at `build-win/Release/mega.dll`.

### Step B-Win-4 — Write Dart FFI bindings

Create a Flutter plugin or add to `windows/runner/`:

1. Copy `mega.dll` to `windows/runner/Release/`.
2. Create `lib/data/remote/mega/mega_ffi.dart`:

```dart
import 'dart:ffi';
import 'dart:io';

final DynamicLibrary _mega = DynamicLibrary.open(
  '${Directory.current.path}\\mega.dll',
);

// Define FFI function signatures matching the SDK's C API:
// int mega_init(const char* appKey);
// mega_session_t* mega_login(const char* email, const char* password);
// mega_node_list_t* mega_get_nodes(mega_session_t* session);
// etc.
```

3. Add `mega.dll` to `windows/CMakeLists.txt` as an install target so it is bundled with the built app.

### Step B-Win-5 — Update pubspec for Windows FFI

No additional pub packages are needed for FFI — Dart's `dart:ffi` is part of the SDK. However, add the DLL path to the Windows build:

In `windows/CMakeLists.txt` add at the bottom:
```cmake
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/runner/Release/mega.dll"
        DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
        COMPONENT Runtime)
```

---

## Approach B — Android

### Prerequisites

| Tool | Install via |
|---|---|
| Android Studio | https://developer.android.com/studio |
| Android NDK r25c+ | Android Studio → SDK Manager → SDK Tools → NDK |
| CMake 3.22+ | Android Studio → SDK Manager → SDK Tools → CMake |
| Git | System package manager |

### Step B-And-1 — Clone the MEGA SDK

On your development machine (Windows or Mac):

```bash
git clone --depth=1 https://github.com/meganz/sdk.git mega-sdk
cd mega-sdk
```

### Step B-And-2 — Create Android build scripts

Create `mega-sdk/build-android.sh`:

```bash
#!/bin/bash
# Set these to match your NDK installation
NDK_PATH=$ANDROID_NDK_HOME   # e.g. ~/Android/Sdk/ndk/25.2.9519653
MIN_SDK=21

for ABI in arm64-v8a armeabi-v7a x86_64; do
  mkdir -p build-android-$ABI
  cd build-android-$ABI
  cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$ABI \
    -DANDROID_PLATFORM=android-$MIN_SDK \
    -DENABLE_SDKLIB_SHARED=ON \
    -DENABLE_SDKLIB_EXAMPLES=OFF \
    -DENABLE_SDKLIB_TESTS=OFF \
    -DUSE_OPENSSL=ON \
    -DCMAKE_BUILD_TYPE=Release
  cmake --build . --config Release -j$(nproc)
  cd ..
done
```

Run it:
```bash
chmod +x build-android.sh
./build-android.sh
```

This produces `libmega.so` for each ABI.

### Step B-And-3 — Add the .so files to the Flutter project

Copy the compiled libraries:
```
android/app/src/main/jniLibs/
├── arm64-v8a/
│   └── libmega.so
├── armeabi-v7a/
│   └── libmega.so
└── x86_64/
    └── libmega.so
```

### Step B-And-4 — Create a Flutter plugin with JNI bridge

Create `android/app/src/main/kotlin/com/cloudvault/app/MegaPlugin.kt`:

```kotlin
package com.cloudvault.app

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MegaPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    companion object {
        init {
            System.loadLibrary("mega")
        }
        @JvmStatic external fun nativeLogin(email: String, password: String): Long
        @JvmStatic external fun nativeGetNodes(session: Long): Array<String>
        @JvmStatic external fun nativeLogout(session: Long)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.cloudvault.app/mega")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "login" -> {
                val session = nativeLogin(call.argument("email")!!, call.argument("password")!!)
                result.success(session)
            }
            "getNodes" -> {
                val nodes = nativeGetNodes(call.argument("session")!!)
                result.success(nodes.toList())
            }
            "logout" -> {
                nativeLogout(call.argument("session")!!)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
```

Register the plugin in `MainActivity.kt`:
```kotlin
import com.cloudvault.app.MegaPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MegaPlugin())
    }
}
```

### Step B-And-5 — Create a C JNI wrapper

Create `android/app/src/main/cpp/mega_jni.cpp`:

```cpp
#include <jni.h>
#include "megaapi.h"   // from the MEGA SDK headers

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_cloudvault_app_MegaPlugin_nativeLogin(JNIEnv* env, jobject, jstring email, jstring password) {
    const char* emailStr = env->GetStringUTFChars(email, nullptr);
    const char* passStr  = env->GetStringUTFChars(password, nullptr);
    // Create and authenticate a MegaApi instance
    // Returns a pointer cast to jlong as a session handle
    auto* api = new mega::MegaApi("YOUR_APP_KEY", nullptr, nullptr, "CloudVault");
    // ... async login; full implementation requires MegaRequestListener
    env->ReleaseStringUTFChars(email, emailStr);
    env->ReleaseStringUTFChars(password, passStr);
    return reinterpret_cast<jlong>(api);
}

} // extern "C"
```

Add the CMakeLists for the JNI layer in `android/app/CMakeLists.txt`:
```cmake
cmake_minimum_required(VERSION 3.22)
project(cloudvault_mega)

add_library(mega_jni SHARED src/main/cpp/mega_jni.cpp)
target_link_libraries(mega_jni mega android log)
```

Add to `android/app/build.gradle`:
```groovy
android {
    ...
    defaultConfig {
        ...
        externalNativeBuild {
            cmake {
                cppFlags "-std=c++17"
            }
        }
    }
    externalNativeBuild {
        cmake {
            path "CMakeLists.txt"
        }
    }
}
```

---

## Approach B — iOS

### Prerequisites

| Tool | Notes |
|---|---|
| Mac with Xcode 15+ | iOS builds require macOS |
| CocoaPods 1.12+ | `sudo gem install cocoapods` |
| CMake 3.22+ | `brew install cmake` |
| Homebrew | https://brew.sh |

### Step B-iOS-1 — Install MEGA SDK dependencies via Homebrew

```bash
brew install openssl@3 libsodium libuv c-ares cryptopp
```

### Step B-iOS-2 — Clone the MEGA SDK

```bash
git clone --depth=1 https://github.com/meganz/sdk.git mega-sdk
cd mega-sdk
```

### Step B-iOS-3 — Build the SDK as an XCFramework

Create `build-ios.sh`:

```bash
#!/bin/bash
# Build for device (arm64)
xcodebuild archive \
  -scheme MEGASdk \
  -destination "generic/platform=iOS" \
  -archivePath build/MEGASdk-iOS \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build for simulator (x86_64 + arm64)
xcodebuild archive \
  -scheme MEGASdk \
  -destination "generic/platform=iOS Simulator" \
  -archivePath build/MEGASdk-Simulator \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Combine into XCFramework
xcodebuild -create-xcframework \
  -framework build/MEGASdk-iOS.xcarchive/Products/Library/Frameworks/MEGASdk.framework \
  -framework build/MEGASdk-Simulator.xcarchive/Products/Library/Frameworks/MEGASdk.framework \
  -output build/MEGASdk.xcframework
```

> **Note:** The MEGA SDK for iOS does not ship an Xcode project by default. You must create one or use the CMake-based approach with the iOS toolchain from https://github.com/leetal/ios-cmake.

### Step B-iOS-4 — Add XCFramework to the Flutter iOS project

1. Copy `MEGASdk.xcframework` to `ios/Frameworks/`.
2. In Xcode, select the **Runner** target → **General** → **Frameworks, Libraries, and Embedded Content**.
3. Click **+**, navigate to `ios/Frameworks/MEGASdk.xcframework`, and add it.
4. Set **Embed** to **Embed & Sign**.

### Step B-iOS-5 — Create a Flutter method channel (Swift)

Create `ios/Runner/MegaPlugin.swift`:

```swift
import Flutter
import MEGASdk

class MegaPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.cloudvault.app/mega",
            binaryMessenger: registrar.messenger()
        )
        let instance = MegaPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "login":
            guard let args = call.arguments as? [String: Any],
                  let email = args["email"] as? String,
                  let password = args["password"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            // MEGASdk.sharedSdk.login(withEmail: email, password: password, delegate: ...)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

Register it in `AppDelegate.swift`:
```swift
import MEGASdk

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(_ application: UIApplication,
                               didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        MegaPlugin.register(with: self.registrar(forPlugin: "MegaPlugin")!)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### Step B-iOS-6 — Podfile update

Add to `ios/Podfile`:
```ruby
target 'Runner' do
  use_frameworks!
  # If using CocoaPods distribution of MEGA SDK (if available):
  # pod 'MEGASdkiOS', '~> 4.0'
  # Otherwise link the XCFramework directly (Step B-iOS-4 above)
end
```

---

## Dart-side method channel (shared for Android and iOS, Approach B)

Create `lib/data/remote/mega/mega_platform_channel.dart`:

```dart
import 'package:flutter/services.dart';

class MegaPlatformChannel {
  static const _channel = MethodChannel('com.cloudvault.app/mega');

  Future<int> login(String email, String password) async {
    return await _channel.invokeMethod<int>('login', {
      'email': email,
      'password': password,
    }) ?? -1;
  }

  Future<List<Map<String, dynamic>>> getNodes(int session) async {
    final raw = await _channel.invokeMethod<List>('getNodes', {'session': session});
    return raw?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<void> logout(int session) async {
    await _channel.invokeMethod('logout', {'session': session});
  }
}
```

---

## What to implement first

Given the complexity above, the recommended sequencing is:

1. **Now — Approach A, Step A1:** Register the MEGA app key (takes 5 minutes).
2. **Now — Approach A, Step A2:** Add the `encrypt` package to `pubspec.yaml`.
3. **Short term:** Implement `MegaCrypto` and replace the stub `MegaAuthService` with real API calls for login and user info. This unblocks the "Session expired" and "MEGA scanning not available" errors.
4. **Medium term:** Implement file listing (the `f` command) with node key decryption. This is the bulk of the crypto work.
5. **Later (if needed):** Approach B for any platform that requires file download.

The `mega_api.dart` stub and `mega_client.dart` placeholder are already wired into the scan orchestrator and DI graph — no structural changes are needed. Only the crypto and API implementations need to be filled in.
