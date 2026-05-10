import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';



class SubjectImportService {
static Future<void> pickAndImportSubjects({

  required BuildContext context,
  required String schoolId,

}) async {

  final result =
      await FilePicker.platform.pickFiles(

    type: FileType.custom,
    allowedExtensions: ['xlsx'],
  );

  if (result == null) return;

  final file = result.files.first;

  if (file.bytes == null) return;

  final Uint8List bytes =
      file.bytes!;

  final response =
      await importSubjects(

    bytes: bytes,
    schoolId: schoolId,
  );

  if (!context.mounted) return;

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
              CrossAxisAlignment.start,

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

              Navigator.pop(context);
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

  static Future<Map<String, dynamic>>
      importSubjects({

    required Uint8List bytes,

    required String schoolId,
  }) async {

    final excel =
        Excel.decodeBytes(bytes);

    final sheet =
        excel.tables.values.first;

    int imported = 0;

    int duplicates = 0;

    int invalid = 0;

    final firestore =
        FirebaseFirestore.instance;

    for (
      int i = 1;
      i < sheet.rows.length;
      i++
    ) {

      final row = sheet.rows[i];

      // ONLY ONE COLUMN NEEDED NOW

      if (row.isEmpty) {

        invalid++;
        continue;
      }

      final subjectName =
          row[0]
                  ?.value
                  ?.toString()
                  .trim()
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .toUpperCase() ??
              '';

      if (subjectName.isEmpty) {

        invalid++;
        continue;
      }

      /// DUPLICATE CHECK BY NAME

      final existing =
          await firestore
              .collection('schools')
              .doc(schoolId)
              .collection('subjects')
              .where(
                'name',
                isEqualTo:
                    subjectName,
              )
              .limit(1)
              .get();

      if (existing.docs
          .isNotEmpty) {

        duplicates++;
        continue;
      }

      /// SAVE SUBJECT

      await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('subjects')
          .add({

        'name': subjectName,

        'createdAt':
            Timestamp.now(),
      });

      imported++;
    }

    return {

      'imported': imported,

      'duplicates':
          duplicates,

      'invalid': invalid,
    };
  }
}