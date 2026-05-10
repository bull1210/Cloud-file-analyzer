# Development Guide

Local development setup, code generation, testing, and contribution workflow.

---

## First-Time Setup

```bash
# 1. Clone
git clone <repo-url> cloudvault_analyzer
cd cloudvault_analyzer

# 2. Install Flutter dependencies
flutter pub get

# 3. Generate Drift database code (required before first build)
dart run build_runner build --delete-conflicting-outputs

# 4. Verify everything compiles
flutter analyze
```

---

## Code Generation (Drift)

Drift generates `app_database.g.dart` from the annotated table and DAO classes. Re-run whenever you change a table definition or DAO query:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or use watch mode during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

The generated file (`lib/data/local/database/app_database.g.dart`) **is committed to git** so CI builds don't require `build_runner`.

---

## Project Conventions

### Dart/Flutter

- Null safety: Dart 3.x sound null safety throughout.
- Const constructors: use `const` wherever possible.
- Named parameters: prefer named for any function with ≥ 2 parameters.
- No `print()`: use `debugPrint()` or structured logging.
- Return types: always declared explicitly.

### State Management (Riverpod)

- All providers live in `lib/presentation/providers/`.
- `di_providers.dart` contains all infrastructure wiring — screens never instantiate services directly.
- Use `ref.watch` for reactive state; use `ref.read` inside callbacks/event handlers.
- Prefer `AsyncNotifier` / `Notifier` over `StateNotifier` for new code.

### Navigation (go_router)

- All route paths are constants in `RouteNames`.
- Guards live in the `redirect` callback in `app_router.dart` — no `Navigator.push` inside screens.
- Pass complex objects via `state.extra` (typed at the route level).

### Error Handling

- All exceptions extend `AppException` (sealed class in `core/errors/`).
- Providers catch exceptions and surface them as `AsyncError` or a typed error field.
- Never swallow errors silently.

---

## Running Tests

```bash
# Unit + widget tests
flutter test

# Single file
flutter test test/services/scan_orchestrator_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Adding a New Screen

1. Create `lib/presentation/screens/<name>/<name>_screen.dart`
2. Add a route constant to `lib/presentation/navigation/route_names.dart`
3. Register the route in `lib/presentation/navigation/app_router.dart`
4. Add a nav item to `shell_scaffold.dart` if it needs to appear in the sidebar/bottom nav

---

## Adding a New Analytics Query

1. Add a method to `FileRecordDao` (`lib/data/local/database/daos/file_record_dao.dart`)
2. Create a use case in `lib/domain/usecases/analytics/`
3. Add a provider in `lib/presentation/providers/analytics_provider.dart`
4. Wire the provider in `di_providers.dart`

---

## Useful Commands

```bash
# Format all Dart files
dart format lib/

# Static analysis
flutter analyze

# Check outdated dependencies
flutter pub outdated

# Upgrade dependencies (within constraints)
flutter pub upgrade

# Upgrade constraints (careful)
flutter pub upgrade --major-versions

# Clean build caches
flutter clean && flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## IDE Setup

### VS Code

Recommended extensions (`.vscode/extensions.json`):

```json
{
  "recommendations": [
    "Dart-Code.dart-code",
    "Dart-Code.flutter",
    "usernamehw.errorlens",
    "bradlc.vscode-tailwindcss"
  ]
}
```

### Android Studio / IntelliJ

- Install the **Flutter** and **Dart** plugins.
- Enable: *Preferences → Editor → Code Style → Dart → Use dartfmt*.

---

## Environment Variables (--dart-define)

For CI or keeping secrets out of source:

```bash
flutter run \
  --dart-define=GOOGLE_CLIENT_ID_ANDROID=xxxx \
  --dart-define=GOOGLE_CLIENT_ID_IOS=xxxx \
  --dart-define=GOOGLE_CLIENT_ID_DESKTOP=xxxx \
  --dart-define=GOOGLE_CLIENT_SECRET_DESKTOP=xxxx \
  --dart-define=MICROSOFT_CLIENT_ID=xxxx
```

Then in `oauth_constants.dart`:

```dart
static const String clientIdAndroid =
    String.fromEnvironment('GOOGLE_CLIENT_ID_ANDROID');
```

---

## Release Checklist

- [ ] `flutter analyze` passes with no errors
- [ ] `flutter test` passes
- [ ] `pubspec.yaml` version bumped
- [ ] OAuth credentials confirmed for all target platforms
- [ ] `.gitignore` verified — no secrets committed
- [ ] `build_runner build` run with latest generated files committed
- [ ] Tested on real Android device
- [ ] Tested on iOS device / simulator (macOS required)
- [ ] Tested on Windows
