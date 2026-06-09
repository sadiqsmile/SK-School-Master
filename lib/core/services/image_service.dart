import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {

  static final ImagePicker _picker =
      ImagePicker();

  // PICK + COMPRESS
  static Future<Uint8List?>
      pickCropCompressImage() async {

    final picked =
        await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null) return null;

    Uint8List bytes;

    // WEB → NO CROPPER
    if (kIsWeb) {

      bytes =
          await picked.readAsBytes();

    } else {

      final cropped =
          await ImageCropper()
              .cropImage(
        sourcePath: picked.path,

        compressFormat:
            ImageCompressFormat.jpg,

        compressQuality: 80,

        aspectRatio:
            const CropAspectRatio(
          ratioX: 3,
          ratioY: 4,
        ),

        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
                'Crop Image',
            lockAspectRatio:
                true,
          ),

          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (cropped == null) {
        return null;
      }

      bytes =
          await cropped.readAsBytes();
    }

    final compressed =
        await FlutterImageCompress
            .compressWithList(
      bytes,

     quality: 55,

minWidth: 300,
minHeight: 300,

      format:
          CompressFormat.jpeg,
    );

    return Uint8List.fromList(
      compressed,
    );
  }

  // UPLOAD IMAGE
  static Future<String> uploadImage({
    required String schoolId,
    required String module,
    required String type,
    required String fileName,
    required Uint8List bytes,
  }) async {

    final ref = FirebaseStorage
        .instance
        .ref()
        .child(
      'schools/$schoolId/$module/$type/$fileName.jpg',
    );

    await ref.putData(
      bytes,

      SettableMetadata(
        contentType:
            'image/jpeg',
      ),
    );

    return await ref.getDownloadURL();
  }

  // SAVE LOCAL CACHE
  static Future<File>
      saveLocalImage({
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {

    final dir =
        await getApplicationDocumentsDirectory();

    final localDir = Directory(
      '${dir.path}/$folder',
    );

    if (!await localDir.exists()) {
      await localDir.create(
        recursive: true,
      );
    }

    final file = File(
      '${localDir.path}/$fileName.jpg',
    );

    await file.writeAsBytes(bytes);

    return file;
  }

  // LOAD LOCAL CACHE
  static Future<File?>
      getLocalImage({
    required String folder,
    required String fileName,
  }) async {

    final dir =
        await getApplicationDocumentsDirectory();

    final file = File(
      '${dir.path}/$folder/$fileName.jpg',
    );

    if (await file.exists()) {
      return file;
    }

    return null;
  }
}