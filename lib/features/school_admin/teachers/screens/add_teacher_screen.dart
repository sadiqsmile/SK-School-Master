import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String selectedRole = "teacher";
  bool isSaving = false;

  Future<void> _save() async {
    final name = _nameController.text.trim();
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
      // 🔐 Default password (first 6 chars of email)
      final password =
          email.length >= 6 ? email.substring(0, 6) : "123456";

      // 🔥 Get current admin BEFORE creating teacher
      final currentAdmin = FirebaseAuth.instance.currentUser!;
      final adminUid = currentAdmin.uid;

      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminUid)
          .get();

      final schoolId = adminDoc['schoolId'];

      // 🔥 CREATE TEACHER AUTH USER
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final teacherUid = userCredential.user!.uid;

      // 🔥 SAVE IN USERS COLLECTION
      await FirebaseFirestore.instance
          .collection('users')
          .doc(teacherUid)
          .set({
        "role": selectedRole,
        "schoolId": schoolId,
      });

      // 🔥 SAVE IN TEACHERS COLLECTION
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('teachers')
          .doc(teacherUid)
          .set({
        "name": name,
        "email": email,
        "phone": phone,
        "role": selectedRole,
        "assignmentKeys": [],
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${selectedRole == "mentor" ? "Mentor" : "Teacher"} Added Successfully ✅",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (mounted) setState(() => isSaving = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    TextInputType? type,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Add Staff"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff1E3A8A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input(controller: _nameController, label: "Name"),
            const SizedBox(height: 12),

            _input(
              controller: _emailController,
              label: "Email",
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            _input(
              controller: _phoneController,
              label: "Phone",
              type: TextInputType.number,
              maxLength: 10,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: "Role"),
              items: const [
                DropdownMenuItem(value: "teacher", child: Text("Teacher")),
                DropdownMenuItem(value: "mentor", child: Text("Mentor")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedRole = value);
                }
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6366F1),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}