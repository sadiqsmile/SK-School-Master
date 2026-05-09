import 'package:flutter/material.dart';
import 'package:school_app/features/teacher/screens/teacher_profile_screen.dart';
import 'package:school_app/features/school_admin/teachers/screens/assign_teacher_screen.dart';
import 'package:school_app/features/school_admin/fees/screens/fee_list_screen.dart';
import 'package:school_app/features/school_admin/attendance/screens/attendance_report_screen.dart';
import 'package:school_app/features/school_admin/fees/screens/add_fee_screen.dart';
import 'package:school_app/features/school_admin/attendance/screens/attendance_report_screen.dart';

// config/app_router.dart

import 'package:school_app/features/school_admin/classes/screens/class_students_screen.dart';
import 'package:school_app/features/school_admin/teachers/screens/add_teacher_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app/features/auth/screens/auth_gate.dart';
import 'package:school_app/features/auth/screens/enter_school_screen.dart';
import 'package:school_app/features/auth/screens/school_loader_screen.dart';
import 'package:school_app/features/super_admin/screens/super_admin_dashboard.dart';
import 'package:school_app/features/super_admin/screens/maintenance_screen.dart';
import 'package:school_app/features/school_admin/dashboard/screens/school_admin_dashboard.dart';
import 'package:school_app/features/school_admin/teachers/screens/teachers_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_app/features/school_admin/students/screens/students_screen.dart';
import 'package:school_app/features/school_admin/students/screens/add_student_screen.dart';
import 'package:school_app/features/school_admin/students/screens/edit_student_screen.dart';
import 'package:school_app/features/school_admin/students/screens/student_profile_screen.dart';
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
import 'package:school_app/features/school_admin/attendance/screens/attendance_report_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/exam_reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/fee_reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/reports_screen.dart';
import 'package:school_app/features/school_admin/reports/screens/student_reports_screen.dart';
import 'package:school_app/features/school_admin/analytics/providers/student_risk_providers.dart';
import 'package:school_app/features/school_admin/analytics/screens/school_analytics_screen.dart';
import 'package:school_app/features/school_admin/analytics/screens/student_risk_list_screen.dart';
import 'package:school_app/features/school_admin/notifications/screens/notifications_screen.dart';
import 'package:school_app/features/school_admin/settings/screens/modules_control_screen.dart';
import 'package:school_app/features/school_admin/settings/screens/import_export_screen.dart';
import 'package:school_app/features/import_export/screens/import_subject_screen.dart';
import 'package:school_app/features/school_admin/academic_setup/screens/academic_setup_dashboard.dart';
import 'package:school_app/features/parent/screens/parent_login_screen.dart';
import 'package:school_app/features/teacher/attendance/screens/teacher_attendance_screen.dart';
import 'package:school_app/features/teacher/homework/screens/homework_screen.dart';
import 'package:school_app/features/teacher/screens/teacher_class_home_screen.dart';
import 'package:school_app/features/teacher/dashboard/screens/teacher_dashboard.dart';
import 'package:school_app/features/teacher/screens/teacher_students_screen.dart';
import 'package:school_app/features/teacher/risk/screens/class_risk_screen.dart';

