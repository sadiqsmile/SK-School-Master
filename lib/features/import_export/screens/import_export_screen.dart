import 'package:flutter/material.dart';

class ImportExportScreen extends StatelessWidget {
  final String schoolId;

  const ImportExportScreen({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F7),
      appBar: AppBar(
        title: const Text('Imports & Exports'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const _SectionTitle('Academic'),

          _IOSButtonTile(
            title: 'Import Subjects',
            subtitle: 'Upload subject Excel',
            icon: Icons.upload_file,
            onTap: () {
              // TODO
            },
          ),

          _IOSButtonTile(
            title: 'Export Subjects',
            subtitle: 'Download subjects Excel',
            icon: Icons.download,
            onTap: () {
              // TODO
            },
          ),

          _IOSButtonTile(
            title: 'Download Subject Template',
            subtitle: 'Excel template format',
            icon: Icons.description,
            onTap: () {
              // TODO
            },
          ),

          _IOSButtonTile(
            title: 'Import Classes',
            subtitle: 'Upload class Excel',
            icon: Icons.school,
            onTap: () {
              // TODO
            },
          ),

          _IOSButtonTile(
            title: 'Export Classes',
            subtitle: 'Download class Excel',
            icon: Icons.download_for_offline,
            onTap: () {
              // TODO
            },
          ),

          const SizedBox(height: 24),

          const _SectionTitle('Students'),

          _IOSButtonTile(
            title: 'Attendance',
            subtitle: 'Import/export attendance',
            icon: Icons.fact_check,
            onTap: () {
              // TODO
            },
          ),

          const SizedBox(height: 24),

          const _SectionTitle('Staff'),

          _IOSButtonTile(
            title: 'Import Teachers',
            subtitle: 'Bulk teacher upload',
            icon: Icons.people,
            onTap: () {
              // TODO
            },
          ),

          const SizedBox(height: 24),

          const _SectionTitle('Examinations'),

          _IOSButtonTile(
            title: 'Exam Modules',
            subtitle: 'Import exams',
            icon: Icons.quiz,
            onTap: () {
              // TODO
            },
          ),

          _IOSButtonTile(
            title: 'Marks',
            subtitle: 'Import/export marks',
            icon: Icons.grading,
            onTap: () {
              // TODO
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
        top: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _IOSButtonTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _IOSButtonTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xffEEF2FF),
          child: Icon(
            icon,
            color: const Color(0xff6366F1),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}
