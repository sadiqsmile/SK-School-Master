import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class StudentImportService {

    static Future<List<PlatformFile>> pickMultipleImages() async {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );
      if (result == null) return [];
      return result.files;
    }
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
  "rollNo": row[1]?.value?.toString() ?? "",
  "admissionNo": row[2]?.value?.toString() ?? "",
  "name": row[3]?.value?.toString() ?? "",
  "className":
    ((row[4]?.value?.toString().trim() ?? '')
            .startsWith('Class'))
        ? (row[4]?.value?.toString().trim() ?? '')
        : 'Class ${row[4]?.value?.toString().trim() ?? ''}',
  "section": row[5]?.value?.toString() ?? "",
  "type": row[6]?.value?.toString().trim() ?? "",
  "dob": _formatExcelDate(row[7]?.value),
  "gender": row[8]?.value?.toString() ?? "",
  "bloodGroup": row[9]?.value?.toString() ?? "",
  "mess": row[10]?.value?.toString() ?? "",
  "transport": row[11]?.value?.toString() ?? "",
  "route": row[12]?.value?.toString() ?? "",
  "stop": row[13]?.value?.toString() ?? "",
  "vehicleNo": row[14]?.value?.toString() ?? "",
  "parentName": row[15]?.value?.toString() ?? "",
  "parentPhone": row[16]?.value?.toString() ?? "",
  "address": row[17]?.value?.toString() ?? "",
  "academicYear": row[18]?.value?.toString() ?? "",
      });
    }

    return rows;
  }

static String _formatExcelDate(dynamic value) {
  if (value == null) return '';

  final raw = value.toString().trim();

  final number = double.tryParse(raw);

  if (number != null) {
    final date = DateTime(1899, 12, 30)
        .add(Duration(days: number.toInt()));

    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  return raw;
}

}