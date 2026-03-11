// config/app_router.dart
import 'package:go_router/go_router.dart';

import 'package:school_app/features/auth/screens/auth_gate.dart';
import 'package:school_app/features/auth/screens/enter_school_screen.dart';
import 'package:school_app/features/auth/screens/school_loader_screen.dart';
import 'package:school_app/features/super_admin/screens/super_admin_dashboard.dart';
import 'package:school_app/features/super_admin/screens/maintenance_screen.dart';
import 'package:school_app/features/super_admin/screens/backup_restore_screen.dart';
import 'package:school_app/features/super_admin/screens/google_sheets_sync_screen.dart';
import 'package:school_app/features/school_admin/dashboard/screens/school_admin_dashboard.dart';
import 'package:school_app/features/school_admin/data_tools/screens/data_tools_screen.dart';
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
import 'package:school_app/features/school_admin/exams/screens/marks_card_templates_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/attendance_reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/exam_reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/fee_reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/student_reports_screen.dart';
import 'package:school_app/features/school_admin/analytics/providers/student_risk_providers.dart';
import 'package:school_app/features/school_admin/analytics/screens/school_analytics_screen.dart';
import 'package:school_app/features/school_admin/analytics/screens/student_risk_list_screen.dart';
import 'package:school_app/features/school_admin/notifications/screens/notifications_screen.dart';
import 'package:school_app/features/school_admin/settings/screens/modules_control_screen.dart';
import 'package:school_app/features/school_admin/settings/screens/branding_screen.dart';
import 'package:school_app/features/parent/screens/parent_login_screen.dart';
import 'package:school_app/features/teacher/attendance/screens/teacher_attendance_screen.dart';
import 'package:school_app/features/teacher/homework/screens/homework_screen.dart';
import 'package:school_app/features/teacher/screens/teacher_class_home_screen.dart';
import 'package:school_app/features/teacher/screens/teacher_dashboard.dart';
import 'package:school_app/features/teacher/screens/teacher_students_screen.dart';
import 'package:school_app/features/teacher/risk/screens/class_risk_screen.dart';

import 'package:school_app/core/rbac/role_guard.dart';
import 'package:school_app/models/school_modules.dart';
import 'package:school_app/models/user_role.dart';

final appRouter = GoRouter(
  initialLocation: '/',
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
      path: '/super-admin/backup-restore',
      builder: (context, state) => const RoleGuard(
        title: 'Backup & Restore',
        allowedRoles: [UserRole.superAdmin],
        child: BackupRestoreScreen(),
      ),
    ),
    GoRoute(
      path: '/super-admin/google-sheets',
      builder: (context, state) => const RoleGuard(
        title: 'Google Sheets Sync',
        allowedRoles: [UserRole.superAdmin],
        child: GoogleSheetsSyncScreen(),
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
      path: '/school-admin/data-tools',
      builder: (context, state) => const RoleGuard(
        title: 'Data Tools',
        allowedRoles: [UserRole.admin],
        child: SchoolAdminDataToolsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/teachers',
      builder: (context, state) => const RoleGuard(
        title: 'Teachers',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.teachers],
        child: TeachersScreen(),
      ),
    ),
    GoRoute(
      path: '/add-teacher',
      builder: (context, state) => const RoleGuard(
        title: 'Add Teacher',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.teachers],
        child: AddTeacherScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/students',
      builder: (context, state) => const RoleGuard(
        title: 'Students',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.students],
        child: StudentsScreen(),
      ),
    ),
    GoRoute(
      path: '/add-student',
      builder: (context, state) => const RoleGuard(
        title: 'Add Student',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.students],
        child: AddStudentScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/classes',
      builder: (context, state) => const RoleGuard(
        title: 'Classes',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.students],
        child: ClassesScreen(),
      ),
    ),
    GoRoute(
      path: '/classes',
      builder: (context, state) => const RoleGuard(
        title: 'Classes',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.students],
        child: ClassesScreen(),
      ),
    ),
    GoRoute(
      path: '/add-class',
      builder: (context, state) => const RoleGuard(
        title: 'Add Class',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.students],
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
          requiredModules: const [SchoolModuleKey.students],
          child: SectionsScreen(classId: classId),
        );
      },
    ),
    GoRoute(
      path: '/school-admin/attendance',
      builder: (context, state) => const RoleGuard(
        title: 'Attendance',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.attendance],
        child: AttendanceScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/homework',
      builder: (context, state) => const RoleGuard(
        title: 'Homework',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.homework],
        child: HomeworkScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/fees',
      builder: (context, state) => const RoleGuard(
        title: 'Fees',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.fees],
        child: FeesScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/announcements',
      builder: (context, state) => const RoleGuard(
        title: 'Announcements',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.messages],
        child: AnnouncementsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/exam-types',
      builder: (context, state) => const RoleGuard(
        title: 'Exam Types',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.exams],
        child: ExamTypesScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/marks-card-templates',
      builder: (context, state) => const RoleGuard(
        title: 'Marks Card Templates',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.exams],
        child: MarksCardTemplatesScreen(),
      ),
    ),

    GoRoute(
      path: '/school-admin/settings/modules',
      builder: (context, state) => const RoleGuard(
        title: 'Module Control',
        allowedRoles: [UserRole.admin],
        child: ModulesControlScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/settings/branding',
      builder: (context, state) => const RoleGuard(
        title: 'Branding',
        allowedRoles: [UserRole.admin],
        child: BrandingScreen(),
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
        requiredModules: [SchoolModuleKey.messages],
        child: NotificationsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/reports/attendance',
      builder: (context, state) => const RoleGuard(
        title: 'Attendance Reports',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.attendance],
        child: AttendanceReportsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/reports/fees',
      builder: (context, state) => const RoleGuard(
        title: 'Fee Reports',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.fees],
        child: FeeReportsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/reports/exams',
      builder: (context, state) => const RoleGuard(
        title: 'Exam Reports',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.exams],
        child: ExamReportsScreen(),
      ),
    ),
    GoRoute(
      path: '/school-admin/reports/students',
      builder: (context, state) => const RoleGuard(
        title: 'Student Reports',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.students],
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
          requiredModules: const [SchoolModuleKey.students],
          child: StudentReportDetailScreen(studentId: studentId),
        );
      },
    ),
    GoRoute(
      path: '/school-admin/academic/promote',
      builder: (context, state) => const RoleGuard(
        title: 'Promote Students',
        allowedRoles: [UserRole.admin],
        requiredModules: [SchoolModuleKey.students],
        child: PromoteStudentsScreen(),
      ),
    ),

    // Teacher routes
    GoRoute(
      path: '/teacher-dashboard',
      builder: (context, state) => const RoleGuard(
        title: 'Teacher Dashboard',
        allowedRoles: [UserRole.teacher],
        requiredModules: [SchoolModuleKey.teachers],
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
          requiredModules: const [SchoolModuleKey.teachers],
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
          requiredModules: const [SchoolModuleKey.students],
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
          requiredModules: const [SchoolModuleKey.attendance],
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
          requiredModules: const [SchoolModuleKey.homework],
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

