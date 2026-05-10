import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_logo.dart';
import 'route_names.dart';

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

const _navItems = [
  _NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    path: RouteName.dashboard,
  ),
  _NavItem(
    label: 'Files',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    path: RouteName.files,
  ),
  _NavItem(
    label: 'Analytics',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    path: RouteName.analytics,
  ),
  _NavItem(
    label: 'Duplicates',
    icon: Icons.copy_outlined,
    selectedIcon: Icons.copy,
    path: RouteName.duplicates,
  ),
  _NavItem(
    label: 'Accounts',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    path: RouteName.accounts,
  ),
  _NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: RouteName.settings,
  ),
];

class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  final Widget child;
  final String currentPath;

  int get _selectedIndex {
    // Exact match first, then prefix match for sub-routes (e.g. /accounts/123)
    final exact = _navItems.indexWhere((item) => item.path == currentPath);
    if (exact != -1) return exact;
    final prefix = _navItems.indexWhere(
      (item) => item.path != RouteName.dashboard && currentPath.startsWith(item.path),
    );
    return prefix == -1 ? 0 : prefix;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppConstants.desktopBreakpoint;
    final isAuthenticating = ref.watch(authProvider).isLoading;

    final shell = isDesktop
        ? _DesktopLayout(
            selectedIndex: _selectedIndex,
            onNavigate: (index) => context.go(_navItems[index].path),
            child: child,
          )
        : _MobileLayout(
            selectedIndex: _selectedIndex,
            onNavigate: (index) => context.go(_navItems[index].path),
            child: child,
          );

    // When an OAuth flow starts, flutter_web_auth_2 places the WebView as a
    // native child control that only covers the body area, leaving a thin strip
    // of Flutter content visible at the top. Show an opaque loading screen so
    // the dashboard/sidebar don't bleed into that strip.
    if (isAuthenticating) {
      return Scaffold(
        body: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CloudVaultLogo(size: 64, showShadow: true),
                SizedBox(height: 24),
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting to cloud account…'),
              ],
            ),
          ),
        ),
      );
    }

    return shell;
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.child,
    required this.selectedIndex,
    required this.onNavigate,
  });

  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar
          Container(
            width: AppConstants.sidebarWidth,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              // Guard: during the OAuth WebView overlay the main window's
              // available height may briefly collapse. Render nothing rather
              // than overflowing and showing the debug banner.
              if (constraints.maxHeight < 120) return const SizedBox.expand();
              return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // App logo/name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const CloudVaultLogo(size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'CloudVault',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Nav items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final selected = index == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          selected: selected,
                          selectedTileColor: AppColors.brand.withValues(alpha:0.12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Icon(
                            selected ? item.selectedIcon : item.icon,
                            color: selected
                                ? AppColors.brand
                                : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.brand
                                  : colorScheme.onSurface,
                            ),
                          ),
                          onTap: () => onNavigate(index),
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'CloudVault Analyzer',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
          ),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.child,
    required this.selectedIndex,
    required this.onNavigate,
  });

  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    // Show only 5 items in bottom nav; Settings accessible from Accounts
    final bottomItems = _navItems.take(5).toList();
    final bottomIndex = selectedIndex.clamp(0, bottomItems.length - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomIndex,
        onDestinationSelected: onNavigate,
        destinations: bottomItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}
