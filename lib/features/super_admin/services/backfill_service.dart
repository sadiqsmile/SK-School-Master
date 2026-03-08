import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/core/utils/firestore_keys.dart';

class BackfillOptions {
  const BackfillOptions({
    this.students = true,
    this.teachers = true,
    this.exams = true,
    this.homework = true,
  });

  final bool students;
  final bool teachers;
  final bool exams;
  final bool homework;
}

class BackfillProgress {
  const BackfillProgress(this.message);

  final String message;
}

class BackfillResult {
  const BackfillResult({
    required this.studentsScanned,
    required this.studentsUpdated,
    required this.teachersScanned,
    required this.teachersUpdated,
    required this.examsScanned,
    required this.examsUpdated,
    required this.homeworkScanned,
    required this.homeworkUpdated,
    required this.errors,
  });

  final int studentsScanned;
  final int studentsUpdated;
  final int teachersScanned;
  final int teachersUpdated;
  final int examsScanned;
  final int examsUpdated;
  final int homeworkScanned;
  final int homeworkUpdated;

  final List<String> errors;
}

class BackfillService {
  BackfillService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<BackfillResult> backfillSchool({
    required String schoolId,
    required BackfillOptions options,
    void Function(BackfillProgress progress)? onProgress,
  }) async {
    if (schoolId.trim().isEmpty) {
      throw ArgumentError('schoolId cannot be empty');
    }

    final errors = <String>[];

    int studentsScanned = 0;
    int studentsUpdated = 0;
    int teachersScanned = 0;
    int teachersUpdated = 0;
    int examsScanned = 0;
    int examsUpdated = 0;
    int homeworkScanned = 0;
    int homeworkUpdated = 0;

    void log(String message) => onProgress?.call(BackfillProgress(message));

    if (options.students) {
      log('Backfilling students…');
      final r = await _backfillStudents(
        schoolId: schoolId,
        onProgress: log,
        onError: errors.add,
      );
      studentsScanned = r.scanned;
      studentsUpdated = r.updated;
      log('Students done: updated $studentsUpdated / scanned $studentsScanned');
    }

    if (options.teachers) {
      log('Backfilling teachers…');
      final r = await _backfillTeachers(
        schoolId: schoolId,
        onProgress: log,
        onError: errors.add,
      );
      teachersScanned = r.scanned;
      teachersUpdated = r.updated;
      log('Teachers done: updated $teachersUpdated / scanned $teachersScanned');
    }

    if (options.exams) {
      log('Backfilling exams…');
      final r = await _backfillClassKeyCollection(
        label: 'exams',
        col: _db.collection('schools').doc(schoolId).collection('exams'),
        classIdField: 'classId',
        sectionField: 'section',
        onProgress: log,
        onError: errors.add,
      );
      examsScanned = r.scanned;
      examsUpdated = r.updated;
      log('Exams done: updated $examsUpdated / scanned $examsScanned');
    }

    if (options.homework) {
      log('Backfilling homework…');
      final r = await _backfillClassKeyCollection(
        label: 'homework',
        col: _db.collection('schools').doc(schoolId).collection('homework'),
        classIdField: 'classId',
        sectionField: 'section',
        onProgress: log,
        onError: errors.add,
      );
      homeworkScanned = r.scanned;
      homeworkUpdated = r.updated;
      log('Homework done: updated $homeworkUpdated / scanned $homeworkScanned');
    }

    return BackfillResult(
      studentsScanned: studentsScanned,
      studentsUpdated: studentsUpdated,
      teachersScanned: teachersScanned,
      teachersUpdated: teachersUpdated,
      examsScanned: examsScanned,
      examsUpdated: examsUpdated,
      homeworkScanned: homeworkScanned,
      homeworkUpdated: homeworkUpdated,
      errors: List.unmodifiable(errors),
    );
  }

  Future<({int scanned, int updated})> _backfillStudents({
    required String schoolId,
    required void Function(String message) onProgress,
    required void Function(String error) onError,
  }) async {
    final col = _db.collection('schools').doc(schoolId).collection('students');

    int scanned = 0;
    int updated = 0;

    DocumentSnapshot<Map<String, dynamic>>? cursor;
    const pageSize = 250;

    while (true) {
      Query<Map<String, dynamic>> q = col.orderBy(FieldPath.documentId).limit(pageSize);
      if (cursor != null) {
        q = q.startAfterDocument(cursor);
      }

      final snap = await q.get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      int ops = 0;

      for (final doc in snap.docs) {
        scanned++;

        final data = doc.data();
        final classId = (data['classId'] ?? '').toString();
        final section = (data['section'] ?? data['sectionId'] ?? '').toString();

        final desired = classKeyFrom(classId, section);
        if (desired == 'class__') continue;

        final current = (data['classKey'] ?? '').toString();
        if (current == desired) continue;

        batch.set(doc.reference, {'classKey': desired}, SetOptions(merge: true));
        ops++;
        updated++;

        // Safety: keep batches well under 500 operations.
        if (ops >= 400) {
          await batch.commit();
          onProgress('Students: committed 400 updates…');
          ops = 0;
        }
      }

      if (ops > 0) {
        try {
          await batch.commit();
        } catch (e) {
          onError('Students batch commit failed: $e');
        }
      }

      cursor = snap.docs.last;
      onProgress('Students: scanned $scanned, updated $updated');
    }

    return (scanned: scanned, updated: updated);
  }

