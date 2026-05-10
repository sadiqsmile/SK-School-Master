import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ClassImportService {

  static Future<void>
      pickAndImportClasses({

    required BuildContext context,
    required String schoolId,

  }) async {

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

    final response =
        await importClasses(

      bytes: file.bytes!,
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
                'Invalid: ${response['invalid']}',
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
      importClasses({

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

      final row =
          sheet.rows[i];

      if (row.isEmpty) {

        invalid++;
        continue;
      }

      final className =
          row[0]
                  ?.value
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
              '';

      if (className.isEmpty) {

        invalid++;
        continue;
      }

      final existing =
          await firestore
              .collection('schools')
              .doc(schoolId)
              .collection('classes')
              .where(
                'name',
                isEqualTo:
                    className,
              )
              .limit(1)
              .get();

      if (existing.docs
          .isNotEmpty) {

        duplicates++;
        continue;
      }

      await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .add({

        'name': className,

        'createdAt':
            Timestamp.now(),
      });

      imported++;
    }

    return {

      'imported': imported,
      'duplicates': duplicates,
      'invalid': invalid,
    };
  }
}