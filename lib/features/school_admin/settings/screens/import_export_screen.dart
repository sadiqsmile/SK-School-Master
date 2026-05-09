import 'package:flutter/material.dart';

import '../../../../features/import_export/screens/import_subject_screen.dart';
import '../../../../features/import_export/services/subject_export_service.dart';
import '../../../../features/import_export/services/subject_template_service.dart';

class ImportExportScreen extends StatelessWidget {
  final String schoolId;

  const ImportExportScreen({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imports & Exports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 2.3,
          children: [
            _buildCard(
              title: 'Import Subjects',
              subtitle: 'Upload subject Excel',
              icon: Icons.upload_file,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImportSubjectScreen(schoolId: schoolId),
                ),
              ),
            ),
            _buildCard(
              title: 'Export Subjects',
              subtitle: 'Download subjects',
              icon: Icons.download,
              onTap: () async {
                await SubjectExportService().exportSubjects(
                  schoolId: schoolId,
                );
              },
            ),
            _buildCard(
              title: 'Subject Template',
              subtitle: 'Download Excel format',
              icon: Icons.file_download,
              onTap: () async {
                await SubjectTemplateService().downloadTemplate();
              },
            ),
            _buildCard(
              title: 'Import Students',
              subtitle: 'Bulk student upload',
              icon: Icons.groups,
              onTap: () {},
            ),
            _buildCard(
              title: 'Export Students',
              subtitle: 'Download student list',
              icon: Icons.file_download,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffEEF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: const Color(0xff5B5FEF),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
