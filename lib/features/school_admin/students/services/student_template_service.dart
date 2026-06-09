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
  'SL_NO',
   'ROLL_NO',
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

sheet.getRangeByName('A2').setText('1');
sheet.getRangeByName('B2').setText('701');
sheet.getRangeByName('C2').setText('ADM001');
sheet.getRangeByName('D2').setText('RAHUL KUMAR');
sheet.getRangeByName('E2').setText('Class 7');
sheet.getRangeByName('F2').setText('A');
sheet.getRangeByName('G2').setText('DAY');
sheet.getRangeByName('H2').setText('15-06-2013');
sheet.getRangeByName('I2').setText('MALE');
sheet.getRangeByName('J2').setText('O+');
sheet.getRangeByName('K2').setText('NO');
sheet.getRangeByName('L2').setText('YES');

sheet.getRangeByName('M2').setText('ROUTE 1');
sheet.getRangeByName('N2').setText('STOP 1');
sheet.getRangeByName('O2').setText('KA01AB1234');

sheet.getRangeByName('P2').setText('RAMESH KUMAR');
sheet.getRangeByName('Q2').setText('9876543210');
sheet.getRangeByName('R2').setText('SAGAR');
sheet.getRangeByName('S2').setText('2026-27');

sheet.getRangeByName('A3').setText('2');
sheet.getRangeByName('B3').setText('702');
sheet.getRangeByName('C3').setText('ADM002');
sheet.getRangeByName('D3').setText('PRIYA SHARMA');
sheet.getRangeByName('E3').setText('Class 7');
sheet.getRangeByName('F3').setText('A');
sheet.getRangeByName('G3').setText('HOSTEL');
sheet.getRangeByName('H3').setText('20-08-2013');
sheet.getRangeByName('I3').setText('F');
sheet.getRangeByName('J3').setText('B+');
sheet.getRangeByName('K3').setText('NO');
sheet.getRangeByName('L3').setText('NO');

sheet.getRangeByName('P3').setText('SURESH SHARMA');
sheet.getRangeByName('Q3').setText('9876543211');
sheet.getRangeByName('R3').setText('SAGAR');
sheet.getRangeByName('S3').setText('2026-27');



final instructionSheet =
    workbook.worksheets.addWithName(
  'Instructions',
);

instructionSheet.getRangeByName('A1').setText(
  'CLASS: Use exact class names created in the app',
);

instructionSheet.getRangeByName('A2').setText(
  'Examples: Class 1, Class 7, LKG, UKG',
);

instructionSheet.getRangeByName('A3').setText(
  'SECTION: A, B, C',
);

instructionSheet.getRangeByName('A4').setText(
  'DAY/HOSTEL: DAY or HOSTEL',
);

instructionSheet.getRangeByName('A5').setText(
  'GENDER: MALE or FEMALE',
);

instructionSheet.getRangeByName('A6').setText(
  'MESS: YES or NO',
);

instructionSheet.getRangeByName('A7').setText(
  'TRANSPORT: YES or NO',
);

instructionSheet.getRangeByName('A8').setText(
  'Do not modify column headers',
);




    final bytes = workbook.saveAsStream();
    workbook.dispose();

   await saveExcelFile(
  bytes,
  'students_import_template.xlsx',
);
  }

  static Future<void> exportStudentsExcel({
    required List<Map<String, dynamic>> studentsData,
    String fileName = 'Students',
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
     sheet.getRangeByIndex(r + 2, 6).setText( _formatDob(row['dob']),);
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
      '$fileName.xlsx',
    );
  }

  static const _colWidths = {
    'SL NO': 6.0,
    'Name': 25.0,
    'Class': 8.0,
    'Section': 10.0,
    'Hostel/Day': 14.0,
    'D.O.B': 15.0,
    'Blood Group': 14.0,
    'Mess': 10.0,
    'Transport': 12.0,
    'Gender': 10.0,
    'Parent Name': 25.0,
    'Parent Phone': 18.0,
    'Address': 20.0,
    'Academic Year': 16.0,
    'Admission No': 18.0,
  };

  static const _centerCols = {
    'SL NO', 'Class', 'Section', 'Hostel/Day', 'Mess', 'Transport', 'Gender',
  };

  static Future<void> exportCustomExcel({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
    String title = '',
  }) async {
    final workbook = xls.Workbook();
    final sheet = workbook.worksheets[0];
    final colCount = headers.length;

    // ── Row 1: merged title (when provided) ──────────────────────────
    final int headerRow = title.isNotEmpty ? 2 : 1;
    if (title.isNotEmpty) {
      sheet.getRangeByIndex(1, 1, 1, colCount).merge();
      final titleCell = sheet.getRangeByIndex(1, 1);
      titleCell.setText(title);
      titleCell.cellStyle.bold = true;
      titleCell.cellStyle.fontSize = 14;
      titleCell.cellStyle.hAlign = xls.HAlignType.left;
      titleCell.cellStyle.vAlign = xls.VAlignType.center;
      sheet.getRangeByIndex(1, 1).rowHeight = 22;
    }

    // ── Column header row ─────────────────────────────────────────────
    for (int c = 0; c < colCount; c++) {
      final cell = sheet.getRangeByIndex(headerRow, c + 1);
      cell.setText(headers[c]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#D9D9D9';
      cell.cellStyle.hAlign = xls.HAlignType.center;
      cell.cellStyle.vAlign = xls.VAlignType.center;
      cell.cellStyle.borders.all.lineStyle = xls.LineStyle.thin;
    }

    // ── Data rows ─────────────────────────────────────────────────────
    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < rows[r].length; c++) {
        final cell = sheet.getRangeByIndex(headerRow + 1 + r, c + 1);
        final val = rows[r][c];
        if (val is int || val is double) {
          cell.setNumber(val.toDouble());
        } else {
          cell.setText(val.toString());
        }
        final colName = c < headers.length ? headers[c] : '';
        cell.cellStyle.hAlign = _centerCols.contains(colName)
            ? xls.HAlignType.center
            : xls.HAlignType.left;
        cell.cellStyle.vAlign = xls.VAlignType.center;
        cell.cellStyle.borders.all.lineStyle = xls.LineStyle.thin;
      }
    }

    // ── Column widths ─────────────────────────────────────────────────
    for (int c = 0; c < colCount; c++) {
      final w = _colWidths[headers[c]];
      if (w != null) {
        sheet.getRangeByIndex(1, c + 1).columnWidth = w;
      }
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    await saveExcelFile(bytes, '$fileName.xlsx');
  }

static String _formatDob(dynamic value) {
  if (value == null) return '';

  final raw = value.toString().trim();

  try {
    final dt = DateTime.parse(raw);

    return "${dt.day.toString().padLeft(2, '0')}-"
        "${dt.month.toString().padLeft(2, '0')}-"
        "${dt.year}";
  } catch (_) {
    return raw;
  }
}

}