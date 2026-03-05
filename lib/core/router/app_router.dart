// core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/school_admin/screens/school_admin_dashboard.dart';
import '../../features/super_admin/screens/super_admin_dashboard.dart';



final appRouter = GoRouter(
  initialLocation: "/login",

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;

    final loggingIn = state.matchedLocation == "/login";

    if (user == null) {
      return loggingIn ? null : "/login";
    }

    if (user.email == "testadmin@school.com") {
      return "/school-admin";
    }

    return "/super-admin";
  },

  routes: [
    GoRoute(path: "/login", builder: (context, state) => const LoginScreen()),

    GoRoute(
      path: "/school-admin",
      builder: (context, state) => const SchoolAdminDashboard(),
    ),

    GoRoute(
      path: "/super-admin",
      builder: (context, state) => const SuperAdminDashboard(),
    ),
  ],
);
