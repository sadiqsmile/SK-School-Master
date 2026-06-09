import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ImportExportDashboardScreen extends StatelessWidget {
  final String schoolId;

  const ImportExportDashboardScreen({
    super.key,
    required this.schoolId,
  });

  Widget buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 14,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final crossAxisCount = width > 1400
        ? 4
        : width > 900
            ? 3
            : width > 600
                ? 2
                : 1;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Imports & Exports',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= ACADEMIC =================

            sectionTitle('Academic'),

            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 3.2,
              children: [

                buildCard(
                  context: context,
                  title: 'Import Subjects',
                  subtitle: 'Upload subject Excel',
                  icon: Icons.upload_file_rounded,
                  colors: const [
                    Color(0xff4F46E5),
                    Color(0xff2563EB),
                  ],
                  onTap: () {
                    context.push('/import-subjects');
                  },
                ),

                buildCard(
                  context: context,
                  title: 'Export Subjects',
                  subtitle: 'Download subjects',
                  icon: Icons.download_rounded,
                  colors: const [
                    Color(0xff10B981),
                    Color(0xff059669),
                  ],
                  onTap: () {
                    context.push('/export-subjects');
                  },
                ),

                buildCard(
                  context: context,
                  title: 'Subject Template',
                  subtitle: 'Download template',
                  icon: Icons.description_rounded,
                  colors: const [
                    Color(0xffF59E0B),
                    Color(0xffD97706),
                  ],
                  onTap: () {
                    context.push('/subject-template');
                  },
                ),

                buildCard(
                  context: context,
                  title: 'Import Classes',
                  subtitle: 'Upload class Excel',
                  icon: Icons.book_rounded,
                  colors: const [
                    Color(0xff7C3AED),
                    Color(0xff9333EA),
                  ],
                  onTap: () {
                    context.push('/import-classes');
                  },
                ),

                buildCard(
                  context: context,
                  title: 'Export Classes',
                  subtitle: 'Download class Excel',
                  icon: Icons.download_for_offline_rounded,
                  colors: const [
                    Color(0xff16A34A),
                    Color(0xff15803D),
                  ],
                  onTap: () {
                    context.push('/export-classes');
                  },
                ),

                buildCard(
                  context: context,
                  title: 'Timetable',
                  subtitle: 'Import timetable Excel',
                  icon: Icons.view_week_rounded,
                  colors: const [
                    Color(0xffDB2777),
                    Color(0xffBE185D),
                  ],
                  onTap: () {
                    context.push('/timetable-import-export');
                  },
                ),
              ],
            ),

            /// ================= STUDENTS =================

            sectionTitle('Students'),

            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 3.2,
              children: [

                
                buildCard(
                  context: context,
                  title: 'Attendance',
                  subtitle: 'Import & export attendance',
                  icon: Icons.fact_check_rounded,
                  colors: const [
                    Color(0xff3B82F6),
                    Color(0xff1D4ED8),
                  ],
                  onTap: () {
                    context.push('/attendance-import-export');
                  },
                ),
              ],
            ),

            /// ================= STAFF =================

            sectionTitle('Staff'),

            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 3.2,
              children: [

                buildCard(
                  context: context,
                  title: 'Import Teachers',
                  subtitle: 'Bulk teacher upload',
                  icon: Icons.person_add_alt_1_rounded,
                  colors: const [
                    Color(0xffEF4444),
                    Color(0xffB91C1C),
                  ],
                  onTap: () {
                    context.push('/import-teachers');
                  },
                ),
              ],
            ),

            /// ================= EXAMS =================

            sectionTitle('Examinations'),

            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 3.2,
              children: [

                buildCard(
                  context: context,
                  title: 'Exam Modules',
                  subtitle: 'Import exams',
                  icon: Icons.assignment_rounded,
                  colors: const [
                    Color(0xff4F46E5),
                    Color(0xff7C3AED),
                  ],
                  onTap: () {
                    context.push('/exam-import-export');
                  },
                ),

                buildCard(
                  context: context,
                  title: 'Marks',
                  subtitle: 'Import/export marks',
                  icon: Icons.list_alt_rounded,
                  colors: const [
                    Color(0xffF97316),
                    Color(0xffEA580C),
                  ],
                  onTap: () {
                    context.push('/marks-import-export');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}