  Future<({int scanned, int updated})> _backfillTeachers({
    required String schoolId,
    required void Function(String message) onProgress,
    required void Function(String error) onError,
  }) async {
    final col = _db.collection('schools').doc(schoolId).collection('teachers');

    int scanned = 0;
    int updated = 0;

    DocumentSnapshot<Map<String, dynamic>>? cursor;
    const pageSize = 200;

    while (true) {
      Query<Map<String, dynamic>> q = col.orderBy(FieldPath.documentId).limit(pageSize);
      if (cursor != null) {
        q = q.startAfterDocument(cursor);
      }

      final snap = await q.get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      int ops = 0;

      for (final doc in snap.docs) {
        scanned++;
        final data = doc.data();

        final desired = _computeAssignmentKeys(data);
        final desiredSet = desired.toSet();

        final currentRaw = data['assignmentKeys'];
        final current = <String>[];
        if (currentRaw is List) {
          for (final v in currentRaw) {
            final s = v?.toString();
            if (s == null) continue;
            final t = s.trim();
            if (t.isNotEmpty) current.add(t);
          }
        }

        final currentSet = current.toSet();
        if (_setEquals(currentSet, desiredSet)) {
          continue;
        }

        batch.set(
          doc.reference,
          {'assignmentKeys': desired},
          SetOptions(merge: true),
        );
        ops++;
        updated++;

        if (ops >= 350) {
          await batch.commit();
          onProgress('Teachers: committed 350 updates…');
          ops = 0;
        }
      }

      if (ops > 0) {
        try {
          await batch.commit();
        } catch (e) {
          onError('Teachers batch commit failed: $e');
        }
      }

      cursor = snap.docs.last;
      onProgress('Teachers: scanned $scanned, updated $updated');
    }

    return (scanned: scanned, updated: updated);
  }

  Future<({int scanned, int updated})> _backfillClassKeyCollection({
    required String label,
    required CollectionReference<Map<String, dynamic>> col,
    required String classIdField,
    required String sectionField,
    required void Function(String message) onProgress,
    required void Function(String error) onError,
  }) async {
    int scanned = 0;
    int updated = 0;

    DocumentSnapshot<Map<String, dynamic>>? cursor;
    const pageSize = 250;

    while (true) {
      Query<Map<String, dynamic>> q = col.orderBy(FieldPath.documentId).limit(pageSize);
      if (cursor != null) {
        q = q.startAfterDocument(cursor);
      }

      final snap = await q.get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      int ops = 0;

      for (final doc in snap.docs) {
        scanned++;
        final data = doc.data();
        final classId = (data[classIdField] ?? '').toString();
        final section = (data[sectionField] ?? data['sectionId'] ?? '').toString();

        final desired = classKeyFrom(classId, section);
        if (desired == 'class__') continue;
        final current = (data['classKey'] ?? '').toString();
        if (current == desired) continue;

        batch.set(doc.reference, {'classKey': desired}, SetOptions(merge: true));
        ops++;
        updated++;

        if (ops >= 400) {
          await batch.commit();
          onProgress('$label: committed 400 updates…');
          ops = 0;
        }
      }

      if (ops > 0) {
        try {
          await batch.commit();
        } catch (e) {
          onError('$label batch commit failed: $e');
        }
      }

      cursor = snap.docs.last;
      onProgress('$label: scanned $scanned, updated $updated');
    }

    return (scanned: scanned, updated: updated);
  }

  List<String> _computeAssignmentKeys(Map<String, dynamic> teacherData) {
    final rawClasses = teacherData['classes'];
    if (rawClasses is! List) return const <String>[];

    final out = SplayTreeSet<String>();
    for (final item in rawClasses) {
      if (item is! Map) continue;
      final classId = (item['classId'] ?? '').toString();
      final sectionId = (item['sectionId'] ?? item['section'] ?? '').toString();
      final key = classKeyFrom(classId, sectionId);
      if (key == 'class__') continue;
      out.add(key);
    }

    return out.toList(growable: false);
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}
