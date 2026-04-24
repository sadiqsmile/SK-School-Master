import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> saveExcelFile(
  List<int> bytes,
  String fileName,
) async {
  await FilePicker.platform.saveFile(
    dialogTitle: 'Save File',
    fileName: fileName,
    bytes: Uint8List.fromList(bytes),
  );
}