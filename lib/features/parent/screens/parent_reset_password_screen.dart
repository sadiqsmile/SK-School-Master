import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'parent_dashboard_screen.dart';

class ParentResetPasswordScreen extends StatefulWidget {
  final String schoolId;
  final String parentId;
  final Map<String, dynamic> parentData;

  const ParentResetPasswordScreen({
    super.key,
    required this.schoolId,
    required this.parentId,
    required this.parentData,
  });

  @override
  State<ParentResetPasswordScreen> createState() =>
      _ParentResetPasswordScreenState();
}

class _ParentResetPasswordScreenState
    extends State<ParentResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;
  bool isLoading = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (password.length < 4) {
      _showMessage("Password too short");
      return;
    }

    if (password != confirm) {
      _showMessage("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('parents')
          .doc(widget.parentId)
          .update({
        "password": password,
        "mustChangePassword": false,
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ParentDashboardScreen(
            schoolId: widget.schoolId,
            parentId: widget.parentId,
            parentData: widget.parentData,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      _showMessage("Failed to update password");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: const BoxDecoration(
                        color: Color(0xffEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 42,
                        color: Color(0xff5B5FEF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Create a new password for your account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure1,
                    decoration:
                        _inputDecoration("New Password", Icons.lock).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure1 = !obscure1),
                        icon: Icon(
                            obscure1 ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: confirmController,
                    obscureText: obscure2,
                    decoration:
                        _inputDecoration("Confirm Password", Icons.lock_outline)
                            .copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure2 = !obscure2),
                        icon: Icon(
                            obscure2 ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff5B5FEF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isLoading ? null : _resetPassword,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              "Save Password",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xffF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
