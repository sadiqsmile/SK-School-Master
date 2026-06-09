import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class TeacherImportService {

  static Future<void> pickAndImportTeachers({

    required BuildContext context,
    required String schoolId,

  }) async {

    final result =
        await FilePicker.platform.pickFiles(

      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) return;

    final file =
        result.files.first;

    if (file.bytes == null) return;

    final response =
        await importTeachers(

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
      importTeachers({

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

      // CHECK IF SL.NO COLUMN EXISTS

final hasSerialNo =
    row[0]
        ?.value
        ?.toString()
        .trim()
        .contains(RegExp(r'^\d+$')) ?? false;

// COLUMN OFFSET

final offset =
    hasSerialNo ? 1 : 0;

// DATA

final name =
    row.length > offset
        ? row[offset]
                ?.value
                ?.toString()
                .trim()
                .toUpperCase() ??
            ''
        : '';

final email =
    row.length > offset + 1
        ? row[offset + 1]
                ?.value
                ?.toString()
                .trim() ??
            ''
        : '';

final phone =
    row.length > offset + 2
        ? row[offset + 2]
                ?.value
                ?.toString()
                .trim() ??
            ''
        : '';

final dob =
    row.length > offset + 3
        ? row[offset + 3]
                ?.value
                ?.toString()
                .trim() ??
            ''
        : '';

final bloodGroup =
    row.length > offset + 4
        ? row[offset + 4]
                ?.value
                ?.toString()
                .trim()
                .toUpperCase() ??
            ''
        : '';

final address =
    row.length > offset + 5
        ? row[offset + 5]
                ?.value
                ?.toString()
                .trim() ??
            ''
        : '';

final aadharNo =
    row.length > offset + 6
        ? row[offset + 6]
                ?.value
                ?.toString()
                .trim() ??
            ''
        : '';

      // DUPLICATE CHECK

      final existing =
          await firestore
              .collection('schools')
              .doc(schoolId)
              .collection('teachers')
              .where(
                'phone',
                isEqualTo: phone,
              )
              .limit(1)
              .get();

      if (existing.docs.isNotEmpty) {

        duplicates++;
        continue;
      }

      // SAVE

      await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('teachers')
          .add({

        'name': name,

        'email': email,

        'phone': phone,

        'dob': dob,

        'bloodGroup': bloodGroup,

        'address': address,

        'aadharNo': aadharNo,

        'role': 'TEACHER',
        
        'photoUrl': '',

        'createdAt': Timestamp.now(),

        'archived': false,
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