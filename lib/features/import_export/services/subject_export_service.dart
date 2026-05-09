import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

class SubjectExportService {

  static Future<void> exportSubjects({
    required String schoolId,
  }) async {

    final firestore =
        FirebaseFirestore.instance;

    final snapshot =
        await firestore
            .collection('schools')
            .doc(schoolId)
            .collection('subjects')
            .get();

    final excel =
        Excel.createExcel();

    final sheet =
        excel['Subjects'];

    /// HEADER

    sheet.appendRow([
      TextCellValue('Subject Name'),
      TextCellValue('Subject Code'),
      TextCellValue('Groups'),
    ]);

    /// DATA

    for (final doc in snapshot.docs) {

      final data = doc.data();

      final groups =
          List<String>.from(
            data['groups'] ?? [],
          ).join(', ');

      sheet.appendRow([

        TextCellValue(
          data['name'] ?? '',
        ),

        TextCellValue(
          data['code'] ?? '',
        ),

        TextCellValue(groups),
      ]);
    }

    final bytes =
        excel.encode();

    if (bytes == null) return;

    final data =
        Uint8List.fromList(bytes);

    final blob =
        html.Blob([data]);

    final url =
        html.Url
            .createObjectUrlFromBlob(
                blob);

    final anchor =
        html.AnchorElement(
      href: url,
    )
      ..setAttribute(
        'download',
        'subjects_export.xlsx',
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}