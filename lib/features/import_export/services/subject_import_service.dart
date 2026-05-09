import 'dart:typed_data';

import 'package:excel/excel.dart';

class SubjectImportService {
  Future<List<Map<String, dynamic>>> parseExcel(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;

    final List<Map<String, dynamic>> subjects = [];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      if (row.isEmpty) continue;

      subjects.add({
        "name": row[0]?.value?.toString() ?? '',
        "code": row[1]?.value?.toString() ?? '',
        "groups": row[2]
                ?.value
                ?.toString()
                .split(',')
                .map((e) => e.trim())
                .toList() ??
            [],
      });
    }

    return subjects;
  }
}
