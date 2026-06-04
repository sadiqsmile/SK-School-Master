import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final sectionsProvider =
    FutureProvider.family<QuerySnapshot, String>(
  (ref, classId) async {

    return FirebaseFirestore.instance
        .collection('dummy')
        .get();
  },
);