import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/auth/screens/login_screen.dart';
import 'package:school_app/features/mentor/screens/mentor_dashboard_screen.dart';
import 'package:school_app/features/parent/screens/parent_dashboard.dart';
import 'package:school_app/features/school_admin/dashboard/screens/school_admin_dashboard.dart';
import 'package:school_app/features/super_admin/screens/super_admin_dashboard.dart';
import 'package:school_app/features/teacher/dashboard/screens/teacher_dashboard.dart';
import 'package:school_app/providers/current_user_provider.dart';

class RoleBasedRedirectScreen extends ConsumerWidget {
  const RoleBasedRedirectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userDocState = ref.watch(currentUserDocProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        return userDocState.when(
          data: (doc) {
            if (doc == null || !doc.exists) {
              return const Scaffold(
                body: Center(
                  child: Text('User record not found in Firestore'),
                ),
              );
            }

            final userData = doc.data() ?? {};
            final role = (userData['role'] ?? '').toString().trim();
            final status = (userData['status'] ?? '').toString().trim();

            if (status.isNotEmpty && status != 'active') {
              return Scaffold(
                body: Center(
                  child: Text('Your account status is "$status". Contact admin.'),
                ),
              );
            }

            switch (role) {
              case 'superAdmin':
                return const SuperAdminDashboard();

              case 'admin':
                return const SchoolAdminDashboard();

              case 'teacher':
                return const TeacherDashboard();

             case 'parent':
  return ParentDashboard(
    onOpenAnnouncements: () {},
  );

              case 'mentor':
                return const MentorDashboardScreen();

              default:
                return Scaffold(
                  body: Center(
                    child: Text('Unknown role: $role'),
                  ),
                );
            }
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Text('Error loading user: $error'),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Auth error: $error'),
        ),
      ),
    );
  }
}