import 'package:flutter/material.dart';

import '../services/subject_export_service.dart';

class ExportSubjectScreen extends StatefulWidget {

  final String schoolId;

  const ExportSubjectScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<ExportSubjectScreen>
      createState() =>
          _ExportSubjectScreenState();
}

class _ExportSubjectScreenState
    extends State<ExportSubjectScreen> {

  bool loading = false;

  Future<void> exportSubjects() async {

    setState(() {
      loading = true;
    });

    await SubjectExportService
        .exportSubjects(
      schoolId:
          widget.schoolId,
    );

    setState(() {
      loading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(
        content: Text(
          'Subjects exported successfully',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(
        0xffF8FAFC,
      ),

      appBar: AppBar(
        title: const Text(
          'Export Subjects',
        ),
        backgroundColor:
            Colors.white,
        elevation: 0,
      ),

      body: Center(

        child:
            loading

                ? const CircularProgressIndicator()

                : ElevatedButton.icon(

                    onPressed:
                        exportSubjects,

                    icon: const Icon(
                      Icons.download,
                    ),

                    label: const Text(
                      'Export Subjects',
                    ),

                    style:
                        ElevatedButton.styleFrom(

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 18,
                      ),
                    ),
                  ),
      ),
    );
  }
}