// services/teacher_account_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Calls secure backend functions to create/reset teacher logins.
class TeacherAccountService {
  TeacherAccountService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  String normalizePhone(String input) =>
      input.replaceAll(RegExp(r'[^0-9]'), '');

  /// Create teacher or mentor login
  Future<Map<String, dynamic>> createTeacherLogin({
    required String schoolId,
    required String teacherName,
    required String email,
    required String phone,
    required String role,
    String? teacherId,
  }) async {
    await FirebaseAuth.instance.currentUser?.getIdToken(true);

    final callable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('createOrResetTeacherAccount');

    final result = await callable.call({
      'schoolId': schoolId,
      'action': 'create',
      'teacherName': teacherName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'teacherId': (teacherId ?? '').trim(),
      'role': role,
    });

    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Reset teacher password
  Future<Map<String, dynamic>> resetTeacherLogin({
    required String schoolId,
    required String teacherName,
    required String email,
    required String phone,
    required String role,
    String? teacherId,
  }) async {
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    final callable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('createOrResetTeacherAccount');

    final result = await callable.call({
      'schoolId': schoolId,
      'action': 'reset',
      'teacherName': teacherName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'teacherId': (teacherId ?? '').trim(),
      'role': role,
    });

    return Map<String, dynamic>.from(result.data as Map);
  }
}
