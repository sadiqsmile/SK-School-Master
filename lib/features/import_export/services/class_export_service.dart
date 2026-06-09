import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:syncfusion_flutter_xlsio/xlsio.dart'
    as xls;

import '../../school_admin/students/services/template_export_stub.dart'
    if (dart.library.io) '../../school_admin/students/services/template_export_io.dart'
    if (dart.library.html) '../../school_admin/students/services/template_export_web.dart';

class ClassExportService {

  static Future<void>
      exportClasses(
    String schoolId,
  ) async {

    final snapshot =
        await FirebaseFirestore
            .instance
            .collection('schools')
            .doc(schoolId)
            .collection('classes')
            .orderBy('name')
            .get();

    final workbook =
        xls.Workbook();

    final sheet =
        workbook.worksheets[0];

    // HEADERS

    sheet
        .getRangeByIndex(1, 1)
        .setText('SL.NO');

    sheet
        .getRangeByIndex(1, 2)
        .setText(
          'CLASS NAME',
        );

    sheet
        .getRangeByIndex(
          1,
          1,
          1,
          2,
        )
        .cellStyle
        .bold = true;

    // DATA

    for (
      int i = 0;
      i < snapshot.docs.length;
      i++
    ) {

      final data =
          snapshot.docs[i].data();

      sheet
          .getRangeByIndex(
            i + 2,
            1,
          )
          .setNumber(
            (i + 1).toDouble(),
          );

      sheet
          .getRangeByIndex(
            i + 2,
            2,
          )
          .setText(

            (data['name'] ?? '')
                .toString()
                .toUpperCase(),
          );
    }

    final bytes =
        workbook.saveAsStream();

    workbook.dispose();

    await saveExcelFile(
      bytes,
      'classes.xlsx',
    );
  }
}