import 'package:school_app/core/rbac/role_guard.dart';
import 'package:school_app/models/school_modules.dart';
import 'package:school_app/models/user_role.dart';
import 'package:school_app/main.dart' show navigatorKey;
import 'package:school_app/features/school_admin/students/screens/restore_students_screen.dart';
import 'package:school_app/features/school_admin/students/screens/bulk_delete_students_screen.dart';
import 'package:school_app/features/school_admin/teachers/screens/archived_teachers_screen.dart';
import 'package:school_app/providers/school_admin_provider.dart' show schoolIdProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/school-loader',

  /// 🔥 ADD THIS BLOCK (VERY IMPORTANT)
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;

    final isAuthRoute =
        state.matchedLocation == '/' ||
        state.matchedLocation == '/enter-school' ||
        state.matchedLocation == '/parent-login';

    final isLoadingRoute = state.matchedLocation == '/school-loader';

    // 🔴 NOT LOGGED IN
    if (user == null) {
      if (isAuthRoute || isLoadingRoute) return null;
      return '/'; // go to AuthGate
    }

    // 🟢 LOGGED IN
    // prevent going back to login
    if (isAuthRoute) {
      return '/school-loader'; // let loader decide role
    }
  
    return null;
  },

 
  routes: [
    GoRoute(
      path: '/class-students',
      builder: (context, state) {
        final data = state.extra as Map;
        return ClassStudentsScreen(
          className: data['className'],
        );
      },
    ),
    
    GoRoute(
      path: '/assign-class',
      builder: (context, state) {
        final teacherId = state.extra as String;
        return AssignTeacherScreen(teacherId: teacherId);
      },
    ),
    GoRoute(
      path: '/fees',
      builder: (context, state) {
        final studentId = state.extra as String;
        return FeeListScreen(studentId: studentId);
      },
    ),
    GoRoute(
      path: '/add-fee',
      builder: (context, state) {
        final studentId = state.extra as String;
        return AddFeeScreen(studentId: studentId);
      },
    ),
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
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RoleGuard(
          title: 'School Admin',
          allowedRoles: [UserRole.admin],
          child: SchoolAdminDashboard(),
        ),
      ),
    ),



    
    GoRoute(
      path: '/school-admin/teachers',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RoleGuard(
          title: 'Teachers',
          allowedRoles: [UserRole.admin],
          requiredModules: [SchoolModuleKey.teachers],
          child: TeachersScreen(),
        ),
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
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RoleGuard(
          title: 'Students',
          allowedRoles: [UserRole.admin],
          requiredModules: [SchoolModuleKey.students],
          child: StudentsScreen(),
        ),
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
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RoleGuard(
          title: 'Classes',
          allowedRoles: [UserRole.admin],
          requiredModules: [SchoolModuleKey.students],
          child: ClassesScreen(),
        ),
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
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RoleGuard(
          title: 'Attendance',
          allowedRoles: [UserRole.admin],
          requiredModules: [SchoolModuleKey.attendance],
          child: AttendanceScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/school-admin/homework',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RoleGuard(
          title: 'Homework',
          allowedRoles: [UserRole.admin],
          requiredModules: [SchoolModuleKey.homework],
          child: HomeworkScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/school-admin/fees',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RoleGuard(
          title: 'Fees',
          allowedRoles: [UserRole.admin],
          requiredModules: [SchoolModuleKey.fees],
          child: FeesScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/school-admin/announcements',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RoleGuard(
          title: 'Announcements',
          allowedRoles: [UserRole.admin],
          requiredModules: [SchoolModuleKey.messages],
          child: AnnouncementsScreen(),
        ),
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
      path: '/school-admin/settings/archived-teachers',
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final schoolIdAsync = ref.watch(schoolIdProvider);
          return schoolIdAsync.when(
            data: (schoolId) => RoleGuard(
              title: 'Archived Teachers',
              allowedRoles: const [UserRole.admin],
              child: ArchivedTeachersScreen(schoolId: schoolId),
            ),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Scaffold(
              body: Center(child: Text('Error: $e')),
            ),
          );
        },
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
        final filter =
            RiskListFilterX.fromRouteKey(key) ?? RiskListFilter.highRisk;
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
        child: AttendanceReportScreen(),
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
      path: '/school-admin/academic-setup',
      builder: (context, state) {
        final schoolId = state.extra as String;
        return RoleGuard(
          title: 'Academic Setup',
          allowedRoles: const [UserRole.admin],
          child: AcademicSetupDashboard(
            schoolId: schoolId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/import-export',
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final schoolIdAsync = ref.watch(schoolIdProvider);
          return schoolIdAsync.when(
            data: (schoolId) => RoleGuard(
              title: 'Imports & Exports',
              allowedRoles: const [UserRole.admin],
              child: ImportExportScreen(schoolId: schoolId),
            ),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Scaffold(
              body: Center(child: Text('Error loading schoolId')),
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: '/import-subjects',
      builder: (context, state) => Consumer(
        builder: (context, ref, _) {
          final schoolIdAsync = ref.watch(schoolIdProvider);
          return schoolIdAsync.when(
            data: (schoolId) => RoleGuard(
              title: 'Import Subjects',
              allowedRoles: const [UserRole.admin],
              child: ImportSubjectScreen(schoolId: schoolId),
            ),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Scaffold(
              body: Center(child: Text('Error loading schoolId')),
            ),
          );
        },
      ),
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
    GoRoute(
      path: '/student-profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return StudentProfileScreen(
          studentId: extra['studentId'] as String,
          schoolId: extra['schoolId'] as String,
        );
      },
    ),
    GoRoute(
      path: '/edit-student',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return EditStudentScreen(
          studentId: data['studentId'],
          data: Map<String, dynamic>.from(data['data']),
        );
      },
    ),
    GoRoute(
      path: '/restore-students',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return RestoreStudentsScreen(schoolId: data['schoolId']);
      },
    ),
    GoRoute(
      path: '/school-admin/students/bulk-delete',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return RoleGuard(
          title: 'Bulk Delete Students',
          allowedRoles: const [UserRole.admin],
          requiredModules: const [SchoolModuleKey.students],
          child: BulkDeleteStudentsScreen(schoolId: data['schoolId']),
        );
      },
    ),
    GoRoute(
      path: '/teacher/profile',
      builder: (context, state) => const TeacherProfileScreen(),
    ),
  ],
);
