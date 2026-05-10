# Architecture

CloudVault Analyzer follows **Clean Architecture** with three explicit layers: Presentation, Domain, and Data. Riverpod is the dependency injection and state management backbone.

---

## Layer Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION                             │
│  Screens  ·  Providers (Riverpod)  ·  Widgets  ·  Navigation   │
└────────────────────────┬────────────────────────────────────────┘
                         │  calls Use Cases
┌────────────────────────▼────────────────────────────────────────┐
│                          DOMAIN                                 │
│         Models  ·  Use Cases  ·  Repository Interfaces          │
└────────────────────────┬────────────────────────────────────────┘
                         │  implemented by
┌────────────────────────▼────────────────────────────────────────┐
│                           DATA                                  │
│  Remote API clients  ·  Auth services  ·  Drift DB  ·  Secure   │
│  storage  ·  Repository implementations                         │
└─────────────────────────────────────────────────────────────────┘
```

### Key Principles

- **Dependency rule**: inner layers (Domain) never import outer layers (Data/Presentation).
- **Use Cases**: each is a single-method class (`call()`). Screens/providers only interact through use cases, never directly with repositories.
- **Repositories**: defined as abstract classes in `domain/`, implemented in `data/`.

---

## File Tree

```
lib/
├── main.dart
│
├── core/                              # Cross-cutting utilities (no business logic)
│   ├── constants/
│   │   ├── app_constants.dart         # Magic numbers, breakpoints, cache durations
│   │   ├── api_endpoints.dart         # Google Drive & OneDrive base URLs
│   │   └── oauth_constants.dart       # Client IDs, scopes, redirect URIs
│   ├── errors/
│   │   └── app_exception.dart         # Sealed AppException hierarchy
│   ├── extensions/
│   │   ├── datetime_extensions.dart
│   │   ├── int_extensions.dart        # .toStorageString(), .toFileCountLabel()
│   │   └── string_extensions.dart
│   ├── theme/
│   │   ├── app_colors.dart            # Brand palette, light/dark surfaces
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart             # Material 3 ThemeData (light & dark)
│   └── utils/
│       ├── file_type_utils.dart       # MIME → FileCategory classifier
│       └── platform_utils.dart
│
├── domain/
│   ├── models/
│   │   ├── cloud_account.dart         # Connected account (id, email, provider, stats)
│   │   ├── cloud_file.dart            # File record (name, path, size, dates)
│   │   ├── scan_session.dart          # Scan run + progress snapshot
│   │   ├── storage_summary.dart       # Aggregate stats per account
│   │   ├── duplicate_group.dart       # Set of files with same name+size
│   │   ├── file_type_breakdown.dart   # Per-category size distribution
│   │   ├── access_time_stats.dart     # Bucket counts (recent/old/very old/never)
│   │   └── folder_rank.dart           # Folder path + total size
│   └── usecases/
│       ├── auth/
│       │   ├── login_google_usecase.dart
│       │   ├── login_microsoft_usecase.dart
│       │   └── logout_account_usecase.dart
│       ├── scan/
│       │   ├── start_scan_usecase.dart
│       │   └── cancel_scan_usecase.dart
│       ├── analytics/
│       │   ├── get_storage_summary_usecase.dart
│       │   ├── get_largest_files_usecase.dart
│       │   ├── get_file_type_breakdown_usecase.dart
│       │   ├── get_folder_rankings_usecase.dart
│       │   └── get_access_time_stats_usecase.dart
│       ├── duplicates/
│       │   └── find_duplicates_usecase.dart
│       └── files/
│           └── get_files_usecase.dart
│
├── data/
│   ├── local/
│   │   ├── database/
│   │   │   ├── app_database.dart      # @DriftDatabase — opens SQLite connection
│   │   │   ├── tables/
│   │   │   │   ├── accounts_table.dart
│   │   │   │   ├── file_records_table.dart
│   │   │   │   └── scan_sessions_table.dart
│   │   │   └── daos/
│   │   │       ├── account_dao.dart
│   │   │       ├── file_record_dao.dart
│   │   │       └── scan_session_dao.dart
│   │   └── secure_storage/
│   │       └── token_storage_service.dart   # Wraps flutter_secure_storage
│   ├── remote/
│   │   ├── google/
│   │   │   ├── google_auth_service.dart     # PKCE authorize + refresh
│   │   │   ├── google_drive_client.dart     # Dio client with token interceptor
│   │   │   └── google_drive_api.dart        # Paginated file listing stream
│   │   └── microsoft/
│   │       ├── microsoft_auth_service.dart  # PKCE authorize + refresh
│   │       ├── onedrive_client.dart         # Dio client with token interceptor
│   │       └── onedrive_api.dart            # Paginated item listing stream
│   └── repositories/
│       ├── auth_repository.dart             # Abstract interface
│       ├── auth_repository_impl.dart
│       ├── file_repository.dart             # Abstract interface
│       └── file_repository_impl.dart
│
├── services/
│   ├── scan_orchestrator.dart               # Spawns Dart Isolate for scanning
│   └── export_service.dart                  # CSV / Excel / PDF export
│
└── presentation/
    ├── navigation/
    │   ├── route_names.dart
    │   ├── app_router.dart                  # GoRouter + auth redirect guard
    │   └── shell_scaffold.dart             # Adaptive: sidebar (≥720px) / bottom nav
    ├── providers/
    │   ├── di_providers.dart               # All Riverpod Provider wiring
    │   ├── auth_provider.dart
    │   ├── scan_provider.dart
    │   ├── files_provider.dart
    │   ├── analytics_provider.dart
    │   ├── duplicates_provider.dart
    │   └── settings_provider.dart
    ├── screens/
    │   ├── login/login_screen.dart
    │   ├── dashboard/dashboard_screen.dart
    │   ├── files/files_screen.dart
    │   ├── analytics/analytics_screen.dart
    │   ├── duplicates/duplicates_screen.dart
    │   ├── accounts/accounts_screen.dart
    │   └── settings/settings_screen.dart
    └── widgets/
        ├── cloud_provider_icon.dart
        ├── empty_state.dart
        └── stat_card.dart
