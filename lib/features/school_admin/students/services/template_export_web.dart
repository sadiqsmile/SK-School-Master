import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveExcelFile(
  List<int> bytes,
  String fileName,
) async {
  final data = Uint8List.fromList(bytes);

  final blob = html.Blob([data]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
}

Future<void> savePdfFile(
  Uint8List bytes,
  String fileName,
) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
}