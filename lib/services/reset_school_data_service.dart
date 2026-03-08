import 'package:cloud_functions/cloud_functions.dart';

class ResetSchoolDataService {
  ResetSchoolDataService({FirebaseFunctions? functions})
  : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> preview({
    String? schoolId,
    List<String>? schoolIds,
    bool allSchools = false,
    required String confirmPhrase,
    required bool backupConfirmed,
    required bool deleteAuthUsers,
  }) async {
    final callable = _functions.httpsCallable('resetSchoolData');
    final result = await callable.call({
      'schoolId': (schoolId ?? '').trim(),
      'schoolIds': (schoolIds ?? const <String>[]).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'allSchools': allSchools,
      'confirmPhrase': confirmPhrase.trim(),
      'backupConfirmed': backupConfirmed,
      'deleteAuthUsers': deleteAuthUsers,
      'execute': false,
    });

    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> execute({
    String? schoolId,
    List<String>? schoolIds,
    bool allSchools = false,
    required String backupId,
    required String confirmPhrase,
    required bool backupConfirmed,
    required bool deleteAuthUsers,
  }) async {
    final callable = _functions.httpsCallable('resetSchoolData');
    final result = await callable.call({
      'schoolId': (schoolId ?? '').trim(),
      'schoolIds': (schoolIds ?? const <String>[]).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'allSchools': allSchools,
      'backupId': backupId.trim(),
      'confirmPhrase': confirmPhrase.trim(),
      'backupConfirmed': backupConfirmed,
      'deleteAuthUsers': deleteAuthUsers,
      'execute': true,
    });

    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> createBackup({
    String? schoolId,
    List<String>? schoolIds,
    bool allSchools = false,
  }) async {
    final callable = _functions.httpsCallable('createDataBackup');
    final result = await callable.call({
      'schoolId': (schoolId ?? '').trim(),
      'schoolIds': (schoolIds ?? const <String>[]).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'allSchools': allSchools,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<List<Map<String, dynamic>>> listBackups() async {
    final callable = _functions.httpsCallable('listDataBackups');
    final result = await callable.call();
    final data = Map<String, dynamic>.from(result.data as Map);
    final list = (data['backups'] as List?) ?? const [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> restoreBackup({
    required String backupId,
    List<String>? schoolIds,
    bool restoreAll = false,
    required String confirmPhrase,
    required bool overwriteConfirmed,
  }) async {
    final callable = _functions.httpsCallable('restoreDataBackup');
    final result = await callable.call({
      'backupId': backupId.trim(),
      'schoolIds': (schoolIds ?? const <String>[]).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'restoreAll': restoreAll,
      'confirmPhrase': confirmPhrase.trim(),
      'overwriteConfirmed': overwriteConfirmed,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