```

---

## Database Schema (Drift / SQLite)

### `accounts`

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT PK | UUID |
| `provider` | TEXT | `google` \| `microsoft` |
| `email` | TEXT | Account email |
| `display_name` | TEXT | Full name |
| `photo_url` | TEXT? | Avatar URL |
| `total_files` | INT | Updated after scan |
| `total_folders` | INT | |
| `total_bytes` | INT | |
| `last_scan_at` | INT? | Unix timestamp ms |
| `created_at` | INT | |

### `file_records`

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT PK | UUID (local) |
| `account_id` | TEXT FK → accounts | |
| `provider` | TEXT | `google` \| `microsoft` |
| `provider_file_id` | TEXT | Native Drive/OneDrive ID |
| `name` | TEXT | File/folder name |
| `path` | TEXT | Full path string |
| `size_bytes` | INT? | null for folders |
| `mime_type` | TEXT | |
| `category` | TEXT | image/video/document/etc. |
| `is_folder` | BOOL | |
| `modified_at` | INT | Unix ms |
| `accessed_at` | INT? | Unix ms |
| `parent_id` | TEXT? | providerFileId of parent |

**Indexes**: `(account_id, size_bytes DESC)`, `(account_id, category)`, `(account_id, accessed_at)`, `(parent_id)`, `(name, size_bytes)`

### `scan_sessions`

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT PK | UUID |
| `account_id` | TEXT | |
| `status` | TEXT | `running` \| `complete` \| `failed` |
| `started_at` | INT | Unix ms |
| `completed_at` | INT? | |
| `total_files` | INT? | |
| `total_folders` | INT? | |
| `total_bytes` | INT? | |
| `error` | TEXT? | Error message if failed |

---

## Auth Flow

```
User taps "Continue with Google / Microsoft"
        │
        ▼
flutter_appauth.authorizeAndExchangeCode()   ← PKCE, no client secret on mobile
        │
        ▼
Receives: access_token, refresh_token, id_token, expiry
        │
        ▼
TokenStorageService.saveTokens()             ← flutter_secure_storage
        │            (Keychain / Keystore / Credential Manager)
        ▼
Fetch user profile from Drive/Graph API
        │
        ▼
AccountDao.upsertAccount()                   ← persist to SQLite
        │
        ▼
authProvider emits updated account list
        │
        ▼
GoRouter redirects to /dashboard
```

### Token Refresh

Dio interceptors in `GoogleDriveClient` / `OneDriveClient` check token validity before every request. If expired (or within a 5-minute buffer), they call `refreshAccessToken()` transparently.

---

## Scan Flow

```
User taps "Scan Now"
        │
        ▼
ScanProvider.startScan(account)
        │
        ▼
ScanOrchestrator.startScan(account)
        │
        ▼
Dart Isolate spawned (_scanWorker)
  ├── reads access token (pre-fetched, passed as param)
  ├── creates lightweight API client inside Isolate
  ├── paginates Drive / OneDrive API (1000 items/page)
  ├── sends ScanProgressMessage every file
  └── batches 100 file records → sends as List to main thread
        │
Main thread receives:
  ├── ScanProgressMessage  → updates ScanProvider state (UI progress bar)
  ├── List<Map>            → bulk inserts into SQLite via FileRecordDao
  └── ScanCompleteMessage  → updates account stats, marks session complete
```

---

## Analytics Queries (all run on local SQLite)

| Feature | Query strategy |
|---------|---------------|
| Storage by type | `GROUP BY category, SUM(size_bytes)` |
| Largest files | `ORDER BY size_bytes DESC LIMIT 15` |
| Folder rankings | `GROUP BY parent_id, SUM(size_bytes)`, then look up folder names |
| Access time buckets | `CASE` on `accessed_at` vs. `now - 180d / 365d / 730d` |
| Duplicates | Two-pass: group by `(name, size_bytes)` where count > 1 |

---

## Riverpod Provider Graph

```
dbProvider ─────────────────────────────────────┐
tokenStorageProvider ────────────────────────── │
                                                 │
googleAuthServiceProvider ─────────────────── ──┤
googleDriveClientProvider ──────────────────── ─┤
googleDriveApiProvider ─────────────────────── ─┤   authRepositoryProvider
                                                 │         │
microsoftAuthServiceProvider ───────────────── ─┤   fileRepositoryProvider
oneDriveClientProvider ─────────────────────── ─┤
oneDriveApiProvider ────────────────────────── ─┘
                                                        │
                              ┌─────────────────────────┤
                              │                         │
                     authProvider          analyticsProviders
                     scanProvider          filesProvider
                     duplicatesProvider    settingsProvider
                              │
                     UI Screens (ConsumerWidget)
```

---

## Adaptive Layout

`ShellScaffold` detects viewport width:

- **≥ 720 px** → persistent left sidebar (240 px) + main content
- **< 720 px** → bottom NavigationBar (5 items; Settings reachable from Accounts)

---

## Error Hierarchy

```
AppException (sealed)
├── AuthException          OAuth / token errors
├── TokenExpiredException  Silent token expiry
├── NetworkException       Dio connectivity errors
├── ApiException           Non-2xx API responses (includes statusCode)
├── ScanException          Isolate-level scan errors
├── ExportException        CSV/Excel generation errors
└── StorageException       flutter_secure_storage errors
```
