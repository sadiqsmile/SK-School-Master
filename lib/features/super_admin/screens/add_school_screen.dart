// features/super_admin/screens/add_school_screen.dart
// features/super_admin/screens/add_school_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AddSchoolScreen extends StatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  File? _logoFile;

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
      setState(() => _logoFile = File(picked.path));
    }
  }

  /// 🎨 COLOR PICKER
  Future<Color?> _pickColor(BuildContext context) async {
    return showDialog<Color>(
      context: context,
      builder: (_) {
        return AlertDialog(
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
        );
      },
    );
  }

  /// 🔥 SAFE HEX CONVERTER
  String _colorToHex(Color color) {
    final hex = color.value.toRadixString(16).padLeft(8, '0');
    return "#${hex.substring(2)}"; // remove alpha
  }

  /// 💾 SAVE SCHOOL
  Future<void> _saveSchool() async {
    if (isSaving) return;

    final name = _nameController.text.trim().toUpperCase();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    /// 🔥 VALIDATION
    if (name.isEmpty || email.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields correctly")),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid email")));
      return;
    }

    setState(() => isSaving = true);

    try {
      /// 📸 UPLOAD LOGO
      String logoUrl = "";
      if (_logoFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("school_logos")
            .child("${DateTime.now().millisecondsSinceEpoch}.png");

        await ref.putFile(_logoFile!);
        logoUrl = await ref.getDownloadURL();
      }

      /// 🔥 CLOUD FUNCTION
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('createSchoolWithAdmin');

      final result = await callable.call({
        'schoolName': name,
        'email': email,
        'phone': phone,
        'themeColorPrimary': _colorToHex(startColor),
        'themeColorSecondary': _colorToHex(endColor),
        'logo': logoUrl,
      });

      final password = result.data['password'] ?? '';
      final schoolId = result.data['schoolId'] ?? '';

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("School Created ✅\nID: $schoolId\nPassword: $password"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }

    if (mounted) setState(() => isSaving = false);
  }

  Widget _colorBox(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
      ),
    );
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
            /// 📸 LOGO
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _logoFile == null
                    ? const Icon(Icons.camera_alt)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_logoFile!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🏫 NAME
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: "School Name"),
            ),

            const SizedBox(height: 12),

            /// 📧 EMAIL
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Admin Email"),
            ),

            const SizedBox(height: 12),

            /// 📱 PHONE
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Admin Mobile Number",
              ),
            ),

            const SizedBox(height: 20),

            /// 🎨 COLORS
            Row(
              children: [
                Expanded(
                  child: _colorBox(startColor, () async {
                    final c = await _pickColor(context);
                    if (c != null) setState(() => startColor = c);
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _colorBox(endColor, () async {
                    final c = await _pickColor(context);
                    if (c != null) setState(() => endColor = c);
                  }),
                ),
              ],
            ),

            const SizedBox(height: 25),

            /// 💾 SAVE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveSchool,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create School"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
