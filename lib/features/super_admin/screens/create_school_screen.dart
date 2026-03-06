// features/super_admin/screens/create_school_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/services/firestore_service.dart';

class CreateSchoolScreen extends StatefulWidget {
  const CreateSchoolScreen({super.key});

  @override
  State<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends State<CreateSchoolScreen> {
  final _schoolName = TextEditingController(text: 'Test School 2');
  final _adminEmail = TextEditingController(text: 'testadmin2@school.com');
  final _adminPassword = TextEditingController(text: '12345678');
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _schoolName.dispose();
    _adminEmail.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final schoolName = _schoolName.text.trim();
    final adminEmail = _adminEmail.text.trim();
    final adminPassword = _adminPassword.text.trim();

    if (schoolName.isEmpty || adminEmail.isEmpty || adminPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirestoreService(FirebaseFirestore.instance).createSchoolWithAdmin(
        schoolName: schoolName,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        themeColor: '#1976D2',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School created successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating school: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C896);
    const darkGreen = Color(0xFF00A876);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryGreen, darkGreen],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.add_business_rounded, color: darkGreen),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create New School',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _schoolName,
              enabled: !_saving,
              decoration: _modernInputDecoration(
                label: 'School Name',
                hint: 'Enter school name',
                icon: Icons.school_rounded,
                primaryColor: darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adminEmail,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              decoration: _modernInputDecoration(
                label: 'Admin Email',
                hint: 'name@example.com',
                icon: Icons.email_rounded,
                primaryColor: darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adminPassword,
              enabled: !_saving,
              obscureText: _obscurePassword,
              decoration:
                  _modernInputDecoration(
                    label: 'Admin Password',
                    hint: 'Minimum 8 characters',
                    icon: Icons.lock_rounded,
                    primaryColor: darkGreen,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.add_circle_outline_rounded),
                label: Text(
                  _saving ? 'Creating...' : 'Create School',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required Color primaryColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.8),
      ),
    );
  }
}
