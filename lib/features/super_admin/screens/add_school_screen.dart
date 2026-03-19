// features/super_admin/screens/add_school_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

class AddSchoolScreen extends StatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  Uint8List? imageBytes;
  String? imageName; // ✅ FIXED

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  Color startColor = const Color(0xff4facfe);
  Color endColor = const Color(0xff00f2fe);

  bool isSaving = false;

  /// 📸 PICK LOGO
  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();

      setState(() {
        imageBytes = bytes;
        imageName = picked.name; // ✅ IMPORTANT
      });
    }
  }

  /// 🎨 COLOR PICKER
  Future<Color?> _pickColor(BuildContext context) async {
    return showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pick Color"),
        content: Wrap(
          children: Colors.primaries.map((c) {
            return GestureDetector(
              onTap: () => Navigator.pop(context, c),
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 30,
                height: 30,
                color: c,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _colorToHex(Color color) {
    final hex = color.value.toRadixString(16).padLeft(8, '0');
    return "#${hex.substring(2)}";
  }

  /// 💾 SAVE SCHOOL (SVG FIXED)
  Future<void> _saveSchool() async {
    if (isSaving) return;

    final name = _nameController.text.trim().toUpperCase();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields correctly")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      String logoUrl = "";

      
if (imageBytes != null) {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

  if (picked == null) return;

  final imageName = picked.name;

  final isSvg = imageName.toLowerCase().endsWith('.svg');

  final fileName =
      "${DateTime.now().millisecondsSinceEpoch}.${isSvg ? 'svg' : 'png'}";

  final ref = FirebaseStorage.instance
      .ref("school_logos/$fileName");

  await ref.putData(
    imageBytes!,
    SettableMetadata(
      contentType: isSvg ? 'image/svg+xml' : 'image/png',
    ),
  );

  logoUrl = await ref.getDownloadURL();
}








      await FirebaseFirestore.instance.collection('schools').add({
        'name': name,
        'email': email,
        'phone': phone,
        'logo': logoUrl,
        'themeColorPrimary': _colorToHex(startColor),
        'themeColorSecondary': _colorToHex(endColor),
        'archived': false,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("School Created Successfully ✅"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Add School"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff1E3A8A),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// LOGO
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageBytes == null
                    ? const Icon(Icons.camera_alt)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(imageBytes!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "School Name"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Admin Email"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Admin Mobile Number",
              ),
            ),

            const SizedBox(height: 20),

            /// 🎨 COLOR BOX
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey.shade200),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Column(
                children: [

                  const Center(
                    child: Text(
                      "Create Color Theme",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E3A8A),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final c = await _pickColor(context);
                            if (c != null) setState(() => startColor = c);
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.color_lens,
                                    color: Color(0xff1E3A8A)),
                                const SizedBox(width: 8),
                                const Text("Color 1"),
                                const SizedBox(width: 10),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: startColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final c = await _pickColor(context);
                            if (c != null) setState(() => endColor = c);
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.color_lens,
                                    color: Color(0xff1E3A8A)),
                                const SizedBox(width: 8),
                                const Text("Color 2"),
                                const SizedBox(width: 10),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: endColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// BUTTON
            GestureDetector(
              onTap: isSaving ? null : _saveSchool,
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffA8E063), Color(0xff56AB2F)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Create School",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}