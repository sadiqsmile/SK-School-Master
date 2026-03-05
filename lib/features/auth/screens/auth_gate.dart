// features/auth/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_state_provider.dart';
import '../providers/user_role_provider.dart';
import 'login_screen.dart';

import '../../super_admin/screens/super_admin_dashboard.dart';
import '../../school_admin/screens/school_admin_dashboard.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final authState = ref.watch(authStateProvider);

    return authState.when(

      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),

      error: (e, _) => Scaffold(
        body: Center(child: Text(e.toString())),
      ),

      data: (user) {

        if (user == null) {
          return const LoginScreen();
        }

        final roleAsync = ref.watch(userRoleProvider);

        return roleAsync.when(

          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),

          error: (e, _) => Scaffold(
            body: Center(child: Text(e.toString())),
          ),

          data: (roleData) {

            if (roleData == null) {
              return const LoginScreen();
            }

            final role = roleData['role'];

            if (role == "superAdmin") {
              return const SuperAdminDashboard();
            }

            if (role == "admin") {
              return const SchoolAdminDashboard();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}