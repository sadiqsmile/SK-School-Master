import 'package:cloud_functions/cloud_functions.dart';

/// Calls secure backend functions to create/reset teacher logins.
class TeacherAccountService {
  TeacherAccountService({FirebaseFunctions? functions})
  : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  String normalizePhone(String input) => input.replaceAll(RegExp(r'[^0-9]'), '');

  Future<Map<String, dynamic>> createTeacherLogin({
    required String schoolId,
    required String teacherName,
    required String email,
    required String phone,
    String? teacherId,
  }) async {
    final callable = _functions.httpsCallable('createOrResetTeacherAccount');
    final result = await callable.call({
      'schoolId': schoolId,
      'action': 'create',
      'teacherName': teacherName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'teacherId': (teacherId ?? '').trim(),
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> resetTeacherPassword({
    required String schoolId,
    required String teacherName,
    required String email,
    required String phone,
    String? teacherId,
  }) async {
    final callable = _functions.httpsCallable('createOrResetTeacherAccount');
    final result = await callable.call({
      'schoolId': schoolId,
      'action': 'reset',
      'teacherName': teacherName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'teacherId': (teacherId ?? '').trim(),
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
