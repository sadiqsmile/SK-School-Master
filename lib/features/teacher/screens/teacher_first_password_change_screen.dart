import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherFirstPasswordChangeScreen extends StatefulWidget {
  const TeacherFirstPasswordChangeScreen({super.key});

  @override
  State<TeacherFirstPasswordChangeScreen> createState() =>
      _TeacherFirstPasswordChangeScreenState();
}

class _TeacherFirstPasswordChangeScreenState
    extends State<TeacherFirstPasswordChangeScreen> {

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool isLoading = false;
  bool obscure1 = true;
  bool obscure2 = true;

  Future<void> _changePassword() async {

    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.length < 6) {
      _show("Password must be at least 6 characters");
      return;
    }

    if (password != confirm) {
      _show("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {

      final user = FirebaseAuth.instance.currentUser!;

      // ✅ Update Firebase Auth Password
      await user.updatePassword(password);

      // ✅ Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        "mustChangePassword": false,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password Updated Successfully ✅"),
          backgroundColor: Colors.green,
        ),
      );

      // ✅ Refresh app
      Navigator.pushReplacementNamed(context, '/');

    } catch (e) {

      _show(e.toString());

    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  color: Colors.black.withOpacity(0.05),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.lock_reset_rounded,
                  size: 64,
                  color: Color(0xff5B5FEF),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Please change your temporary password before continuing.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 28),

                TextField(
                  controller: _passwordController,
                  obscureText: obscure1,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure1
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscure1 = !obscure1);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: _confirmController,
                  obscureText: obscure2,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure2
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscure2 = !obscure2);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff5B5FEF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Update Password",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
