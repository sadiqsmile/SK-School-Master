// features/auth/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/models/user_role.dart';
import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/core/widgets/app_loader.dart';
import 'package:school_app/providers/school_modules_provider.dart';
import 'package:school_app/providers/core_providers.dart';
import 'package:school_app/providers/platform_status_provider.dart';
import 'package:school_app/core/widgets/maintenance_mode_screen.dart';

import 'login_screen.dart';

import '../../super_admin/screens/super_admin_dashboard.dart';
import '../../school_admin/dashboard/screens/school_admin_dashboard.dart';
import '../../parent/screens/force_change_password_screen.dart';
import '../../parent/screens/parent_shell.dart';
import '../../teacher/screens/teacher_dashboard.dart';
import '../../teacher/screens/teacher_force_change_password_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final maintenanceAsync = ref.watch(maintenanceModeProvider);

    // Fail-open if status doc is missing/unreadable.
    final isMaintenance = maintenanceAsync.asData?.value == true;

    return authState.when(
      loading: () => const Scaffold(body: AppLoader()),

      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),

      data: (user) {
        if (isMaintenance && user == null) {
          return MaintenanceModeScreen(
            onSignIn: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          );
        }

        if (user == null) {
          return const LoginScreen();
        }

        final roleAsync = ref.watch(userRoleProvider);

        return roleAsync.when(
          loading: () => const Scaffold(body: AppLoader()),

          error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),

          data: (role) {
            // Avoid logging roles in production (PII/security). If needed, wrap
            // a log here in kDebugMode.

            // Maintenance mode: block everyone except super admin.
            if (isMaintenance && role != UserRole.superAdmin) {
              return MaintenanceModeScreen(
                onLogout: () => ref.read(authServiceProvider).signOut(),
              );
            }

            if (role == UserRole.superAdmin) {
              return const SuperAdminDashboard();
            }

            if (role == UserRole.admin) {
              return const SchoolAdminDashboard();
            }

            if (role == UserRole.parent) {
              final modulesAsync = ref.watch(schoolModulesProvider);
              return modulesAsync.when(
                loading: () => const Scaffold(body: AppLoader()),
                error: (e, _) => _ModuleBlockedScreen(
                  title: 'Parent Access',
                  message: 'Failed to load school modules: $e',
                  onLogout: () => ref.read(authServiceProvider).signOut(),
                ),
                data: (modules) {
                  if (!modules.parents) {
                    return _ModuleBlockedScreen(
                      title: 'Parent Access Disabled',
                      message:
                          'Parent access is disabled by your school admin. Please contact the school office.',
                      onLogout: () => ref.read(authServiceProvider).signOut(),
                    );
                  }

              final mustChangeAsync = ref.watch(mustChangePasswordProvider);
              return mustChangeAsync.when(
                loading: () => const Scaffold(body: AppLoader()),
                error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
                data: (mustChange) {
                  if (mustChange) {
                    return const ForceChangePasswordScreen();
                  }
                  return const ParentShell();
                },
              );
                },
              );
            }

            if (role == UserRole.teacher) {
              final modulesAsync = ref.watch(schoolModulesProvider);
              return modulesAsync.when(
                loading: () => const Scaffold(body: AppLoader()),
                error: (e, _) => _ModuleBlockedScreen(
                  title: 'Teacher Access',
                  message: 'Failed to load school modules: $e',
                  onLogout: () => ref.read(authServiceProvider).signOut(),
                ),
                data: (modules) {
                  if (!modules.teachers) {
                    return _ModuleBlockedScreen(
                      title: 'Teacher Access Disabled',
                      message:
                          'Teacher access is disabled by your school admin. Please contact the school office.',
                      onLogout: () => ref.read(authServiceProvider).signOut(),
                    );
                  }

              final mustChangeAsync = ref.watch(mustChangePasswordProvider);
              return mustChangeAsync.when(
                loading: () => const Scaffold(body: AppLoader()),
                error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
                data: (mustChange) {
                  if (mustChange) {
                    return const TeacherForceChangePasswordScreen();
                  }
                  return const TeacherDashboard();
                },
              );
                },
              );
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}

class _ModuleBlockedScreen extends StatelessWidget {
  const _ModuleBlockedScreen({
    required this.title,
    required this.message,
    required this.onLogout,
  });

  final String title;
  final String message;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                    const Icon(Icons.block_rounded, size: 44),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
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
                    FilledButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
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
