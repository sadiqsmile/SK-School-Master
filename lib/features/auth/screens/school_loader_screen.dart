// features/auth/screens/school_loader_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/utils/school_storage.dart';

class SchoolLoaderScreen extends StatefulWidget {
  const SchoolLoaderScreen({super.key});

  @override
  State<SchoolLoaderScreen> createState() => _SchoolLoaderScreenState();
}

class _SchoolLoaderScreenState extends State<SchoolLoaderScreen> {
  void _goHome() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/');
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSchool();
  }

 Future<void> _loadSchool() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    const hardcodedSuperAdminEmails = <String>{'sadiq.smile@gmail.com'};
    final email = user.email?.trim().toLowerCase();

    if (email != null && hardcodedSuperAdminEmails.contains(email)) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/super-admin');
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data() ?? {};
      final schoolId = (data['schoolId'] ?? '').toString().trim();
      final role = (data['role'] ?? '').toString().trim();

      if (schoolId.isNotEmpty) {
        await SchoolStorage.saveSchoolId(schoolId);
      }

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (role == 'superAdmin') {
          context.go('/super-admin');
        } else if (role == 'admin') {
          context.go('/school-admin');
        } else if (role == 'teacher') {
          context.go('/teacher-dashboard');
        } else {
          context.go('/');
        }
      });
      return;
    } catch (_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/');
      });
      return;
    }
  }

  await SchoolStorage.getSchoolId();

  if (!mounted) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    context.go('/');
  });
}

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
