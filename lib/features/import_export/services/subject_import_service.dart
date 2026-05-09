import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

class SubjectImportService {

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

    for (int i = 1;
        i < sheet.rows.length;
        i++) {

      final row = sheet.rows[i];

      if (row.length < 3) {

        invalid++;
        continue;
      }

     final subjectName =
    row[0]
            ?.value
            ?.toString()
            .trim() ??
        '';

final subjectCode =
    row[1]
            ?.value
            ?.toString()
            .trim() ??
        '';

final groups =
    row[2]
            ?.value
            ?.toString()
            .split(',')
            .map(
              (e) => e.trim(),
            )
            .toList() ??
        [];

      if (subjectName.isEmpty ||
          subjectCode.isEmpty) {

        invalid++;
        continue;
      }

      /// DUPLICATE CHECK

      final existing =
          await firestore
              .collection('schools')
              .doc(schoolId)
              .collection('subjects')
              .where(
                'code',
                isEqualTo:
                    subjectCode,
              )
              .limit(1)
              .get();

      if (existing.docs
          .isNotEmpty) {

        duplicates++;
        continue;
      }

      /// SAVE

      await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('subjects')
          .add({

        'name': subjectName,

        'code': subjectCode,

        'groups': groups,

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