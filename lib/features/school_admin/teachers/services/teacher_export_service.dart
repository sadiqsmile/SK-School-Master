import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;

import '../../../import_export/services/file_saver_web.dart';

class TeacherExportService {

  static Future<void> exportTeachers(
    String schoolId,
  ) async {

    final snapshot =
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('teachers')
            .orderBy('name')
            .get();

    final workbook =
        xls.Workbook();

    final sheet =
        workbook.worksheets[0];

    sheet.name = 'Teachers';

    // HEADERS

   sheet.getRangeByName('A1').setText('SL.NO');

sheet.getRangeByName('B1').setText('NAME');

sheet.getRangeByName('C1').setText('EMAIL');

sheet.getRangeByName('D1').setText('PHONE');

sheet.getRangeByName('E1').setText('DOB');

sheet.getRangeByName('F1').setText('BLOOD GROUP');

sheet.getRangeByName('G1').setText('ADDRESS');

sheet.getRangeByName('H1').setText('AADHAR NO');

    // DATA

    for (
      int i = 0;
      i < snapshot.docs.length;
      i++
    ) {

      final data =
          snapshot.docs[i].data();

      final row = i + 2;

      sheet
          .getRangeByName(
            'A$row',
          )
          .setNumber(
            i + 1,
          );

      sheet
          .getRangeByName(
            'B$row',
          )
          .setText(
            (data['name'] ?? '')
                .toString()
                .toUpperCase(),
          );

      sheet
          .getRangeByName(
            'C$row',
          )
          .setText(
            (data['email'] ?? '')
                .toString(),
          );

      
      sheet
          .getRangeByName(
            'D$row',
          )
          .setText(
            (data['phone'] ?? '')
                .toString(),
          );

sheet
    .getRangeByName(
      'E$row',
    )
    .setText(
      (data['dob'] ?? '')
          .toString(),
    );

sheet
    .getRangeByName(
      'F$row',
    )
    .setText(
      (data['bloodGroup'] ?? '')
          .toString(),
    );

sheet
    .getRangeByName(
      'G$row',
    )
    .setText(
      (data['address'] ?? '')
          .toString(),
    );

sheet
    .getRangeByName(
      'H$row',
    )
    .setText(
      (data['aadharNo'] ?? '')
          .toString(),
    );



    }

   for (int i = 1; i <= 8; i++) {

  sheet.autoFitColumn(i);
}

    final List<int> bytes =
        workbook.saveAsStream();

    workbook.dispose();

    await saveExcelFile(
      bytes: Uint8List.fromList(bytes),
      fileName: 'teachers.xlsx',
    );
  }
}