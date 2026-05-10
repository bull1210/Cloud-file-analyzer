# CloudVault Analyzer

A cross-platform Flutter app that connects to **Google Drive** and **Microsoft OneDrive**, scans your cloud storage metadata, and gives you detailed analytics — all without downloading a single file to your device.

---

## Features

| Feature | Description |
|---------|-------------|
| **Multi-account** | Connect multiple Google and Microsoft accounts simultaneously |
| **Background scan** | File metadata scanned in a Dart Isolate so the UI stays fluid |
| **Dashboard** | Per-account summary: total files, folders, storage used, largest file |
| **File browser** | Sort/filter by name, size, category, provider, date |
| **Analytics** | Storage breakdown by type, largest files table, folder rankings, access-time heatmap |
| **Duplicate finder** | Groups files by identical name + size fingerprint |
| **Export** | Download full report as CSV or Excel (.xlsx) |
| **Dark / Light theme** | Follows system or user choice |
| **Offline cache** | SQLite (Drift) keeps last scan results available without network |
| **Read-only** | Only `drive.metadata.readonly` and `Files.Read` scopes — file content is never accessed |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart 3.3+) |
| State management | Riverpod 2.x |
| Navigation | go_router 14 |
| Auth (OAuth 2.0 PKCE) | flutter_appauth 7 |
| Secure storage | flutter_secure_storage 9 |
| HTTP client | Dio 5 |
| Local database | Drift 2 (SQLite) |
| Charts | fl_chart 0.68 |
| Export | csv, excel, pdf, printing |

---

## Project Structure

```
lib/
├── main.dart                         # App entry point
├── core/
│   ├── constants/                    # App & OAuth constants
│   ├── errors/                       # Typed exception hierarchy
│   ├── extensions/                   # DateTime, int, String helpers
│   ├── theme/                        # Material 3 colour scheme & typography
│   └── utils/                        # File-type classifier, platform utils
├── domain/
│   ├── models/                       # Pure data classes (no Flutter/Drift deps)
│   └── usecases/                     # One-operation use cases (auth, scan, analytics)
├── data/
│   ├── local/
│   │   ├── database/                 # Drift tables, DAOs, AppDatabase
│   │   └── secure_storage/          # flutter_secure_storage wrapper
│   ├── remote/
│   │   ├── google/                   # GoogleAuthService, GoogleDriveClient, GoogleDriveApi
│   │   └── microsoft/               # MicrosoftAuthService, OneDriveClient, OneDriveApi
│   └── repositories/                # Interface + Impl for auth & files
├── services/
│   ├── scan_orchestrator.dart        # Isolate-based scan engine
│   └── export_service.dart          # CSV / Excel export
└── presentation/
    ├── navigation/                   # go_router + ShellScaffold (sidebar/bottom nav)
    ├── providers/                    # Riverpod providers (DI, auth, scan, analytics…)
    ├── screens/                      # One folder per screen
    └── widgets/                      # Shared UI components
```

---

## Quick Start

### Prerequisites

- Flutter SDK ≥ 3.16 ([install](https://docs.flutter.dev/get-started/install))
- Dart SDK ≥ 3.3 (bundled with Flutter)
- Git

### 1 — Clone and install dependencies

```bash
git clone <repo-url> cloudvault_analyzer
cd cloudvault_analyzer
flutter pub get
```

### 2 — Generate Drift database code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3 — Configure OAuth credentials

Edit `lib/core/constants/oauth_constants.dart` with your Google and Microsoft credentials.
See [SETUP.md](SETUP.md) for step-by-step instructions.

### 4 — Run

```bash
# Android device / emulator
flutter run -d android

# iOS simulator
flutter run -d ios

# Windows desktop
flutter run -d windows

# macOS desktop
flutter run -d macos

# Linux desktop
flutter run -d linux
```

---

## Documentation Index

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layer design, data flows, provider graph, DB schema |
| [SETUP.md](SETUP.md) | Google Cloud Console + Azure Portal OAuth setup |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Build & install for Android, iOS, Windows, macOS, Linux |

---

## Privacy

CloudVault Analyzer requests **read-only metadata** scopes only:

- Google Drive: `drive.metadata.readonly`
- OneDrive: `Files.Read`, `User.Read`

No file content is ever downloaded to your device. All scan data is stored locally in an encrypted SQLite database on your own machine.

---

## License

MIT — see [LICENSE](LICENSE) for details.
