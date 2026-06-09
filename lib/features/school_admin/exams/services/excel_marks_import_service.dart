import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ExcelMarksImportService {
  Future<File?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null) {
      return null;
    }

    return File(result.files.single.path!);
  }

  Future<List<Map<String, dynamic>>> readExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    final rows = sheet?.rows ?? [];

    List<Map<String, dynamic>> students = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      students.add({
        "studentId": row[0]?.value?.toString() ?? '',
        "studentName": row[1]?.value?.toString() ?? '',
        "marks": row[2]?.value?.toString() ?? '',
      });
    }

    return students;
  }
}
