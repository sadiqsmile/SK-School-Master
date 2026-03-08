// config/app_router.dart
import 'package:go_router/go_router.dart';

import 'package:school_app/features/auth/screens/auth_gate.dart';
import 'package:school_app/features/auth/screens/enter_school_screen.dart';
import 'package:school_app/features/auth/screens/school_loader_screen.dart';
import 'package:school_app/features/super_admin/screens/super_admin_dashboard.dart';
import 'package:school_app/features/super_admin/screens/maintenance_screen.dart';
import 'package:school_app/features/school_admin/dashboard/screens/school_admin_dashboard.dart';
import 'package:school_app/features/school_admin/teachers/screens/teachers_screen.dart';
import 'package:school_app/features/school_admin/teachers/screens/add_teacher_screen.dart';
import 'package:school_app/features/school_admin/students/screens/students_screen.dart';
import 'package:school_app/features/school_admin/students/screens/add_student_screen.dart';
import 'package:school_app/features/school_admin/classes/screens/classes_screen.dart';
import 'package:school_app/features/school_admin/classes/screens/add_class_screen.dart';
import 'package:school_app/features/school_admin/classes/screens/sections_screen.dart';
import 'package:school_app/features/school_admin/attendance/screens/attendance_screen.dart';
import 'package:school_app/features/school_admin/academic/screens/promote_students_screen.dart';
import 'package:school_app/features/school_admin/homework/screens/homework_screen.dart';
import 'package:school_app/features/school_admin/fees/screens/fees_screen.dart';
import 'package:school_app/features/school_admin/announcements/screens/announcements_screen.dart';
import 'package:school_app/features/school_admin/exams/screens/exam_types_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/attendance_reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/exam_reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/fee_reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/student_reports_screen.dart';
import 'package:school_app/features/parent/screens/parent_login_screen.dart';
import 'package:school_app/features/teacher/attendance/screens/teacher_attendance_screen.dart';
import 'package:school_app/features/teacher/homework/screens/homework_screen.dart';
import 'package:school_app/features/teacher/screens/teacher_class_home_screen.dart';
import 'package:school_app/features/teacher/screens/teacher_dashboard.dart';
import 'package:school_app/features/teacher/screens/teacher_students_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/school-loader',
  routes: [
    GoRoute(
      path: '/school-loader',
      builder: (context, state) => const SchoolLoaderScreen(),
    ),
    GoRoute(
      path: '/enter-school',
      builder: (context, state) => const EnterSchoolScreen(),
    ),
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
      path: '/super-admin/maintenance',
      builder: (context, state) => const MaintenanceScreen(),
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
      path: '/add-teacher',
      builder: (context, state) => const AddTeacherScreen(),
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
    GoRoute(
      path: '/school-admin/announcements',
      builder: (context, state) => const AnnouncementsScreen(),
    ),
    GoRoute(
      path: '/school-admin/exam-types',
      builder: (context, state) => const ExamTypesScreen(),
    ),
    GoRoute(
      path: '/school-admin/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/school-admin/reports/attendance',
      builder: (context, state) => const AttendanceReportsScreen(),
    ),
    GoRoute(
      path: '/school-admin/reports/fees',
      builder: (context, state) => const FeeReportsScreen(),
    ),
    GoRoute(
      path: '/school-admin/reports/exams',
      builder: (context, state) => const ExamReportsScreen(),
    ),
    GoRoute(
      path: '/school-admin/reports/students',
      builder: (context, state) => const StudentReportsScreen(),
    ),
    GoRoute(
      path: '/school-admin/reports/students/:studentId',
      builder: (context, state) {
        final raw = state.pathParameters['studentId'] ?? '';
        final studentId = Uri.decodeComponent(raw);
        return StudentReportDetailScreen(studentId: studentId);
      },
    ),
    GoRoute(
      path: '/school-admin/academic/promote',
      builder: (context, state) => const PromoteStudentsScreen(),
    ),

    // Teacher routes
    GoRoute(
      path: '/teacher-dashboard',
      builder: (context, state) => const TeacherDashboard(),
    ),
    GoRoute(
      path: '/teacher/class/:classId/:sectionId',
      builder: (context, state) {
        final rawClassId = state.pathParameters['classId'] ?? '';
        final rawSectionId = state.pathParameters['sectionId'] ?? '';
        final classId = Uri.decodeComponent(rawClassId);
        final sectionId = Uri.decodeComponent(rawSectionId);
        return TeacherClassHomeScreen(classId: classId, sectionId: sectionId);
      },
    ),
    GoRoute(
      path: '/teacher/class/:classId/:sectionId/students',
      builder: (context, state) {
        final rawClassId = state.pathParameters['classId'] ?? '';
        final rawSectionId = state.pathParameters['sectionId'] ?? '';
        final classId = Uri.decodeComponent(rawClassId);
        final sectionId = Uri.decodeComponent(rawSectionId);
        return TeacherStudentsScreen(classId: classId, sectionId: sectionId);
      },
    ),
    GoRoute(
      path: '/teacher/attendance/:classId/:sectionId',
      builder: (context, state) {
        final rawClassId = state.pathParameters['classId'] ?? '';
        final rawSectionId = state.pathParameters['sectionId'] ?? '';
        final classId = Uri.decodeComponent(rawClassId);
        final sectionId = Uri.decodeComponent(rawSectionId);
        return TeacherAttendanceScreen(
          classId: classId,
          sectionId: sectionId,
        );
      },
    ),
    GoRoute(
      path: '/teacher/homework/:classId/:sectionId',
      builder: (context, state) {
        final rawClassId = state.pathParameters['classId'] ?? '';
        final rawSectionId = state.pathParameters['sectionId'] ?? '';
        final classId = Uri.decodeComponent(rawClassId);
        final sectionId = Uri.decodeComponent(rawSectionId);
        return TeacherHomeworkScreen(classId: classId, sectionId: sectionId);
      },
    ),
  ],
);

