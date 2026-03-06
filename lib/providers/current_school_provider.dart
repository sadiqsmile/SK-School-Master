// providers/current_school_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final currentSchoolProvider =
    FutureProvider<DocumentSnapshot<Map<String, dynamic>>>((ref) async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final schoolId = userDoc.data()?['schoolId'];

      if (schoolId == null) {
        throw Exception("School ID not found");
      }

      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .get();

      return schoolDoc;
    });
