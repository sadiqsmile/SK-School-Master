import 'dart:html' as html;
import 'dart:typed_data';

import 'package:excel/excel.dart';

class SubjectTemplateService {
  Future<void> downloadTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Subjects'];

    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Code'),
      TextCellValue('Groups'),
    ]);

    sheet.appendRow([
      TextCellValue('Kannada'),
      TextCellValue('KAN01'),
      TextCellValue('Primary,Middle'),
    ]);

    final bytes = excel.encode();

    if (bytes == null) return;

    final uint8list = Uint8List.fromList(bytes);
    final blob = html.Blob([uint8list]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'subject_template.xlsx')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
