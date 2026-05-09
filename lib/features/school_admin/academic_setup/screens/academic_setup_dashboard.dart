import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/premium_dashboard_card.dart';
import 'classes_setup_screen.dart';
import 'subjects_screen.dart';

class AcademicSetupDashboard extends StatelessWidget {
  final String schoolId;

  const AcademicSetupDashboard({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Academic Setup'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 3.8,
          children: [
            PremiumDashboardCard(
              title: 'Subjects',
              subtitle: 'Manage centralized subjects',
              icon: Icons.menu_book_rounded,
              colors: const [Color(0xff6366F1), Color(0xff8B5CF6)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectsScreen(schoolId: schoolId),
                ),
              ),
            ),
            PremiumDashboardCard(
              title: 'Classes',
              subtitle: 'Manage classes & sections',
              icon: Icons.school_rounded,
              colors: const [Color(0xff10B981), Color(0xff059669)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassesSetupScreen(schoolId: schoolId),
                ),
              ),
            ),
            PremiumDashboardCard(
              title: 'Academic Periods',
              subtitle: 'Configure terms & exams',
              icon: Icons.calendar_month,
              colors: const [Color(0xffF59E0B), Color(0xffD97706)],
              onTap: () {},
            ),
            PremiumDashboardCard(
              title: 'Group Timings',
              subtitle: 'Manage school timings',
              icon: Icons.access_time,
              colors: const [Color(0xffEC4899), Color(0xffBE185D)],
              onTap: () {},
            ),
            PremiumDashboardCard(
              title: 'Imports & Exports',
              subtitle: 'Excel import & export',
              icon: Icons.import_export_rounded,
              colors: const [Color(0xff06B6D4), Color(0xff0891B2)],
              onTap: () {
                context.push('/import-export');
              },
            ),
            PremiumDashboardCard(
              title: 'Examinations',
              subtitle: 'Manage exams & marks',
              icon: Icons.fact_check_rounded,
              colors: const [Color(0xffEF4444), Color(0xffDC2626)],
              onTap: () {
                context.push('/exam-dashboard');
              },
            ),
            PremiumDashboardCard(
              title: 'Timetable',
              subtitle: 'Class & teacher timetable',
              icon: Icons.calendar_view_week,
              colors: const [Color(0xff8B5CF6), Color(0xff7C3AED)],
              onTap: () {
                context.push('/timetable');
              },
            ),
          ],
        ),
      ),
    );
  }

}