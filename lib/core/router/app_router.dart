import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_state_provider.dart';
import '../../features/auth/providers/user_role_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/school_admin/screens/school_admin_dashboard.dart';
import '../../features/super_admin/screens/super_admin_dashboard.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final roleState = ref.watch(userRoleProvider);

  return GoRouter(
    initialLocation: "/super-admin",
    routes: [
      GoRoute(
        path: "/login",
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: "/super-admin",
        builder: (context, state) => const SuperAdminDashboard(),
      ),
      GoRoute(
        path: "/school-admin",
        builder: (context, state) => const SchoolAdminDashboard(),
      ),
    ],
    redirect: (context, state) {
      final user = authState.value;

      if (user == null) {
        // Avoid redirect loops when already on the login page.
        if (state.matchedLocation == "/login") return null;
        return "/login";
      }

      final roleData = roleState.value;

      if (roleData == null) return null;

      final role = roleData['role'];

      if (role == "superAdmin") {
        return "/super-admin";
      }

      if (role == "admin") {
        return "/school-admin";
      }

      return null;
    },
  );
});