# CLAUDE.md

## Project overview
- **App name:** CloudVault Analyzer (`com.cloudvault.app`)
- **Platform:** Cross-platform Flutter — Windows (primary dev target), Android, iOS, macOS, Linux
- **Purpose:** Scan Google Drive, OneDrive, Dropbox, TeraBox, MEGA, and iCloud metadata to surface large files, duplicates, storage breakdown, and access-age analytics — no file content is ever downloaded (read-only OAuth scopes)
- **Version:** 1.0.0 — Dart SDK `>=3.3.0 <4.0.0`; Flutter ≥3.22; Android minSdk 21; Windows 10+

---

## Tech stack
- **Language:** Dart 3.3
- **Framework:** Flutter (Material 3, adaptive layout: sidebar ≥720 px, bottom-nav on mobile)
- **Build system:** Flutter CLI / `pubspec.yaml`; code-gen via `build_runner` + `drift_dev`
- **Key libs:**

| Library | Version | Role |
|---|---|---|
| flutter_riverpod | ^2.5.1 | State management + DI |
| go_router | ^14.0.0 | Declarative navigation |
| drift + drift_flutter | ^2.22.0 / ^0.2.7 | SQLite ORM (Drift) |
| flutter_web_auth_2 | ^4.0.0 | OAuth 2.0 PKCE (all platforms) |
| sign_in_with_apple | ^6.0.0 | Sign in with Apple (iOS + macOS) |
| flutter_secure_storage | ^9.2.2 | Keychain/Keystore token storage |
| dio | ^5.4.3 | HTTP client |
| fl_chart | ^0.68.0 | Animated charts |
| intl | ^0.19.0 | Date/number formatting |
| path_provider | ^2.1.3 | Platform file paths |
| uuid | ^4.4.0 | Local UUID generation |
| google_fonts | ^6.2.1 | Typography |
| csv / excel / pdf / printing | ^6/^4/^3/^5 | Export formats |
| share_plus | 12.0.2 | File sharing (pinned — API changed in 13) |
| connectivity_plus | ^6.0.3 | Network state |
| shimmer / lottie | ^3.0.0 / ^3.1.0 | Loading states |

- **No shared KMM/MAUI layer** — pure Flutter Dart throughout

---

## Architecture
- **Pattern:** Clean Architecture with Riverpod-based MVVM
- **Layers:**
  - `core/` — constants, extensions, theme, logging, utils (no Flutter deps)
  - `domain/` — plain-Dart models + use-case classes (no Flutter, no Riverpod)
  - `data/` — repositories, DAOs, remote API clients (implements domain interfaces)
  - `presentation/` — Riverpod providers, screens, widgets, navigation

- **Data flow:**
  ```
  ConsumerWidget
    → ref.watch(xxxProvider)          # Riverpod FutureProvider / StreamProvider
    → UseCase.execute()               # domain/usecases/
    → RepositoryImpl.method()         # data/repositories/
    → FileRecordDao / GoogleDriveApi  # data/local | data/remote
  ```

- **DI:** Manual — all services/repos/use-cases wired in `lib/presentation/providers/di_providers.dart` as `Provider<T>` singletons; no Hilt/Koin/get_it

- **Navigation:** GoRouter 14 with a single `ShellRoute` wrapping a persistent `ShellScaffold`; auth redirect (`/login` ↔ `/`) driven by `accountsStreamProvider`; `_AuthChangeNotifier` decouples auth state from router rebuild

---

