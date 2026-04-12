import 'dart:io';
import 'package:image_cropper/image_cropper.dart';

Future<File?> cropImageMobile(File file) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: file.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
  );

  if (cropped == null) return null;
  return File(cropped.path);
}