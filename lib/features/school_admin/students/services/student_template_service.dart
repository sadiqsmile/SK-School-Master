import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;

import 'template_export_stub.dart'
    if (dart.library.io) 'template_export_io.dart'
    if (dart.library.html) 'template_export_web.dart';

class StudentTemplateService {
  static const prefKey = 'student_custom_fields';

  static Future<List<String>> getSavedFields() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(prefKey) ?? [];
  }

  static Future<void> saveFields(List<String> fields) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(prefKey, fields);
  }

  static Future<void> exportBlankTemplate({
    List<String> customFields = const [],
  }) async {
    final workbook = xls.Workbook();
    final sheet = workbook.worksheets[0];

    final headers = [
       'ADMISSION_NO',
  'STUDENT_NAME',
  'CLASS',
  'SECTION',
  'DAY/HOSTEL',
  'DOB',
  'GENDER',
  'BLOOD_GROUP',
  'MESS',
  'TRANSPORT',
  'ROUTE',
  'STOP',
  'VEHICLE_NO',
  'PARENT_NAME',
  'PARENT_PHONE',
  'ADDRESS',
  'ACADEMIC_YEAR',
      ...customFields,
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    sheet.getRangeByIndex(1, 1, 1, headers.length)
        .cellStyle
        .bold = true;

    final bytes = workbook.saveAsStream();
    workbook.dispose();

   await saveExcelFile(
  bytes,
  'students_import_template.xlsx',
);
  }

  static Future<void> exportStudentsExcel({
    required List<Map<String, dynamic>> studentsData,
  }) async {
    final workbook = xls.Workbook();
    final sheet = workbook.worksheets[0];

    final headers = [
      'ADMISSION_NO',
      'STUDENT_NAME',
      'CLASS',
      'SECTION',
      'DAY/HOSTEL',
      'DOB',
      'GENDER',
      'BLOOD_GROUP',
      'MESS',
      'TRANSPORT',
      'ROUTE',
      'STOP',
      'VEHICLE_NO',
      'PARENT_NAME',
      'PARENT_PHONE',
      'ADDRESS',
      'ACADEMIC_YEAR',
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    sheet.getRangeByIndex(1, 1, 1, headers.length).cellStyle.bold = true;

    for (int r = 0; r < studentsData.length; r++) {
      final row = studentsData[r];

      sheet.getRangeByIndex(r + 2, 1).setText((row['admissionNo'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 2).setText((row['name'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 3).setText((row['className'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 4).setText((row['section'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 5).setText((row['type'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 6).setText((row['dob'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 7).setText((row['gender'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 8).setText((row['bloodGroup'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 9).setText((row['mess'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 10).setText((row['transport'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 11).setText((row['route'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 12).setText((row['stop'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 13).setText((row['vehicleNo'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 14).setText((row['parentName'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 15).setText((row['parentPhone'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 16).setText((row['address'] ?? '').toString());
      sheet.getRangeByIndex(r + 2, 17).setText((row['academicYear'] ?? '').toString());
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    await saveExcelFile(
      bytes,
      'students_export.xlsx',
    );
  }
}