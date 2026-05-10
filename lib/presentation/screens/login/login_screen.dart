import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/cloud_provider_icon.dart';
import '../../../domain/models/cloud_account.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final isLoading = authAsync.isLoading;

    ref.listen<AsyncValue<List<CloudAccount>>>(authProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) => _showError(context, e),
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    const CloudVaultLogo(size: 80, showShadow: true),
                    const SizedBox(height: 32),
                    Text(
                      'CloudVault Analyzer',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connect your cloud accounts to analyze storage, find large files, and discover duplicates.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Google Sign In
                    _ProviderLoginButton(
                      label: 'Continue with Google',
                      provider: CloudProvider.google,
                      isLoading: isLoading,
                      onTap: () => ref.read(authProvider.notifier).loginGoogle(),
                    ),
                    const SizedBox(height: 16),
                    // Microsoft Sign In
                    _ProviderLoginButton(
                      label: 'Continue with Microsoft',
                      provider: CloudProvider.microsoft,
                      isLoading: isLoading,
                      onTap: () =>
                          ref.read(authProvider.notifier).loginMicrosoft(),
                    ),
                    const SizedBox(height: 48),
                    // Privacy note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha:0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.brand.withValues(alpha:0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.shield_outlined,
                              size: 18, color: AppColors.brand),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Read-only access only. Your files are never downloaded to this device — only metadata (names, sizes, dates) is scanned.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, Object error) {
    final message =
        error is AppException ? error.message : error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ProviderLoginButton extends StatelessWidget {
  const _ProviderLoginButton({
    required this.label,
    required this.provider,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final CloudProvider provider;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          backgroundColor:
              isDark ? const Color(0xFF1A1A2E) : Colors.white,
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brand,
                ),
              )
            else
              CloudProviderIcon(provider: provider, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
