import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/files/files_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/duplicates/duplicates_screen.dart';
import '../screens/accounts/accounts_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/analytics/access_bucket_screen.dart';
import '../screens/accounts/account_detail_screen.dart';
import '../../domain/models/access_time_stats.dart';
import '../../domain/models/cloud_account.dart';
import 'route_names.dart';
import 'shell_scaffold.dart';

// Thin ChangeNotifier so GoRouter can re-run its redirect without the
// Provider recreating a new GoRouter instance every time accounts change.
class _AuthChangeNotifier extends ChangeNotifier {
  bool? _hasAccounts; // null = still loading

  bool? get hasAccounts => _hasAccounts;

  void update(bool? value) {
    if (_hasAccounts != value) {
      _hasAccounts = value;
      notifyListeners();
    }
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();

  // Seed with whatever value is already available (avoids a login flash on
  // hot restart when the stream provider's cache is warm).
  final initial = ref.read(accountsStreamProvider).valueOrNull;
  if (initial != null) authNotifier.update(initial.isNotEmpty);

  // Primary: DB stream keeps the notifier in sync after scans/deletes.
  ref.listen<AsyncValue<List<CloudAccount>>>(
    accountsStreamProvider,
    (_, next) {
      if (next is AsyncData<List<CloudAccount>>) {
        authNotifier.update(next.value.isNotEmpty);
      }
    },
  );

  // Secondary: authProvider is explicitly set by AuthNotifier after every
  // login. On Android the DB-stream emission can arrive during the window
  // where Riverpod resumes from the background (CCT activity), causing the
  // primary listener to miss it. Listening here guarantees redirect fires.
  ref.listen<AsyncValue<List<CloudAccount>>>(
    authProvider,
    (_, next) {
      if (next is AsyncData<List<CloudAccount>>) {
        authNotifier.update(next.value.isNotEmpty);
      }
    },
  );

  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: RouteName.dashboard,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final hasAccounts = authNotifier.hasAccounts;
      if (hasAccounts == null) return null; // still loading — don't redirect
      final isLoggingIn = state.matchedLocation == RouteName.login;
      if (!hasAccounts && !isLoggingIn) return RouteName.login;
      if (hasAccounts && isLoggingIn) return RouteName.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteName.login,
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            ShellScaffold(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: RouteName.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteName.files,
            builder: (_, __) => const FilesScreen(),
          ),
          GoRoute(
            path: RouteName.analytics,
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: RouteName.duplicates,
            builder: (_, __) => const DuplicatesScreen(),
          ),
          GoRoute(
            path: RouteName.accounts,
            builder: (_, __) => const AccountsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) {
                  final accountId = state.pathParameters['id'] ?? '';
                  return AccountDetailScreen(accountId: accountId);
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteName.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: RouteName.accessBucketFiles,
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final bucket = extra?['bucket'] as AccessTimeBucket? ??
                  AccessTimeBucket.recentSixMonths;
              final accountId = extra?['accountId'] as String? ?? '';
              return AccessBucketScreen(bucket: bucket, accountId: accountId);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