## Project structure
```
lib/
├── main.dart                  # Entry point; ProviderScope + AppLogger.init()
├── core/
│   ├── constants/             # AppConstants, OAuthConstants, ApiEndpoints
│   ├── errors/                # AppException hierarchy
│   ├── extensions/            # int (storage), DateTime, String helpers
│   ├── logging/               # AppLogger (file + console, Documents/cloudvault_debug.log)
│   ├── theme/                 # AppTheme (light/dark), AppColors, AppTextStyles
│   └── utils/                 # FileTypeUtils (MIME → category), PlatformUtils
├── domain/
│   ├── models/                # CloudAccount, CloudFile, ScanSession, DuplicateGroup,
│   │                          #   FolderRank, FileTypeBreakdown, AccessTimeStats, StorageSummary
│   └── usecases/              # auth/, scan/, files/, analytics/, duplicates/
├── data/
│   ├── local/
│   │   ├── database/          # AppDatabase (Drift), 3 tables, 3 DAOs, migration v1→v2
│   │   └── secure_storage/    # TokenStorageService (Keychain/Keystore/Windows Credential)
│   ├── remote/
│   │   ├── google/            # GoogleAuthService, GoogleDriveClient, GoogleDriveApi
│   │   └── microsoft/         # MicrosoftAuthService, OneDriveClient, OneDriveApi
│   └── repositories/          # AuthRepository + FileRepository (interface + impl)
├── presentation/
│   ├── navigation/            # app_router.dart, route_names.dart, shell_scaffold.dart
│   ├── providers/             # di_providers, auth_provider, scan_provider, analytics_provider,
│   │                          #   files_provider, duplicates_provider, settings_provider
│   ├── screens/
│   │   ├── accounts/          # AccountsScreen (cloud mgmt), AccountDetailScreen
│   │   ├── analytics/         # AnalyticsScreen (4 tabs) + widgets/
│   │   ├── dashboard/         # DashboardScreen (per-account analytics) + scan_progress_banner
│   │   ├── duplicates/        # DuplicatesScreen
│   │   ├── files/             # FilesScreen (browse + filter)
│   │   ├── login/             # LoginScreen (OAuth entry)
│   │   └── settings/          # SettingsScreen (theme toggle)
│   └── widgets/               # CloudProviderIcon, EmptyState, StatCard
└── services/
    ├── scan_orchestrator.dart  # Dart Isolate-based scan engine; emits Stream<ScanProgress>
    └── export_service.dart     # CSV/Excel/PDF export
```

---

## Key modules & entry points
- **App entry:** `lib/main.dart` → `CloudVaultApp` (ConsumerWidget); initialises `AppLogger`, wraps in `ProviderScope`
- **DI root:** `lib/presentation/providers/di_providers.dart` — all `Provider<T>` declarations; start here when tracing dependencies
- **DB:** `lib/data/local/database/app_database.dart` — schema v2; `AppDatabase` opened once via `dbProvider`; WAL mode + FK enabled
- **Scan engine:** `services/scan_orchestrator.dart` — spawns a `dart:isolate` Isolate; token must be refreshed on main thread *before* spawning (isolate cannot refresh mid-scan)
- **Background work:** scan Isolate only; no WorkManager / background fetch services

---

## State management
- **Riverpod 2** — all state lives in providers; no global singletons outside `di_providers.dart`

| Provider | Type | Holds |
|---|---|---|
| `accountsStreamProvider` | `StreamProvider<List<CloudAccount>>` | Live account list from DB — single source of truth |
| `activeAccountIdProvider` | `StateProvider<String?>` | Selected account ID across screens |
| `activeAccountProvider` | `Provider<CloudAccount?>` | Derived from above |
| `scanProvider` | `NotifierProvider<ScanNotifier, ScanState>` | Scan running/progress/error |
| `settingsProvider` | `NotifierProvider<SettingsNotifier, SettingsState>` | Theme mode (in-memory only) |
| `fileTypeBreakdownProvider` | `FutureProvider.family<…, String>` | Per-account, keyed by accountId |
| `duplicateSummaryProvider` | `FutureProvider.family<…, String>` | Quick dup count + wasted bytes |
| `fileAgeStatsProvider` | `FutureProvider.family<…, String>` | File count by modification-date age buckets |
| `depthDistributionProvider` | `FutureProvider.family<…, String>` | Entry count by path depth level |

- After a scan completes, `ScanNotifier._invalidateDataProviders(accountId)` invalidates all related `FutureProvider.family` caches to force re-fetch

---

## Build, run & test

