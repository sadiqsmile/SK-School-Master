import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

class SubjectExportService {
  Future<void> exportSubjects({
    required String schoolId,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('subjects')
        .get();

    final excel = Excel.createExcel();
    final sheet = excel['Subjects'];

    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Code'),
      TextCellValue('Groups'),
    ]);

    for (final doc in snapshot.docs) {
      final data = doc.data();

      sheet.appendRow([
        TextCellValue(data['name'] ?? ''),
        TextCellValue(data['code'] ?? ''),
        TextCellValue(
          List<String>.from(data['groups'] ?? []).join(', '),
        ),
      ]);
    }

    final bytes = excel.encode();

    if (bytes == null) return;

    final Uint8List uint8list = Uint8List.fromList(bytes);
    final blob = html.Blob([uint8list]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'subjects.xlsx')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
