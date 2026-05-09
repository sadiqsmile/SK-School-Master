import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/subject_import_service.dart';

class ImportSubjectScreen extends StatefulWidget {
  final String schoolId;

  const ImportSubjectScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<ImportSubjectScreen>
      createState() =>
          _ImportSubjectScreenState();
}

class _ImportSubjectScreenState
    extends State<ImportSubjectScreen> {

  bool loading = false;

  Future<void> pickExcel() async {

    final result =
        await FilePicker.platform
            .pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) return;

    final file =
        result.files.first;

    if (file.bytes == null) return;

    final Uint8List bytes =
        file.bytes!;

    setState(() {
      loading = true;
    });

    final response =
        await SubjectImportService
            .importSubjects(

      bytes: bytes,

      schoolId:
          widget.schoolId,
    );

    setState(() {
      loading = false;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {

        return AlertDialog(

          title: const Text(
            'Import Completed',
          ),

          content: Column(

            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [

              Text(
                'Imported: ${response['imported']}',
              ),

              Text(
                'Duplicates: ${response['duplicates']}',
              ),

              Text(
                'Invalid Rows: ${response['invalid']}',
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child: const Text(
                'OK',
              ),
            ),
          ],
        );
      },
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
          'Import Subjects',
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
                        pickExcel,

                    icon: const Icon(
                      Icons.upload_file,
                    ),

                    label: const Text(
                      'Select Excel File',
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