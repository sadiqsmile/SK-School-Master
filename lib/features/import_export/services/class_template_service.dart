import 'package:syncfusion_flutter_xlsio/xlsio.dart'
    as xls;

import '../../school_admin/students/services/template_export_stub.dart'
    if (dart.library.io) '../../school_admin/students/services/template_export_io.dart'
    if (dart.library.html) '../../school_admin/students/services/template_export_web.dart';

class ClassTemplateService {

  static Future<void>
      downloadTemplate() async {

    final workbook =
        xls.Workbook();

    final sheet =
        workbook.worksheets[0];

    sheet.getRangeByIndex(
      1,
      1,
    ).setText(
      'CLASS NAME',
    );

    sheet.getRangeByIndex(
      1,
      1,
    ).cellStyle.bold = true;

    final bytes =
        workbook.saveAsStream();

    workbook.dispose();

    await saveExcelFile(
      bytes,
      'class_template.xlsx',
    );
  }
}