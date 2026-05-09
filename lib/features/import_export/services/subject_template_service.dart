import 'dart:typed_data';
import 'dart:html' as html;

import 'package:excel/excel.dart';

class SubjectTemplateService {

  static Future<void> downloadTemplate() async {

    final excel = Excel.createExcel();

    final sheet = excel['Subjects'];

    /// HEADER

    sheet.appendRow([
      TextCellValue('Subject Name'),
      TextCellValue('Subject Code'),
      TextCellValue('Groups'),
    ]);

    /// SAMPLE DATA

    sheet.appendRow([
      TextCellValue('Kannada'),
      TextCellValue('KAN01'),
      TextCellValue('Primary,Middle'),
    ]);

    sheet.appendRow([
      TextCellValue('English'),
      TextCellValue('ENG01'),
      TextCellValue('Primary,Middle,High'),
    ]);

    sheet.appendRow([
      TextCellValue('Mathematics'),
      TextCellValue('MAT01'),
      TextCellValue('Middle,High'),
    ]);

    final bytes = excel.encode();

    if (bytes == null) return;

    final data = Uint8List.fromList(bytes);

    final blob = html.Blob([data]);

    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'subject_template.xlsx',
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}