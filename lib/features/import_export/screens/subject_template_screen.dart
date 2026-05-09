import 'package:flutter/material.dart';

import '../services/subject_template_service.dart';

class SubjectTemplateScreen extends StatelessWidget {
  const SubjectTemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        title: const Text('Subject Template'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Center(
        child: ElevatedButton.icon(
          onPressed: () async {

            await SubjectTemplateService.downloadTemplate();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Subject template downloaded',
                ),
              ),
            );
          },

          icon: const Icon(Icons.download),

          label: const Text(
            'Download Subject Template',
          ),

          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }
}