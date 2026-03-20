import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



class AddSchoolScreen extends StatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  bool _isReplacingAdmin = false;

  Future<void> _replaceSchoolAdmin({
    required String schoolId,
    required String currentEmail,
  }) async {
    final controller = TextEditingController(text: currentEmail);

    final newEmail = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Replace School Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the new school admin email. This email should already exist in Firebase Auth or be created by your existing flow.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'New Admin Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newEmail == null || newEmail.isEmpty) return;

    setState(() => _isReplacingAdmin = true);

    try {
      await FirebaseFirestore.instance.collection('schools').doc(schoolId).update({
        'adminEmail': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: newEmail);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          await _showErrorDialog(
            'Admin Updated But Reset Email Failed',
            'School admin email was updated in Firestore, but no Firebase Auth user exists for:\n\n$newEmail\n\nCreate the Auth user first, then send reset email again.',
          );
          return;
        } else {
          rethrow;
        }
      }

      await _showSuccessDialog(
        'School Admin Replaced',
        'School admin email updated successfully.\n\nNew admin: $newEmail\n\nA password reset email has also been sent.',
      );
    } on FirebaseAuthException catch (e) {
      await _showErrorDialog(
        'Replace Failed',
        e.message ?? 'Failed while sending reset email.',
      );
    } catch (e) {
      await _showErrorDialog(
        'Replace Failed',
        'Something went wrong while replacing school admin.\n\n$e',
      );
    } finally {
      if (mounted) {
        setState(() => _isReplacingAdmin = false);
      }
    }
  }

  Widget _buildAdminActions({
    required String schoolId,
    required String adminEmail,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Email: $adminEmail',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: _isSendingReset
                  ? null
                  : () => _sendPasswordResetEmail(adminEmail),
              icon: _isSendingReset
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_reset),
              label: Text(_isSendingReset ? 'Sending...' : 'Reset Password'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _isReplacingAdmin
                  ? null
                  : () => _replaceSchoolAdmin(
                        schoolId: schoolId,
                        currentEmail: adminEmail,
                      ),
              icon: _isReplacingAdmin
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz),
              label: Text(_isReplacingAdmin ? 'Updating...' : 'Replace Admin'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isSendingReset = false;

  Future<void> _sendPasswordResetEmail(String email) async {
    setState(() => _isSendingReset = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

      await _showSuccessDialog(
        'Reset Email Sent',
        'A password reset link has been sent to:\n\n$email\n\nThe school admin can use that link to set a new password.',
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send password reset email.';

      if (e.code == 'user-not-found') {
        message =
            'No Firebase Auth user exists for this email.\n\nMake sure the school admin account was created in Firebase Auth first.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else if (e.message != null && e.message!.trim().isNotEmpty) {
        message = e.message!;
      }

      await _showErrorDialog('Reset Failed', message);
    } catch (e) {
      await _showErrorDialog(
        'Reset Failed',
        'Something went wrong while sending reset email.\n\n$e',
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

    Future<void> _showSuccessDialog(String title, String message) async {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    Future<void> _showErrorDialog(String title, String message) async {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  Uint8List? imageBytes;
  String? imageName;

  String? loadingMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  Color startColor = const Color(0xff4facfe);
  Color endColor = const Color(0xff00f2fe);

  bool isSaving = false;

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        imageBytes = bytes;
        imageName = picked.name;
      });
    }
  }

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

  Future<void> _saveSchool() async {
    if (isSaving) return;

    final name = _nameController.text.trim().toUpperCase();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.length != 10 || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields correctly")),
      );
      return;
    }

    setState(() {
      isSaving = true;
      loadingMessage = 'Creating school...';
    });

    String logoUrl = '';
    String logoPath = '';

    try {
      if (imageBytes != null) {
        final ext = (imageName ?? '').toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final ref = FirebaseStorage.instance.ref().child('school_logos').child(fileName);

        await ref.putData(
          imageBytes!,
          SettableMetadata(
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );

        logoUrl = await ref.getDownloadURL();
        logoPath = ref.fullPath;
          if (mounted) {
            setState(() {
              loadingMessage = 'Uploading and creating admin account...';
            });
          }
      }

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('createSchoolWithAdmin');

      final result = await callable.call({
        'name': name,
        'email': email,
        'phone': phone,
        'logo': logoUrl,
        'logoPath': logoPath,
        'themeColorPrimary': _colorToHex(startColor),
        'themeColorSecondary': _colorToHex(endColor),
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      if (!mounted) return;
      setState(() {
        loadingMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'School created ✅\nDefault password: ${data['tempPassword']}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (logoPath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(logoPath).delete();
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
          loadingMessage = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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
            if (isSaving)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xffE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xff66BB6A)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xff2E7D32)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loadingMessage ?? 'Please wait...',
                        style: const TextStyle(
                          color: Color(0xff1B5E20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // ...existing code...
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
                        child: Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                        ),
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
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.color_lens, color: Color(0xff1E3A8A)),
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
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.color_lens, color: Color(0xff1E3A8A)),
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