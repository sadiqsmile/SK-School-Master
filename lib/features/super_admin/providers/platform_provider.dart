import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final platformProvider = StreamProvider<DocumentSnapshot>((ref) {
  return FirebaseFirestore.instance
      .collection('platform')
      .doc('config')
      .snapshots();
});