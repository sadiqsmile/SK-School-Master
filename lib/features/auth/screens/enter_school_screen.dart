// features/auth/screens/enter_school_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/utils/school_storage.dart';

class EnterSchoolScreen extends StatefulWidget {
  const EnterSchoolScreen({super.key});

  @override
  State<EnterSchoolScreen> createState() => _EnterSchoolScreenState();
}

class _EnterSchoolScreenState extends State<EnterSchoolScreen> {
  final controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> saveSchool() async {
    final schoolId = controller.text.trim();

    setState(() {
      _error = null;
    });

    if (schoolId.isEmpty) {
      setState(() {
        _error = 'Please enter your School ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Optional safety: validate school exists.
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .get();

      if (!schoolDoc.exists) {
        setState(() {
          _error = 'Invalid School ID. Please check and try again.';
          _isLoading = false;
        });
        return;
      }

      await SchoolStorage.saveSchoolId(schoolId);

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      setState(() {
        _error = 'Failed to save School ID. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F3D66), Color(0xFF196D89), Color(0xFFE5EEF6)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x1A0B2F4A)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33092A42),
                      blurRadius: 28,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: Color(0xFF2D6079),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter School ID',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Color(0xFF0F2D45),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Use the unique ID shared by your school admin to continue securely.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF4A687C),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: controller,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => saveSchool(),
                          decoration: InputDecoration(
                            hintText: 'e.g. sch_2026_main',
                            labelText: 'School ID',
                            errorText: _error,
                            prefixIcon: const Icon(Icons.school_outlined),
                            filled: true,
                            fillColor: const Color(0xFFF3F8FC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFBBD0DF),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFBBD0DF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF1A7194),
                                width: 1.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : saveSchool,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E5F83),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tip: Your School Admin can provide the School ID.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF607D8F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
