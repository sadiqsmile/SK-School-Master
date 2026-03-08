import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class GoogleSheetsSyncConfig {
  GoogleSheetsSyncConfig({
    required this.enabled,
    required this.spreadsheetId,
    required this.daysBack,
    required this.maxRowsPerTab,
    this.lastSyncAt,
    this.lastSyncByUid,
    this.lastSyncCounts,
  });

  final bool enabled;
  final String? spreadsheetId;
  final int daysBack;
  final int maxRowsPerTab;

  final DateTime? lastSyncAt;
  final String? lastSyncByUid;
  final Map<String, dynamic>? lastSyncCounts;

  static GoogleSheetsSyncConfig? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;

    DateTime? lastSyncAt;
    final raw = m['lastSyncAt'];
    if (raw is Timestamp) {
      lastSyncAt = raw.toDate();
    }

    return GoogleSheetsSyncConfig(
      enabled: m['enabled'] == true,
      spreadsheetId: (m['spreadsheetId'] ?? '').toString().trim().isEmpty
          ? null
          : (m['spreadsheetId'] ?? '').toString(),
      daysBack: int.tryParse((m['daysBack'] ?? 30).toString()) ?? 30,
      maxRowsPerTab: int.tryParse((m['maxRowsPerTab'] ?? 20000).toString()) ?? 20000,
      lastSyncAt: lastSyncAt,
      lastSyncByUid: (m['lastSyncByUid'] ?? '').toString().trim().isEmpty
          ? null
          : (m['lastSyncByUid'] ?? '').toString(),
      lastSyncCounts: m['lastSyncCounts'] is Map ? Map<String, dynamic>.from(m['lastSyncCounts'] as Map) : null,
    );
  }
}

class GoogleSheetsSyncService {
  GoogleSheetsSyncService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw const FormatException('Invalid Cloud Function response');
  }

  Future<GoogleSheetsSyncConfig?> getConfig({required String schoolId}) async {
    final callable = _functions.httpsCallable('getGoogleSheetsSyncConfig');
    final result = await callable.call({'schoolId': schoolId});
    final data = _asMap(result.data);

    final cfgRaw = data['config'];
    if (cfgRaw is! Map) return null;
    return GoogleSheetsSyncConfig.fromMap(Map<String, dynamic>.from(cfgRaw));
  }

  Future<void> setConfig({
    required String schoolId,
    required bool enabled,
    required String spreadsheetId,
    required int daysBack,
    required int maxRowsPerTab,
  }) async {
    final callable = _functions.httpsCallable('setGoogleSheetsSyncConfig');
    await callable.call({
      'schoolId': schoolId,
      'enabled': enabled,
      'spreadsheetId': spreadsheetId,
      'daysBack': daysBack,
      'maxRowsPerTab': maxRowsPerTab,
    });
  }

  Future<Map<String, dynamic>> syncNow({
    required String schoolId,
    int? daysBack,
    int? maxRowsPerTab,
  }) async {
    final callable = _functions.httpsCallable('syncSchoolToGoogleSheets');
    final payload = <String, dynamic>{'schoolId': schoolId};
    if (daysBack != null) payload['daysBack'] = daysBack;
    if (maxRowsPerTab != null) payload['maxRowsPerTab'] = maxRowsPerTab;

    final result = await callable.call(payload);
    return _asMap(result.data);
  }
}
