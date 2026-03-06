// features/auth/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/models/user_role.dart';
import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/core/widgets/app_loader.dart';

import 'login_screen.dart';

import '../../super_admin/screens/super_admin_dashboard.dart';
import '../../school_admin/dashboard/screens/school_admin_dashboard.dart';
import '../../parent/screens/force_change_password_screen.dart';
import '../../parent/screens/parent_dashboard_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: AppLoader()),

      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),

      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        final roleAsync = ref.watch(userRoleProvider);

        return roleAsync.when(
          loading: () => const Scaffold(body: AppLoader()),

          error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),

          data: (role) {
            debugPrint('CURRENT USER ROLE = $role');

            if (role == UserRole.superAdmin) {
              return const SuperAdminDashboard();
            }

            if (role == UserRole.admin) {
              return const SchoolAdminDashboard();
            }

            if (role == UserRole.parent) {
              final mustChangeAsync = ref.watch(mustChangePasswordProvider);
              return mustChangeAsync.when(
                loading: () => const Scaffold(body: AppLoader()),
                error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
                data: (mustChange) {
                  if (mustChange) {
                    return const ForceChangePasswordScreen();
                  }
                  return const ParentDashboardScreen();
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
