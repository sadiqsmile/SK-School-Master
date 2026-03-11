import 'package:cloud_functions/cloud_functions.dart';

class PlatformFileBackupItem {
  PlatformFileBackupItem({
    required this.backupFileId,
    required this.status,
    required this.allSchools,
    required this.schoolIds,
    required this.objectPath,
    required this.createdAtIso,
    required this.createdByUid,
    required this.note,
  });

  final String backupFileId;
  final String status;
  final bool allSchools;
  final List<String> schoolIds;
  final String objectPath;
  final String? createdAtIso;
  final String? createdByUid;
  final String? note;

  static PlatformFileBackupItem fromMap(Map<String, dynamic> m) {
    final schoolIdsRaw = m['schoolIds'];
    final schoolIds = schoolIdsRaw is List
        ? schoolIdsRaw.map((e) => (e ?? '').toString()).where((s) => s.trim().isNotEmpty).toList()
        : <String>[];

    return PlatformFileBackupItem(
      backupFileId: (m['backupFileId'] ?? '').toString(),
      status: (m['status'] ?? '').toString(),
      allSchools: m['allSchools'] == true,
      schoolIds: schoolIds,
      objectPath: (m['objectPath'] ?? '').toString(),
      createdAtIso: (m['createdAtIso'] ?? '').toString().trim().isEmpty
          ? null
          : (m['createdAtIso'] ?? '').toString(),
      createdByUid: (m['createdByUid'] ?? '').toString().trim().isEmpty
          ? null
          : (m['createdByUid'] ?? '').toString(),
      note: (m['note'] ?? '').toString().trim().isEmpty ? null : (m['note'] ?? '').toString(),
    );
  }
}

class PlatformFileBackupService {
  PlatformFileBackupService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw const FormatException('Invalid Cloud Function response');
  }

  Future<({String backupFileId, String objectPath})> createFileBackup({
    String? schoolId,
    List<String>? schoolIds,
    bool allSchools = false,
  }) async {
    final callable = _functions.httpsCallable('createFileBackup');
    final result = await callable.call({
      'schoolId': (schoolId ?? '').trim(),
      'schoolIds': (schoolIds ?? const []).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'allSchools': allSchools,
    });
    final data = _asMap(result.data);

    final id = (data['backupFileId'] ?? '').toString();
    final path = (data['objectPath'] ?? '').toString();
    if (id.trim().isEmpty || path.trim().isEmpty) {
      throw const FormatException('backupFileId/objectPath missing');
    }

    return (backupFileId: id, objectPath: path);
  }

  Future<List<PlatformFileBackupItem>> listFileBackups() async {
    final callable = _functions.httpsCallable('listFileBackups');
    final result = await callable.call();
    final data = _asMap(result.data);

    final raw = data['backups'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((e) => PlatformFileBackupItem.fromMap(Map<String, dynamic>.from(e)))
        .where((b) => b.backupFileId.trim().isNotEmpty)
        .toList();
  }

  Future<Uri> getDownloadUrl({required String backupFileId}) async {
    final callable = _functions.httpsCallable('getFileBackupDownloadUrl');
    final result = await callable.call({'backupFileId': backupFileId});
    final data = _asMap(result.data);

    final url = (data['url'] ?? '').toString();
    final uri = Uri.tryParse(url);
    if (uri == null) throw const FormatException('Invalid download URL');
    return uri;
  }

  Future<void> restoreFileBackup({
    required String backupFileId,
    required bool overwriteConfirmed,
    required String confirmPhrase,
    bool restoreAll = true,
    List<String>? schoolIds,
  }) async {
    final callable = _functions.httpsCallable('restoreFileBackup');
    await callable.call({
      'backupFileId': backupFileId,
      'restoreAll': restoreAll,
      'schoolIds': (schoolIds ?? const []).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'overwriteConfirmed': overwriteConfirmed,
      'confirmPhrase': confirmPhrase,
    });
  }
}
