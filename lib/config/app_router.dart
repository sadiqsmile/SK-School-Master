// config/app_router.dart
import 'package:go_router/go_router.dart';

import 'package:school_app/features/auth/screens/auth_gate.dart';
import 'package:school_app/features/super_admin/screens/super_admin_dashboard.dart';
import 'package:school_app/features/school_admin/dashboard/screens/school_admin_dashboard.dart';
import 'package:school_app/features/school_admin/teachers/screens/teachers_screen.dart';
import 'package:school_app/features/school_admin/students/screens/students_screen.dart';
import 'package:school_app/features/school_admin/students/screens/add_student_screen.dart';
import 'package:school_app/features/school_admin/classes/screens/classes_screen.dart';
import 'package:school_app/features/school_admin/classes/screens/add_class_screen.dart';
import 'package:school_app/features/school_admin/classes/screens/sections_screen.dart';
import 'package:school_app/features/school_admin/attendance/screens/attendance_screen.dart';
import 'package:school_app/features/school_admin/homework/screens/homework_screen.dart';
import 'package:school_app/features/school_admin/fees/screens/fees_screen.dart';
import 'package:school_app/features/parent/screens/parent_login_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(
      path: '/parent-login',
      builder: (context, state) => const ParentLoginScreen(),
    ),
    GoRoute(
      path: '/super-admin',
      builder: (context, state) => const SuperAdminDashboard(),
    ),
    GoRoute(
      path: '/school-admin',
      builder: (context, state) => const SchoolAdminDashboard(),
    ),
    GoRoute(
      path: '/school-admin/teachers',
      builder: (context, state) => const TeachersScreen(),
    ),
    GoRoute(
      path: '/school-admin/students',
      builder: (context, state) => const StudentsScreen(),
    ),
    GoRoute(
      path: '/add-student',
      builder: (context, state) => const AddStudentScreen(),
    ),
    GoRoute(
      path: '/school-admin/classes',
      builder: (context, state) => const ClassesScreen(),
    ),
    GoRoute(
      path: '/classes',
      builder: (context, state) => const ClassesScreen(),
    ),
    GoRoute(
      path: '/add-class',
      builder: (context, state) => const AddClassScreen(),
    ),
    GoRoute(
      path: '/sections/:classId',
      builder: (context, state) {
        final raw = state.pathParameters['classId'] ?? '';
        final classId = Uri.decodeComponent(raw);
        return SectionsScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/school-admin/attendance',
      builder: (context, state) => const AttendanceScreen(),
    ),
    GoRoute(
      path: '/school-admin/homework',
      builder: (context, state) => const HomeworkScreen(),
    ),
    GoRoute(
      path: '/school-admin/fees',
      builder: (context, state) => const FeesScreen(),
    ),
  ],
);
