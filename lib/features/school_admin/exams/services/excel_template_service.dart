import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class ExcelTemplateService {
  Future<void> exportBlankTemplate() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];

    sheet.getRangeByName('A1').setText('Student ID');
    sheet.getRangeByName('B1').setText('Student Name');
    sheet.getRangeByName('C1').setText('Marks');

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/marks_template.xlsx');
    await file.writeAsBytes(bytes);

    await OpenFile.open(file.path);
  }
}
