import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUploadService {
  /// Compresses [bytes] to 300×300 at quality 60.
  /// Skips compression when input is already < 100 KB.
  static Future<Uint8List> compress(Uint8List bytes) async {
    if (bytes.length < 100 * 1024) return bytes;
    return await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 300,
      minHeight: 300,
      quality: 60,
    );
  }

  /// Uploads [bytes] to [storagePath] (full path, e.g.
  /// `schools/$schoolId/students/$admissionNo.jpg`) and returns the
  /// download URL.  [onProgress] receives values from 0.0 to 1.0.
  static Future<String> upload({
    required Uint8List bytes,
    required String storagePath,
    Function(double)? onProgress,
  }) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    final uploadTask = ref.putData(bytes);

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          onProgress(event.bytesTransferred / event.totalBytes);
        }
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}