import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';

import 'package:school_app/core/utils/firestore_keys.dart';
import 'package:school_app/features/school_admin/classes/services/section_service.dart';
import 'package:school_app/features/school_admin/students/services/student_service.dart';
import 'package:school_app/features/school_admin/teachers/services/teacher_service.dart';
import 'package:school_app/services/teacher_account_service.dart';

class ImportSummary {
  ImportSummary({
    required this.totalRows,
    required this.created,
    required this.updated,
    required this.skipped,
    required this.errors,
  });

  final int totalRows;
  final int created;
  final int updated;
  final int skipped;
  final List<String> errors;
}

class SchoolDataToolsService {
  SchoolDataToolsService({
    FirebaseFirestore? db,
    StudentService? studentService,
    TeacherService? teacherService,
    TeacherAccountService? teacherAccountService,
    SectionService? sectionService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _studentService = studentService ?? StudentService(db: db),
        _teacherService = teacherService ?? TeacherService(db: db),
        _teacherAccountService = teacherAccountService ?? TeacherAccountService(),
        _sectionService = sectionService ?? SectionService(firestore: db);

  final FirebaseFirestore _db;
  final StudentService _studentService;
  final TeacherService _teacherService;
  final TeacherAccountService _teacherAccountService;
  final SectionService _sectionService;

  String _asString(dynamic v) => (v ?? '').toString().trim();

  List<Map<String, String>> parseCsvToMaps(String raw) {
    final text = raw.replaceFirst(RegExp('^\uFEFF'), '');
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(text);

    if (rows.isEmpty) return [];

    final headers = rows.first
        .map((e) => (e ?? '').toString().trim())
        .where((h) => h.isNotEmpty)
        .toList(growable: false);

    if (headers.isEmpty) return [];

    final out = <Map<String, String>>[];
    for (final r in rows.skip(1)) {
      if (r.isEmpty) continue;

      final map = <String, String>{};
      for (var i = 0; i < headers.length; i++) {
        final key = headers[i];
        final value = i < r.length ? (r[i] ?? '').toString() : '';
        map[key] = value.trim();
      }

      final hasAnyValue = map.values.any((v) => v.trim().isNotEmpty);
      if (!hasAnyValue) continue;

      out.add(map);
    }

    return out;
  }

  String exportStudentsCsv(String schoolId, QuerySnapshot<Map<String, dynamic>> snap) {
    final header = <String>[
      'admissionNo',
      'name',
      'classId',
      'section',
      'academicYear',
      'parentName',
      'parentPhone',
      'parentUid',
    ];

    final rows = <List<dynamic>>[header];
    for (final d in snap.docs) {
      final data = d.data();
      rows.add([
        _asString(data['admissionNo']).isEmpty ? d.id : _asString(data['admissionNo']),
        _asString(data['name']),
        _asString(data['classId']),
        _asString(data['section']),
        _asString(data['academicYear']),
        _asString(data['parentName']),
        _asString(data['parentPhone']),
        _asString(data['parentUid']),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<String> buildStudentsCsv({required String schoolId}) async {
    final snap = await _db
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .orderBy('admissionNo')
        .get();
    return exportStudentsCsv(schoolId, snap);
  }

  Future<ImportSummary> importStudentsCsv({
    required String schoolId,
    required String csvText,
  }) async {
    final rows = parseCsvToMaps(csvText);
    if (rows.isEmpty) {
      return ImportSummary(
        totalRows: 0,
        created: 0,
        updated: 0,
        skipped: 0,
        errors: const ['No rows found (check the header row and data).'],
      );
    }

    int created = 0;
    int updated = 0;
    int skipped = 0;
    final errors = <String>[];

    String pick(Map<String, String> r, List<String> keys) {
      for (final k in keys) {
        final exact = r[k];
        if (exact != null && exact.trim().isNotEmpty) return exact.trim();

        // Case-insensitive.
        final found = r.entries
            .firstWhere(
              (e) => e.key.toLowerCase() == k.toLowerCase(),
              orElse: () => const MapEntry('', ''),
            )
            .value;
        if (found.trim().isNotEmpty) return found.trim();
      }
      return '';
    }

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final rowNo = i + 2; // header is row 1

      final admissionNo = pick(r, ['admissionNo', 'admission', 'id']).toUpperCase();
      final name = pick(r, ['name', 'studentName']);
      final classId = pick(r, ['classId', 'class']);
      final section = pick(r, ['section', 'sec']);
      final academicYear = pick(r, ['academicYear', 'year']);
      final parentName = pick(r, ['parentName']);
      final parentPhone = pick(r, ['parentPhone', 'phone']);

      if (admissionNo.isEmpty || name.isEmpty) {
        skipped++;
        errors.add('Row $rowNo: admissionNo and name are required (skipped)');
        continue;
      }

      try {
        await _studentService.addStudent(
          schoolId: schoolId,
          data: {
            'admissionNo': admissionNo,
            'name': name,
            if (classId.isNotEmpty) 'classId': classId,
            if (section.isNotEmpty) 'section': section,
            if (academicYear.isNotEmpty) 'academicYear': academicYear,
            if (parentName.isNotEmpty) 'parentName': parentName,
            if (parentPhone.isNotEmpty) 'parentPhone': parentPhone,
          },
        );
        created++;
      } on DuplicateAdmissionNumberException {
        // Update existing student instead.
        try {
          final docRef = _db
              .collection('schools')
              .doc(schoolId)
              .collection('students')
              .doc(admissionNo);
          await docRef.set(
            {
              'admissionNo': admissionNo,
              'name': name.trim().toUpperCase(),
              'nameLower': name.trim().toLowerCase(),
              if (classId.isNotEmpty) 'classId': classId,
              if (section.isNotEmpty) 'section': section,
              if (academicYear.isNotEmpty) 'academicYear': academicYear,
              if (parentName.isNotEmpty) 'parentName': parentName.trim().toUpperCase(),
              if (parentPhone.isNotEmpty) 'parentPhone': parentPhone,
              'updatedAt': FieldValue.serverTimestamp(),
              if (classId.isNotEmpty && section.isNotEmpty)
                'classKey': classKeyFrom(classId, section),
            },
            SetOptions(merge: true),
          );
          updated++;
        } catch (e) {
          errors.add('Row $rowNo: duplicate admissionNo "$admissionNo" but update failed: $e');
        }
      } catch (e) {
        errors.add('Row $rowNo: failed to import student "$admissionNo": $e');
      }
    }

    return ImportSummary(
      totalRows: rows.length,
      created: created,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }

  Future<String> buildTeachersCsv({required String schoolId}) async {
    final snap = await _db
        .collection('schools')
        .doc(schoolId)
        .collection('teachers')
        .get();

    final header = <String>[
      'teacherUid',
      'name',
      'email',
      'phone',
      'subjectsJson',
      'classesJson',
    ];

    final rows = <List<dynamic>>[header];
    for (final d in snap.docs) {
      final data = d.data();
      rows.add([
        _asString(data['teacherUid']).isEmpty ? d.id : _asString(data['teacherUid']),
        _asString(data['name']),
        _asString(data['email']),
        _asString(data['phone']),
        jsonEncode(data['subjects'] ?? const []),
        jsonEncode(data['classes'] ?? const []),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<ImportSummary> importTeachersCsv({
    required String schoolId,
    required String csvText,
    bool createLogins = true,
  }) async {
    final rows = parseCsvToMaps(csvText);
    if (rows.isEmpty) {
      return ImportSummary(
        totalRows: 0,
        created: 0,
        updated: 0,
        skipped: 0,
        errors: const ['No rows found (check the header row and data).'],
      );
    }

    int created = 0;
    int updated = 0;
    int skipped = 0;
    final errors = <String>[];

    String pick(Map<String, String> r, List<String> keys) {
      for (final k in keys) {
        final exact = r[k];
        if (exact != null && exact.trim().isNotEmpty) return exact.trim();

        final found = r.entries
            .firstWhere(
              (e) => e.key.toLowerCase() == k.toLowerCase(),
              orElse: () => const MapEntry('', ''),
            )
            .value;
        if (found.trim().isNotEmpty) return found.trim();
      }
      return '';
    }

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final rowNo = i + 2;

      final name = pick(r, ['name', 'teacherName']);
      final email = pick(r, ['email']);
      final phone = pick(r, ['phone']);
      final teacherUidHint = pick(r, ['teacherUid', 'uid']);

      final subjectsJson = pick(r, ['subjectsJson']);
      final classesJson = pick(r, ['classesJson']);

      if (name.isEmpty || email.isEmpty || phone.isEmpty) {
        skipped++;
        errors.add('Row $rowNo: name, email and phone are required (skipped)');
        continue;
      }

      String teacherUid = teacherUidHint;
      String? tempPassword;

      try {
        if (createLogins) {
          final result = await _teacherAccountService.createTeacherLogin(
            schoolId: schoolId,
            teacherName: name,
            email: email,
            phone: phone,
            teacherId: teacherUidHint.isEmpty ? null : teacherUidHint,
          );
          teacherUid = (result['uid'] ?? '').toString();
          tempPassword = (result['temporaryPassword'] ?? '').toString();
        }

        if (teacherUid.trim().isEmpty) {
          skipped++;
          errors.add('Row $rowNo: teacherUid missing (skipped)');
          continue;
        }

        List<dynamic> subjects = const [];
        if (subjectsJson.isNotEmpty) {
          try {
            final parsed = jsonDecode(subjectsJson);
            if (parsed is List) subjects = parsed;
          } catch (_) {}
        }

        List<dynamic> classes = const [];
        if (classesJson.isNotEmpty) {
          try {
            final parsed = jsonDecode(classesJson);
            if (parsed is List) classes = parsed;
          } catch (_) {}
        }

        final assignmentKeys = <String>[];
        for (final c in classes) {
          if (c is Map) {
            final classId = _asString(c['classId']);
            final sectionId = _asString(c['sectionId']);
            final ck = classKeyFrom(classId, sectionId);
            if (ck != 'class__') assignmentKeys.add(ck);
          }
        }

        await _teacherService.setTeacher(
          schoolId: schoolId,
          teacherId: teacherUid,
          data: {
            'teacherUid': teacherUid,
            'name': name,
            'nameLower': name.trim().toLowerCase(),
            'email': email,
            'emailLower': email.trim().toLowerCase(),
            'phone': phone,
            'subjects': subjects,
            'classes': classes,
            'assignmentKeys': assignmentKeys.toSet().toList(),
            if (tempPassword != null && tempPassword.trim().isNotEmpty)
              'importTemporaryPassword': tempPassword,
          },
        );

        // We treat teachers as created/updated based on whether doc existed.
        // This avoids having to read each doc beforehand.
        created++;
      } catch (e) {
        errors.add('Row $rowNo: failed to import teacher "$email": $e');
      }
    }

    return ImportSummary(
      totalRows: rows.length,
      created: created,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }

  Future<String> buildClassesCsv({required String schoolId}) async {
    final classesSnap = await _db
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .get();

    final header = <String>['classId', 'name', 'sectionType', 'sectionsPipe'];
    final rows = <List<dynamic>>[header];

    for (final classDoc in classesSnap.docs) {
      final data = classDoc.data();
      final sectionsSnap = await classDoc.reference.collection('sections').get();
      final sections = sectionsSnap.docs
          .map((d) => _asString(d.data()['name']).isEmpty ? d.id : _asString(d.data()['name']))
          .where((s) => s.isNotEmpty)
          .toList();

      rows.add([
        classDoc.id,
        _asString(data['name']),
        _asString(data['sectionType']),
        sections.join('|'),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<ImportSummary> importClassesCsv({
    required String schoolId,
    required String csvText,
  }) async {
    final rows = parseCsvToMaps(csvText);
    if (rows.isEmpty) {
      return ImportSummary(
        totalRows: 0,
        created: 0,
        updated: 0,
        skipped: 0,
        errors: const ['No rows found (check the header row and data).'],
      );
    }

    int created = 0;
    int updated = 0;
    int skipped = 0;
    final errors = <String>[];

    String pick(Map<String, String> r, List<String> keys) {
      for (final k in keys) {
        final exact = r[k];
        if (exact != null && exact.trim().isNotEmpty) return exact.trim();

        final found = r.entries
            .firstWhere(
              (e) => e.key.toLowerCase() == k.toLowerCase(),
              orElse: () => const MapEntry('', ''),
            )
            .value;
        if (found.trim().isNotEmpty) return found.trim();
      }
      return '';
    }

    String computeClassId(String name, String sectionType) {
      return '${name}_$sectionType'.toLowerCase().replaceAll(' ', '_');
    }

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final rowNo = i + 2;

      final name = pick(r, ['name', 'className']);
      final sectionType = pick(r, ['sectionType']);
      final classId = pick(r, ['classId']).isNotEmpty
          ? pick(r, ['classId'])
          : (name.isNotEmpty && sectionType.isNotEmpty)
              ? computeClassId(name, sectionType)
              : '';

      final sectionsPipe = pick(r, ['sectionsPipe', 'sections']);
      final sections = sectionsPipe
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (classId.isEmpty || name.isEmpty) {
        skipped++;
        errors.add('Row $rowNo: classId and name are required (skipped)');
        continue;
      }

      try {
        final classRef = _db
            .collection('schools')
            .doc(schoolId)
            .collection('classes')
            .doc(classId);

        final existing = await classRef.get();

        await classRef.set(
          {
            'name': name,
            'nameLower': name.trim().toLowerCase(),
            if (sectionType.isNotEmpty) 'sectionType': sectionType,
            if (sectionType.isNotEmpty) 'sectionTypeLower': sectionType.trim().toLowerCase(),
            'updatedAt': FieldValue.serverTimestamp(),
            if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (sections.isNotEmpty) {
          for (final sec in sections) {
            await _sectionService.createSection(
              schoolId: schoolId,
              classId: classId,
              sectionName: sec,
            );
          }
        }

        if (existing.exists) {
          updated++;
        } else {
          created++;
        }
      } catch (e) {
        errors.add('Row $rowNo: failed to import class "$classId": $e');
      }
    }

    return ImportSummary(
      totalRows: rows.length,
      created: created,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }
}
