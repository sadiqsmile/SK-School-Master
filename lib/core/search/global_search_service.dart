import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:school_app/core/search/global_search_models.dart';

class GlobalSearchService {
  GlobalSearchService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  String _endPrefix(String prefix) => '$prefix\uf8ff';

  Future<List<GlobalSearchResult>> search({
    required String schoolId,
    required String query,
    int perTypeLimit = 12,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const <GlobalSearchResult>[];

    final qLower = q.toLowerCase();
    final qUpper = q.toUpperCase();

    final studentsFuture = _searchStudents(
      schoolId: schoolId,
      q: q,
      qLower: qLower,
      qUpper: qUpper,
      limit: perTypeLimit,
    );
    final teachersFuture = _searchTeachers(
      schoolId: schoolId,
      qLower: qLower,
      qUpper: qUpper,
      limit: perTypeLimit,
    );
    final classesFuture = _searchClasses(
      schoolId: schoolId,
      qLower: qLower,
      qUpper: qUpper,
      limit: perTypeLimit,
    );

    final results = await Future.wait([
      studentsFuture,
      teachersFuture,
      classesFuture,
    ]);

    final merged = <GlobalSearchResult>[];
    for (final list in results) {
      merged.addAll(list);
    }

    // Dedupe by type+id.
    final seen = <String>{};
    final deduped = <GlobalSearchResult>[];
    for (final r in merged) {
      final key = '${r.type.name}:${r.id}';
      if (seen.add(key)) deduped.add(r);
    }

    return deduped;
  }

  Future<List<GlobalSearchResult>> _searchStudents({
    required String schoolId,
    required String q,
    required String qLower,
    required String qUpper,
    required int limit,
  }) async {
    final ref = _db.collection('schools').doc(schoolId).collection('students');

    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];

    // 1) Search by documentId prefix (admissionNo used as id).
    futures.add(
      ref
          .orderBy(FieldPath.documentId)
          .startAt([qUpper])
          .endAt([_endPrefix(qUpper)])
          .limit(limit)
          .get(),
    );

    // 2) Search by normalized name (preferred, case-insensitive).
    futures.add(
      ref
          .orderBy('nameLower')
          .startAt([qLower])
          .endAt([_endPrefix(qLower)])
          .limit(limit)
          .get(),
    );

    // 3) Fallback: legacy name field (many existing docs are ALL CAPS).
    futures.add(
      ref
          .orderBy('name')
          .startAt([qUpper])
          .endAt([_endPrefix(qUpper)])
          .limit(limit)
          .get(),
    );

    final snaps = await Future.wait(futures);

    final out = <GlobalSearchResult>[];
    for (final snap in snaps) {
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().trim();
        final classId = (data['classId'] ?? '').toString().trim();
        final section = (data['section'] ?? '').toString().trim();

        final title = name.isEmpty ? doc.id : name;
        final subtitle = [
          if (doc.id.trim().isNotEmpty) 'Adm: ${doc.id}',
          if (classId.isNotEmpty) 'Class $classId${section.isEmpty ? '' : section}',
        ].join(' • ');

        out.add(
          GlobalSearchResult(
            type: GlobalSearchResultType.student,
            id: doc.id,
            title: title,
            subtitle: subtitle,
            icon: Icons.groups_rounded,
            // We have a detail screen here already.
            route: '/school-admin/reports/students/${Uri.encodeComponent(doc.id)}',
          ),
        );
      }
    }

    return out;
  }

  Future<List<GlobalSearchResult>> _searchTeachers({
    required String schoolId,
    required String qLower,
    required String qUpper,
    required int limit,
  }) async {
    final ref = _db.collection('schools').doc(schoolId).collection('teachers');

    final snaps = await Future.wait([
      ref
          .orderBy('nameLower')
          .startAt([qLower])
          .endAt([_endPrefix(qLower)])
          .limit(limit)
          .get(),
      ref
          .orderBy('name')
          .startAt([qUpper])
          .endAt([_endPrefix(qUpper)])
          .limit(limit)
          .get(),
    ]);

    final out = <GlobalSearchResult>[];
    for (final snap in snaps) {
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().trim();
        final email = (data['email'] ?? '').toString().trim();

        out.add(
          GlobalSearchResult(
            type: GlobalSearchResultType.teacher,
            id: doc.id,
            title: name.isEmpty ? 'Teacher' : name,
            subtitle: email.isEmpty ? 'Teacher ID: ${doc.id}' : email,
            icon: Icons.school_rounded,
            // No dedicated teacher detail screen yet; route to the teachers list.
            route: '/school-admin/teachers',
          ),
        );
      }
    }

    return out;
  }

  Future<List<GlobalSearchResult>> _searchClasses({
    required String schoolId,
    required String qLower,
    required String qUpper,
    required int limit,
  }) async {
    final ref = _db.collection('schools').doc(schoolId).collection('classes');

    final snaps = await Future.wait([
      ref
          .orderBy('nameLower')
          .startAt([qLower])
          .endAt([_endPrefix(qLower)])
          .limit(limit)
          .get(),
      ref
          .orderBy('name')
          .startAt([qUpper])
          .endAt([_endPrefix(qUpper)])
          .limit(limit)
          .get(),
    ]);

    final out = <GlobalSearchResult>[];
    for (final snap in snaps) {
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = (data['name'] ?? doc.id).toString().trim();
        final sectionType = (data['sectionType'] ?? '').toString().trim();

        out.add(
          GlobalSearchResult(
            type: GlobalSearchResultType.classItem,
            id: doc.id,
            title: 'Class $name',
            subtitle: sectionType.isEmpty ? doc.id : sectionType,
            icon: Icons.class_rounded,
            route: '/sections/${Uri.encodeComponent(doc.id)}',
          ),
        );
      }
    }

    return out;
  }
}
