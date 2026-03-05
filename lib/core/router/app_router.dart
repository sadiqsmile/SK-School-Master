import 'package:go_router/go_router.dart';

import '../../features/auth/screens/auth_gate.dart';
import '../../features/super_admin/screens/super_admin_dashboard.dart';
import '../../features/school_admin/screens/school_admin_dashboard.dart';

final appRouter = GoRouter(
  initialLocation: "/",
  routes: [

    GoRoute(
      path: "/",
      builder: (context, state) => const AuthGate(),
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
);