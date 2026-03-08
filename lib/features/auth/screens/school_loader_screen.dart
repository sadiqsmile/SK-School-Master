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
  @override
  void initState() {
    super.initState();
    _loadSchool();
  }

  Future<void> _loadSchool() async {
    // If a user is already signed in, we can sync the school id from their
    // user profile (and let AuthGate route them).
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Keep super admin unblocked (super admin may not have a user doc).
      const hardcodedSuperAdminEmails = <String>{'sadiq.smile@gmail.com'};
      final email = user.email?.trim().toLowerCase();
      if (email != null && hardcodedSuperAdminEmails.contains(email)) {
        if (!mounted) return;
        context.go('/');
        return;
      }

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = userDoc.data();
        final schoolId = (data?['schoolId'] ?? '').toString().trim();
        if (schoolId.isNotEmpty) {
          await SchoolStorage.saveSchoolId(schoolId);
        }
      } catch (_) {
        // Ignore and let AuthGate handle any unknown state.
      }

      if (!mounted) return;
      context.go('/');
      return;
    }

    final schoolId = await SchoolStorage.getSchoolId();
    if (!mounted) return;

    if (schoolId == null || schoolId.trim().isEmpty) {
      context.go('/enter-school');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
