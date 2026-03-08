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
import 'package:school_app/features/school_admin/analytics/providers/student_risk_providers.dart';
import 'package:school_app/features/school_admin/analytics/screens/school_analytics_screen.dart';
import 'package:school_app/features/school_admin/analytics/screens/student_risk_list_screen.dart';
import 'package:school_app/features/school_admin/notifications/screens/notifications_screen.dart';
import 'package:school_app/features/parent/screens/parent_login_screen.dart';
import 'package:school_app/features/teacher/attendance/screens/teacher_attendance_screen.dart';
import 'package:school_app/features/teacher/homework/screens/homework_screen.dart';
import 'package:school_app/features/teacher/screens/teacher_class_home_screen.dart';
import 'package:school_app/features/teacher/screens/teacher_dashboard.dart';
import 'package:school_app/features/teacher/screens/teacher_students_screen.dart';
import 'package:school_app/features/teacher/risk/screens/class_risk_screen.dart';

import 'package:school_app/core/rbac/role_guard.dart';
import 'package:school_app/models/user_role.dart';

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
      builder: (context, state) => const RoleGuard(
        title: 'Super Admin',
        allowedRoles: [UserRole.superAdmin],
        child: SuperAdminDashboard(),
      ),
    ),
    GoRoute(
      path: '/super-admin/maintenance',
      builder: (context, state) => const RoleGuard(
        title: 'Maintenance',
        allowedRoles: [UserRole.superAdmin],
        child: MaintenanceScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin',
      builder: (context, state) => const RoleGuard(
        title: 'School Admin',
        allowedRoles: [UserRole.admin],
        child: SchoolAdminDashboard(),
      ),
    ),
    GoRoute(
      path: '/school-admin/teachers',
      builder: (context, state) => const RoleGuard(
        title: 'Teachers',
        allowedRoles: [UserRole.admin],
        child: TeachersScreen(),
      ),
    ),
    GoRoute(
      path: '/add-teacher',
      builder: (context, state) => const RoleGuard(
        title: 'Add Teacher',
        allowedRoles: [UserRole.admin],
        child: AddTeacherScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/students',
      builder: (context, state) => const RoleGuard(
        title: 'Students',
        allowedRoles: [UserRole.admin],
        child: StudentsScreen(),
      ),
    ),
    GoRoute(
      path: '/add-student',
      builder: (context, state) => const RoleGuard(
        title: 'Add Student',
        allowedRoles: [UserRole.admin],
        child: AddStudentScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/classes',
      builder: (context, state) => const RoleGuard(
        title: 'Classes',
        allowedRoles: [UserRole.admin],
        child: ClassesScreen(),
      ),
    ),
    GoRoute(
      path: '/classes',
      builder: (context, state) => const RoleGuard(
        title: 'Classes',
        allowedRoles: [UserRole.admin],
        child: ClassesScreen(),
      ),
    ),
    GoRoute(
      path: '/add-class',
      builder: (context, state) => const RoleGuard(
        title: 'Add Class',
        allowedRoles: [UserRole.admin],
        child: AddClassScreen(),
      ),
    ),
    GoRoute(
      path: '/sections/:classId',
      builder: (context, state) {
        final raw = state.pathParameters['classId'] ?? '';
        final classId = Uri.decodeComponent(raw);
        return RoleGuard(
          title: 'Sections',
          allowedRoles: const [UserRole.admin],
          child: SectionsScreen(classId: classId),
        );
      },
    ),
    GoRoute(
      path: '/school-admin/attendance',
      builder: (context, state) => const RoleGuard(
        title: 'Attendance',
        allowedRoles: [UserRole.admin],
        child: AttendanceScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/homework',
      builder: (context, state) => const RoleGuard(
        title: 'Homework',
        allowedRoles: [UserRole.admin],
        child: HomeworkScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/fees',
      builder: (context, state) => const RoleGuard(
        title: 'Fees',
        allowedRoles: [UserRole.admin],
        child: FeesScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/announcements',
      builder: (context, state) => const RoleGuard(
        title: 'Announcements',
        allowedRoles: [UserRole.admin],
        child: AnnouncementsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/exam-types',
      builder: (context, state) => const RoleGuard(
        title: 'Exam Types',
        allowedRoles: [UserRole.admin],
        child: ExamTypesScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/reports',
      builder: (context, state) => const RoleGuard(
        title: 'Reports',
        allowedRoles: [UserRole.admin],
        child: ReportsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/analytics',
      builder: (context, state) => const RoleGuard(
        title: 'Analytics',
        allowedRoles: [UserRole.admin],
        child: SchoolAnalyticsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/analytics/:filter',
      builder: (context, state) {
        final key = (state.pathParameters['filter'] ?? '').trim();
        final filter = RiskListFilterX.fromRouteKey(key) ?? RiskListFilter.highRisk;
        return RoleGuard(
          title: 'Analytics',
          allowedRoles: const [UserRole.admin],
          child: StudentRiskListScreen(filter: filter),
        );
      },
    ),
    GoRoute(
      path: '/school-admin/notifications',
      builder: (context, state) => const RoleGuard(
        title: 'Notifications',
        allowedRoles: [UserRole.admin],
        child: NotificationsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/reports/attendance',
      builder: (context, state) => const RoleGuard(
        title: 'Attendance Reports',
        allowedRoles: [UserRole.admin],
        child: AttendanceReportsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/reports/fees',
      builder: (context, state) => const RoleGuard(
        title: 'Fee Reports',
        allowedRoles: [UserRole.admin],
        child: FeeReportsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/reports/exams',
      builder: (context, state) => const RoleGuard(
        title: 'Exam Reports',
        allowedRoles: [UserRole.admin],
        child: ExamReportsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/reports/students',
      builder: (context, state) => const RoleGuard(
        title: 'Student Reports',
        allowedRoles: [UserRole.admin],
        child: StudentReportsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/reports/students/:studentId',
      builder: (context, state) {
        final raw = state.pathParameters['studentId'] ?? '';
        final studentId = Uri.decodeComponent(raw);
        return RoleGuard(
          title: 'Student Report',
          allowedRoles: const [UserRole.admin],
          child: StudentReportDetailScreen(studentId: studentId),
        );
      },
    ),
    GoRoute(
      path: '/school-admin/academic/promote',
      builder: (context, state) => const RoleGuard(
        title: 'Promote Students',
        allowedRoles: [UserRole.admin],
        child: PromoteStudentsScreen(),
      ),
    ),

    // Teacher routes
    GoRoute(
      path: '/teacher-dashboard',
      builder: (context, state) => const RoleGuard(
        title: 'Teacher Dashboard',
        allowedRoles: [UserRole.teacher],
        child: TeacherDashboard(),
      ),
    ),
    GoRoute(
      path: '/teacher/class/:classId/:sectionId',
      builder: (context, state) {
        final rawClassId = state.pathParameters['classId'] ?? '';
        final rawSectionId = state.pathParameters['sectionId'] ?? '';
        final classId = Uri.decodeComponent(rawClassId);
        final sectionId = Uri.decodeComponent(rawSectionId);
        return RoleGuard(
          title: 'Class',
          allowedRoles: const [UserRole.teacher],
          child: TeacherClassHomeScreen(classId: classId, sectionId: sectionId),
        );
      },
    ),
    GoRoute(
      path: '/teacher/class/:classId/:sectionId/students',
      builder: (context, state) {
        final rawClassId = state.pathParameters['classId'] ?? '';
        final rawSectionId = state.pathParameters['sectionId'] ?? '';
        final classId = Uri.decodeComponent(rawClassId);
        final sectionId = Uri.decodeComponent(rawSectionId);
        return RoleGuard(
          title: 'Students',
          allowedRoles: const [UserRole.teacher],
          child: TeacherStudentsScreen(classId: classId, sectionId: sectionId),
        );
      },
    ),
    GoRoute(
      path: '/teacher/attendance/:classId/:sectionId',
      builder: (context, state) {
        final rawClassId = state.pathParameters['classId'] ?? '';
        final rawSectionId = state.pathParameters['sectionId'] ?? '';
        final classId = Uri.decodeComponent(rawClassId);
        final sectionId = Uri.decodeComponent(rawSectionId);
        return RoleGuard(
          title: 'Attendance',
          allowedRoles: const [UserRole.teacher],
          child: TeacherAttendanceScreen(
            classId: classId,
            sectionId: sectionId,
          ),
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
        return RoleGuard(
          title: 'Homework',
          allowedRoles: const [UserRole.teacher],
          child: TeacherHomeworkScreen(classId: classId, sectionId: sectionId),
        );
      },
    ),
    GoRoute(
      path: '/teacher/risk/:classId/:sectionId',
      builder: (context, state) {
        final rawClassId = state.pathParameters['classId'] ?? '';
        final rawSectionId = state.pathParameters['sectionId'] ?? '';
        final classId = Uri.decodeComponent(rawClassId);
        final sectionId = Uri.decodeComponent(rawSectionId);
        return RoleGuard(
          title: 'Class Risk',
          allowedRoles: const [UserRole.teacher],
          child: ClassRiskScreen(classId: classId, sectionId: sectionId),
        );
      },
    ),
  ],
);

