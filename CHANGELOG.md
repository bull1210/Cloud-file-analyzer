# Changelog

All notable changes to CloudVault Analyzer are documented here.

---

## [Unreleased]

### Added
- Initial full implementation of CloudVault Analyzer
- Multi-account support for Google Drive and Microsoft OneDrive
- OAuth 2.0 PKCE authentication via `flutter_appauth`
- Background file metadata scanning using Dart Isolates
- Dashboard with per-account stats (files, folders, storage, largest file)
- File browser with sort/filter (name, size, category, date, provider)
- Analytics screen: storage by type (pie chart), largest files table, folder rankings bar chart, access-time heatmap
- Duplicate finder (name + size fingerprint grouping)
- Export reports as CSV and Excel (.xlsx)
- Adaptive layout: sidebar navigation on wide screens (≥ 720 px), bottom nav on mobile
- Dark / Light / System theme switching
- Settings screen with theme picker and data management
- Secure token storage via `flutter_secure_storage` (Keychain/Keystore/Credential Manager)
- Local SQLite cache via Drift with WAL mode and query indexes
- Typed exception hierarchy (`AppException` sealed class)
- Platform configuration files for Android (AndroidManifest.xml) and iOS (Info.plist)

### Technical
- Clean Architecture: Presentation → Domain → Data layers
- Riverpod 2.x for state management and dependency injection
- go_router 14 for declarative navigation with auth redirect guard
- Drift 2 for type-safe SQLite with generated DAOs
- Dio 5 with token-refresh interceptors for both Google and Microsoft APIs

---

## Version History

| Version | Date | Notes |
|---------|------|-------|
| 1.0.0 | 2026-05-05 | Initial release |
