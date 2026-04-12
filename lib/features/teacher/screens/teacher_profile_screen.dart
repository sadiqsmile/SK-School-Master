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

  // 🔥 Add TransformationController
  final TransformationController _controller = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadTransform(); // 🚀 STEP 5: CALL LOAD FUNCTION
  }

  /// 🔥 COMPRESS (MOBILE ONLY)
  Future<File> _compressImage(File file) async {
    try {
      if (kIsWeb) return file;

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

      if (result == null) return file;
      return File(result.path);
    } catch (e) {
      return file;
    }
  }

  /// 🔥 PICK + CROP + COMPRESS
  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);

      final picked = await _picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        final bytes = await picked.readAsBytes();

        /// 🌐 WEB → skip crop, direct preview
        if (kIsWeb) {
          setState(() {
            _webImage = bytes;
          });
          return;
        }

        /// 📱 MOBILE → crop screen
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
      }
    } catch (e) {
      print("ERROR: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🚀 STEP 3: ADD SAVE FUNCTION
  Future<void> _saveTransform() async {
    final matrix = _controller.value;
    final scale = matrix.getMaxScaleOnAxis();
    final offsetX = matrix.row0[3];
    final offsetY = matrix.row1[3];
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'scale': scale,
      'offsetX': offsetX,
      'offsetY': offsetY,
    });
    print("Transform saved");
  }

  // 🚀 STEP 4: LOAD SAVED POSITION
  Future<void> _loadTransform() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null) return;
    final scale = (data['scale'] ?? 1).toDouble();
    final offsetX = (data['offsetX'] ?? 0).toDouble();
    final offsetY = (data['offsetY'] ?? 0).toDouble();
    _controller.value = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(scale);
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
        error: (e, _) => Center(
          child: Text("Error: $e",
              style: const TextStyle(color: Colors.white)),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child:
                  Text("No user", style: TextStyle(color: Colors.white)),
            );
          }

          return Column(
            children: [
              const SizedBox(height: 30),

              /// 🔥 PROFILE IMAGE
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
                        /// 🌐 WEB → interactive alignment
                        child: kIsWeb
                            ? (_webImage != null
                                ? InteractiveViewer(
                                    transformationController: _controller,
                                    panEnabled: true,
                                    scaleEnabled: true,
                                    minScale: 1,
                                    maxScale: 4,
                                    onInteractionEnd: (details) {
                                      _saveTransform(); // 🔥 SAVE AFTER DRAG/ZOOM
                                    },
                                    child: Image.memory(
                                      _webImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.person, size: 50))
                            /// 📱 MOBILE → normal image
                            : (_image != null
                                ? Image.file(
                                    _image!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.person, size: 50)),
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

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {},
                child: const Text("Edit Profile"),
              ),

              const SizedBox(height: 20),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem("Classes", "0"),
                  _StatItem("Students", "0"),
                  _StatItem("Attendance", "0%"),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}