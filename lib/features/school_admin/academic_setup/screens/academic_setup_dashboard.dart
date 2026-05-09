import 'package:flutter/material.dart';

import 'classes_setup_screen.dart';
import 'subjects_screen.dart';
import '../../../school_admin/settings/screens/import_export_screen.dart';

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
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.8,
        children: [
          _buildSetupCard(
            title: 'Subjects',
            subtitle: 'Manage centralized subjects',
            icon: Icons.menu_book_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectsScreen(schoolId: schoolId),
              ),
            ),
          ),
          _buildSetupCard(
            title: 'Classes & Sections',
            subtitle: 'Configure classes and sections',
            icon: Icons.school_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClassesSetupScreen(schoolId: schoolId),
              ),
            ),
          ),
          _buildSetupCard(
            title: 'Academic Periods',
            subtitle: 'Manage academic periods',
            icon: Icons.access_time_rounded,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon')),
            ),
          ),
          _buildSetupCard(
            title: 'Group Timings',
            subtitle: 'Configure group timings',
            icon: Icons.schedule_rounded,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon')),
            ),
          ),
          _buildSetupCard(
            title: 'Examinations',
            subtitle: 'Configure exam structure',
            icon: Icons.fact_check_rounded,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon')),
            ),
          ),
          _buildSetupCard(
            title: 'Imports & Exports',
            subtitle: 'Bulk upload and templates',
            icon: Icons.upload_file_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImportExportScreen(schoolId: schoolId),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xffF3F4F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xffEEF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xff5B5FEF), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
