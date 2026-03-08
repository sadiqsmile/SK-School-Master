import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/widgets/app_loader.dart';
import 'package:school_app/models/school_modules.dart';
import 'package:school_app/models/user_role.dart';
import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/core_providers.dart';
import 'package:school_app/providers/school_modules_provider.dart';

/// A lightweight route guard to ensure users can only access screens allowed
/// for their role.
///
/// This does not replace Firestore security rules (those remain the source of
/// truth), but it keeps the UI clean and prevents accidental URL-based access.
class RoleGuard extends ConsumerWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.title,
    this.requiredModules,
  });

  final List<UserRole> allowedRoles;
  final Widget child;
  final String? title;
  final List<SchoolModuleKey>? requiredModules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    // If auth state is still resolving, block navigation.
    if (authAsync.isLoading) {
      return const Scaffold(body: AppLoader());
    }

    final user = authAsync.value;
    if (user == null) {
      // Not signed in. Send them to the AuthGate.
      // Using microtask to avoid setState during build.
      Future.microtask(() {
        if (context.mounted) context.go('/');
      });
      return const Scaffold(body: AppLoader());
    }

    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      loading: () => const Scaffold(body: AppLoader()),
      error: (e, _) => _UnauthorizedScreen(
        title: title,
        message: 'Failed to read your role: $e',
        onGoHome: () => context.go('/'),
        onLogout: () => ref.read(authServiceProvider).signOut(),
      ),
      data: (role) {
        if (allowedRoles.contains(role)) {
          final req = requiredModules;
          if (req == null || req.isEmpty) {
            return child;
          }

          // Module gating only applies for school-scoped roles.
          if (role == UserRole.superAdmin) {
            return child;
          }

          final modulesAsync = ref.watch(schoolModulesProvider);
          return modulesAsync.when(
            loading: () => const Scaffold(body: AppLoader()),
            error: (e, _) => _UnauthorizedScreen(
              title: title,
              message: 'Failed to load school modules: $e',
              onGoHome: () => context.go('/'),
              onLogout: () => ref.read(authServiceProvider).signOut(),
            ),
            data: (modules) {
              final allEnabled = req.every(modules.isEnabled);
              if (allEnabled) {
                return child;
              }

              final disabled = req.where((m) => !modules.isEnabled(m)).toList(growable: false);
              final names = disabled.map((m) => m.label).join(', ');
              return _UnauthorizedScreen(
                title: title,
                message:
                    'This feature is disabled by your school admin (${names.isEmpty ? 'module OFF' : names}).',
                onGoHome: () => context.go('/'),
                onLogout: () => ref.read(authServiceProvider).signOut(),
              );
            },
          );
        }

        return _UnauthorizedScreen(
          title: title,
          message: 'This screen is not available for your account role ($role).',
          onGoHome: () => context.go('/'),
          onLogout: () => ref.read(authServiceProvider).signOut(),
        );
      },
    );
  }
}

class _UnauthorizedScreen extends StatelessWidget {
  const _UnauthorizedScreen({
    required this.message,
    required this.onGoHome,
    required this.onLogout,
    this.title,
  });

  final String? title;
  final String message;
  final VoidCallback onGoHome;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = title ?? 'Not Authorized';

    return Scaffold(
      appBar: AppBar(title: Text(t)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 44),
                    const SizedBox(height: 10),
                    Text(
                      t,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.black54, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: onGoHome,
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Go Home'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onLogout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Logout'),
                        ),
                      ],
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
}