### First-time setup
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.g.dart (Drift)
```

### Run
```bash
flutter run -d windows        # Windows desktop
flutter run -d android        # Android (USB debug)
flutter run -d chrome         # Web (limited — no secure storage)
```

### Build release
```bash
flutter build windows         # Windows MSIX/exe in build/windows/
flutter build apk             # Android APK
flutter build appbundle       # Android AAB for Play Store
```

### Test & lint
```bash
flutter test                  # runs test/widget_test.dart (smoke test only)
flutter analyze               # lint — must pass before committing
```

### Code-gen (re-run after changing Drift tables or DAOs)
```bash
dart run build_runner build --delete-conflicting-outputs
# OR watch mode during development:
dart run build_runner watch --delete-conflicting-outputs
```
Generated files: `app_database.g.dart`, `account_dao.g.dart`, `file_record_dao.g.dart`, `scan_session_dao.g.dart` — all excluded from the analyser via `analysis_options.yaml`

### Required credentials (fill before first OAuth flow)
File: `lib/core/constants/oauth_constants.dart`
- `GoogleOAuthConstants.clientIdAndroid` — Google Console → OAuth 2.0 → Android client
- `GoogleOAuthConstants.clientIdIos` — Google Console → OAuth 2.0 → iOS client
- `GoogleOAuthConstants.clientIdDesktop` / `clientSecretDesktop` — Desktop App client (**currently has a real credential committed — rotate and move to a gitignored file**)
- `MicrosoftOAuthConstants.clientId` — Azure Portal → App Registrations → Application (client) ID

No `.env` file or `local.properties` required beyond standard Flutter Android setup.

---

## Coding conventions

### Naming
- **Files:** `snake_case.dart` (e.g. `file_record_dao.dart`, `cloud_account.dart`)
- **Classes:** `PascalCase`
- **Providers:** `xxxProvider` suffix (e.g. `scanProvider`, `fileAgeStatsProvider`)
- **Screen widgets:** `XxxScreen extends ConsumerWidget`
- **Notifiers:** `XxxNotifier extends Notifier<XxxState>`
- **State objects:** immutable class `XxxState` with `copyWith()`
- **Private file-local widgets:** `_XxxWidget` (underscore prefix, defined in same file as screen)
- **Resources:** Flutter asset paths in `assets/images/` and `assets/lottie/`

### Code style
- Linter: `flutter_lints` + custom rules in `analysis_options.yaml`
  - Enforced: `always_declare_return_types`, `avoid_print`, `prefer_const_constructors`, `use_super_parameters`
  - Run: `flutter analyze` — zero warnings policy before merging
- `withOpacity()` → use `withValues(alpha:)` throughout (migration complete)
- No comments on obvious code; comments only for non-obvious constraints or workarounds

### No established branch/commit convention in the repo

---

## Known issues / gotchas

- **Google desktop credential exposed:** `clientIdDesktop` + `clientSecretDesktop` in `oauth_constants.dart` are real values in source — rotate them and move to a gitignored `secrets.dart` before pushing publicly
- **Settings not persisted:** `SettingsState` is in-memory only; theme resets to dark on app restart (SharedPreferences not yet wired)
- **Folder size disabled in Dashboard:** `folderRankingsProvider` triggers a recursive CTE query that is too slow for large accounts (10k+ files); deliberately not called from `DashboardScreen` — use Analytics screen instead
- **Token refresh race on Windows:** `flutter_secure_storage` on Windows has a write-then-read race condition; mitigated by in-memory cache in `TokenStorageService` — do not remove that cache
- **Isolate token constraint:** `ScanOrchestrator` spawns a Dart Isolate that receives a snapshot of the access token. Token *must* be refreshed on the main thread before `startScan()` is called. `ScanNotifier` handles this; do not call `ScanOrchestrator.startScan()` directly
- **`share_plus` pinned at 12.0.2:** API changed in v13 (`SharePlus.instance.share()`); `ExportService` still uses the v12 API — upgrade needs a refactor of `export_service.dart:153`
- **Deprecated UI widgets:** `DropdownButtonFormField` (filter_panel.dart) and `RadioListTile.groupValue` (settings_screen.dart) use old APIs — deferred migration, flagged by analyser as `info` only
- **DB schema v2 migration:** adds `content_hash` column to `file_records` + duplicate-detection index; existing installs auto-migrate via `onUpgrade`
- **One scan at a time:** `ScanNotifier` guards against concurrent scans (`if (state.isScanning) return`) — UI must check `scanState.isScanning` before offering a sync button
- **No test coverage beyond smoke test:** `test/widget_test.dart` only verifies the app doesn't crash on launch; no unit or integration tests exist yet
- **iCloud Drive has no public REST API:** `ICloudApi.testConnection()` always throws `ScanException` — scanning is blocked on all platforms until native iOS/macOS integration is built. Auth (Sign in with Apple) works only on iOS and macOS; attempting it on Windows/Android/Linux throws `AuthException` immediately in `AppleAuthService.authorize()`. This mirrors the MEGA pattern.
- **iCloud token refresh impossible:** Apple identity tokens expire in 10 minutes and cannot be refreshed programmatically — `AppleAuthService.refreshAccessToken()` returns `null`. Users must re-auth manually; the app will show "Session expired" on the next 401.
- **Sign in with Apple requires Xcode capability:** "Sign In with Apple" must be added as a capability in Xcode for both iOS and macOS targets, and the bundle ID must match `com.cloudvault.app`. Missing this causes a native crash on `SignInWithApple.getAppleIDCredential()`.
- **Apple omits email/name after first sign-in:** The identity token only contains `email` and `name` on the very first authorisation. `AuthRepositoryImpl.loginApple()` persists whatever is available; subsequent re-auths fall back to the stored DB row.
