import 'package:cloud_functions/cloud_functions.dart';

/// Calls secure backend functions to create/reset parent logins.
class ParentAccountService {
  ParentAccountService({FirebaseFunctions? functions})
  : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    throw const FormatException('Invalid Cloud Function response');
  }

  String normalizePhone(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String last4OfPhone(String phoneDigits) {
    if (phoneDigits.length < 4) return phoneDigits;
    return phoneDigits.substring(phoneDigits.length - 4);
  }

  Future<({String uid, String? initialPin})> createParentLogin({
    required String schoolId,
    required String phone,
    required String parentName,
    String? studentId,
  }) async {
    final callable = _functions.httpsCallable('createOrResetParentAccount');
    final result = await callable.call({
      'schoolId': schoolId,
      'action': 'create',
      'phone': phone,
      'parentName': parentName.trim().toUpperCase(),
      'studentId': studentId,
    });
    final data = _asMap(result.data);

    final uid = (data['uid'] ?? '').toString();
    final rawPin = (data['initialPin'] ?? '').toString().trim();
    return (uid: uid, initialPin: rawPin.isEmpty ? null : rawPin);
  }

  Future<({String uid, String? initialPin})> resetParentPassword({
    required String schoolId,
    required String phone,
    required String parentName,
    String? studentId,
  }) async {
    final callable = _functions.httpsCallable('createOrResetParentAccount');
    final result = await callable.call({
      'schoolId': schoolId,
      'action': 'reset',
      'phone': phone,
      'parentName': parentName.trim().toUpperCase(),
      'studentId': studentId,
    });
    final data = _asMap(result.data);

    final uid = (data['uid'] ?? '').toString();
    final rawPin = (data['initialPin'] ?? '').toString().trim();
    return (uid: uid, initialPin: rawPin.isEmpty ? null : rawPin);
  }

  Future<String> parentLogin({
    required String phone,
    required String pin,
  }) async {
    final callable = _functions.httpsCallable('parentLogin');
    final result = await callable.call({
      'phone': phone,
      'pin': pin,
    });
    final data = _asMap(result.data);
    return (data['token'] ?? '').toString();
  }

  Future<void> changeParentPin({
    required String newPin,
  }) async {
    final callable = _functions.httpsCallable('changeParentPin');
    await callable.call({'newPin': newPin});
  }
}
