import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../../providers/auth_provider.dart';
import 'crop_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TeacherProfileScreen extends ConsumerStatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  ConsumerState<TeacherProfileScreen> createState() =>
      _TeacherProfileScreenState();
}

class _TeacherProfileScreenState
    extends ConsumerState<TeacherProfileScreen> {
  File? _image;
  Uint8List? _webImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final TransformationController _controller = TransformationController();

  final String schoolId = "ICZVEJTPZoHvGu4jICZ"; // 🔥 keep dynamic later

  // ✅ Upload to Firebase
  Future<String?> _uploadToFirebase(Uint8List bytes, String uid) async {
    try {
      final refStorage = FirebaseStorage.instance
          .ref()
          .child('teacher_profiles')
          .child('$uid.jpg');

      await refStorage.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await refStorage.getDownloadURL();
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // ✅ Save URL (FINAL FIX)
  Future<void> _saveImageUrl(String url, String uid) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('teachers')
          .doc(uid);

      print("🔥 Saving to path:");
      print("schools/$schoolId/teachers/$uid");
      print("URL: $url");

      await docRef.set({
        'photoUrl': url,
      }, SetOptions(merge: true));

      print("✅ Photo URL saved SUCCESSFULLY");

      // TEMP debug: confirm Firestore data
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('teachers')
          .doc(uid)
          .get();
      print("🔥 FIRESTORE DATA: ${doc.data()}");
    } catch (e) {
      print("❌ SAVE ERROR: $e");
    }
  }

  // ✅ Compress
  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 500,
      minHeight: 500,
    );

    return result == null ? file : File(result.path);
  }

  // ✅ Web compression (simple for now)
  Uint8List _compressWeb(Uint8List bytes) {
    return bytes; // simple for now (fast)
  }

  // ✅ Pick Image
  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final user = ref.read(authStateProvider).value;
        if (kIsWeb) {
          setState(() {
            _webImage = bytes;
          });
          // 🚀 STEP 3: UPLOAD TO FIREBASE (web, fixed)
          final compressed = _compressWeb(bytes);
          final url = await _uploadToFirebase(compressed, user!.uid);
          if (url != null) {
            await _saveImageUrl(url, user.uid);
          }
          return;
        }
        final croppedBytes = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CropScreen(imageBytes: bytes),
          ),
        );
        if (croppedBytes == null) return;
        final tempDir = await getTemporaryDirectory();
        final file = File(
            "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg");
        await file.writeAsBytes(croppedBytes);
        final compressed = await _compressImage(file);
        setState(() {
          _image = compressed;
        });
        // 🚀 STEP 3: UPLOAD TO FIREBASE (mobile, fixed)
        final compressedBytes = await compressed.readAsBytes();
        final url = await _uploadToFirebase(compressedBytes, user!.uid);
        if (url != null) {
          await _saveImageUrl(url, user.uid);
        }
      }
    } catch (e) {
      print("ERROR: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.black,
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text("No user", style: TextStyle(color: Colors.white)),
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .collection('teachers')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String? photoUrl;

if (snapshot.hasData && snapshot.data!.exists) {
  final data = snapshot.data!.data() as Map<String, dynamic>?;
  photoUrl = data?['photoUrl'];
}

              ImageProvider? imageProvider;

              if (_webImage != null) {
                imageProvider = MemoryImage(_webImage!);
              } else if (_image != null) {
                imageProvider = FileImage(_image!);
              } else if (photoUrl != null) {
                imageProvider = NetworkImage(photoUrl);
              }

              return Column(
                children: [
                  const SizedBox(height: 30),

                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipOval(
                          child: Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: imageProvider != null
                                ? Image(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.person, size: 50),
                          ),
                        ),

                        if (_isLoading)
                          Container(
                            height: 120,
                            width: 120,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    user.displayName ?? "Teacher",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    user.email ?? "",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}