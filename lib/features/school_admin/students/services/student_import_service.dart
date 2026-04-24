import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class StudentImportService {
  static Future<List<Map<String, dynamic>>> pickAndReadExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final file = result.files.first;

    Uint8List? bytes = file.bytes;

    if (bytes == null) return [];

    final excel = Excel.decodeBytes(bytes);

    final sheet = excel.tables.values.first;

    if (sheet == null) return [];

    final rows = <Map<String, dynamic>>[];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];

      if (row.isEmpty) continue;

      rows.add({
        "admissionNo": row[0]?.value?.toString() ?? "",
  "name": row[1]?.value?.toString() ?? "",
  "className": row[2]?.value?.toString() ?? "",
  "section": row[3]?.value?.toString() ?? "",
  "dayHostel": row[4]?.value?.toString() ?? "",
  "dob": row[5]?.value?.toString() ?? "",
  "gender": row[6]?.value?.toString() ?? "",
  "bloodGroup": row[7]?.value?.toString() ?? "",
  "mess": row[8]?.value?.toString() ?? "",
  "transport": row[9]?.value?.toString() ?? "",
  "route": row[10]?.value?.toString() ?? "",
  "stop": row[11]?.value?.toString() ?? "",
  "vehicleNo": row[12]?.value?.toString() ?? "",
  "parentName": row[13]?.value?.toString() ?? "",
  "parentPhone": row[14]?.value?.toString() ?? "",
  "address": row[15]?.value?.toString() ?? "",
  "academicYear": row[16]?.value?.toString() ?? "",
      });
    }

    return rows;
  }
}