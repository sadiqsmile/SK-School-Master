import 'package:cloud_firestore/cloud_firestore.dart';

class DuplicateFeeTypeException implements Exception {
  DuplicateFeeTypeException(this.name);

  final String name;

  @override
  String toString() => 'DuplicateFeeTypeException(name: $name)';
}

class FeeTypeService {
  FeeTypeService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String schoolId) {
    return _db.collection('schools').doc(schoolId).collection('feeTypes');
  }

  DocumentReference<Map<String, dynamic>> _nameLock(String schoolId, String nameLower) {
    return _db
        .collection('schools')
        .doc(schoolId)
        .collection('feeTypeNameLocks')
        .doc(nameLower);
  }

  String _normalize(String name) => name.trim();

  String _key(String name) => _normalize(name).toLowerCase();

  Future<void> addFeeType({
    required String schoolId,
    required String name,
  }) async {
    final clean = _normalize(name);
    final lower = _key(name);
    if (clean.isEmpty) throw ArgumentError('Fee type name is required');

    final col = _col(schoolId);

    final lockRef = _nameLock(schoolId, lower);

    await _db.runTransaction((tx) async {
      final lockSnap = await tx.get(lockRef);
      if (lockSnap.exists) {
        throw DuplicateFeeTypeException(clean);
      }

      tx.set(lockRef, {
        'name': clean,
        'nameLower': lower,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final ref = col.doc();
      tx.set(ref, {
        'name': clean,
        'nameLower': lower,
        'nameLockId': lower,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateFeeType({
    required String schoolId,
    required String feeTypeId,
    required String name,
  }) async {
    final clean = _normalize(name);
    final lower = _key(name);
    if (clean.isEmpty) throw ArgumentError('Fee type name is required');

    final col = _col(schoolId);
    final ref = col.doc(feeTypeId);

    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) {
        throw Exception('Fee type not found');
      }

      final data = doc.data() ?? <String, dynamic>{};
      final oldLower = (data['nameLower'] ?? '').toString();

      if (oldLower.isNotEmpty && oldLower != lower) {
        final newLockRef = _nameLock(schoolId, lower);
        final oldLockRef = _nameLock(schoolId, oldLower);

        final newLockSnap = await tx.get(newLockRef);
        if (newLockSnap.exists) {
          throw DuplicateFeeTypeException(clean);
        }

        // Acquire new lock then release old lock.
        tx.set(newLockRef, {
          'name': clean,
          'nameLower': lower,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.delete(oldLockRef);
      }

      tx.update(ref, {
        'name': clean,
        'nameLower': lower,
        'nameLockId': lower,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteFeeType({
    required String schoolId,
    required String feeTypeId,
  }) async {
    final col = _col(schoolId);
    final ref = col.doc(feeTypeId);

    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;

      final data = doc.data() ?? <String, dynamic>{};
      final lower = (data['nameLockId'] ?? data['nameLower'] ?? '').toString();
      if (lower.isNotEmpty) {
        tx.delete(_nameLock(schoolId, lower));
      }
      tx.delete(ref);
    });
  }
}
