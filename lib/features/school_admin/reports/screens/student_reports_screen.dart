import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/core/utils/marks_calc.dart';
import 'package:school_app/models/exam.dart';
import 'package:school_app/models/exam_marks.dart';
import 'package:school_app/providers/grading_system_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';

class StudentReportsScreen extends ConsumerStatefulWidget {
  const StudentReportsScreen({super.key});

  @override
  ConsumerState<StudentReportsScreen> createState() =>
      _StudentReportsScreenState();
}

class _StudentReportsScreenState extends ConsumerState<StudentReportsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8FAFC);

    final schoolAsync = ref.watch(currentSchoolProvider);

    return AdminLayout(
      title: 'Student Reports',
      body: Container(
        color: bg,
        child: schoolAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load school: $e')),
          data: (schoolDoc) {
            final schoolId = schoolDoc.id;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Search student by name or admission number…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('schools')
                        .doc(schoolId)
                        .collection('students')
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Failed: ${snap.error}'));
                      }
                      final docs = snap.data?.docs ?? const [];

                      final q = _query.toLowerCase();
                      final filtered = q.isEmpty
                          ? docs
                          : docs.where((d) {
                              final data = d.data();
                              final name = (data['name'] ?? '').toString().toLowerCase();
                              final admission = (data['admissionNo'] ?? '').toString().toLowerCase();
                              return name.contains(q) || admission.contains(q);
                            }).toList(growable: false);

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('No students found.'),
                        );
                      }

                      filtered.sort((a, b) {
                        final an = (a.data()['name'] ?? '').toString();
                        final bn = (b.data()['name'] ?? '').toString();
                        return an.compareTo(bn);
                      });

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final doc = filtered[i];
                          final data = doc.data();
                          final name = (data['name'] ?? 'Student').toString();
                          final admission = (data['admissionNo'] ?? '').toString();
                          final classId = (data['classId'] ?? '').toString();
                          final section = (data['section'] ?? '').toString();

                          return ListTile(
                            title: Text(name),
                            subtitle: Text(
                              '${classId.isEmpty ? 'Class' : classId}${section.isEmpty ? '' : ' • $section'}'
                              '${admission.isEmpty ? '' : ' • Adm $admission'}',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.go(
                              '/school-admin/reports/students/${Uri.encodeComponent(doc.id)}',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class StudentReportDetailScreen extends ConsumerStatefulWidget {
  const StudentReportDetailScreen({
    super.key,
    required this.studentId,
  });

  final String studentId;

  @override
  ConsumerState<StudentReportDetailScreen> createState() =>
      _StudentReportDetailScreenState();
}

class _StudentReportDetailScreenState
    extends ConsumerState<StudentReportDetailScreen> {
  Future<_StudentReport>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _sanitizeId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final safe = trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    return safe
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _classKey(String classId, String sectionId) {
    return 'class_${_sanitizeId(classId)}_${_sanitizeId(sectionId)}';
  }

  num _readNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  Future<_StudentReport> _load() async {
    final schoolDoc = await ref.read(currentSchoolProvider.future);
    final schoolId = schoolDoc.id;

    final grading = await ref.read(gradingSystemProvider.future);

    final db = FirebaseFirestore.instance;

    final studentSnap = await db
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(widget.studentId)
        .get();

    if (!studentSnap.exists) throw Exception('Student not found');
    final student = studentSnap.data() ?? const <String, dynamic>{};

    final name = (student['name'] ?? widget.studentId).toString();
    final classId = (student['classId'] ?? '').toString();
    final sectionId = (student['section'] ?? '').toString();

    // Attendance: last 30 days.
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 29));

    int present = 0;
    int absent = 0;
    int late = 0;
    int leave = 0;

    final classKey = _classKey(classId, sectionId);

    if (classKey != 'class__' && classId.trim().isNotEmpty && sectionId.trim().isNotEmpty) {
      final reads = <Future<DocumentSnapshot<Map<String, dynamic>>>>[];
      for (int i = 0; i < 30; i++) {
        final day = DateTime(start.year, start.month, start.day).add(Duration(days: i));
        final key = _dateKey(day);
        reads.add(
          db
              .collection('schools')
              .doc(schoolId)
              .collection('attendance')
              .doc(key)
              .collection(classKey)
              .doc(widget.studentId)
              .get(),
        );
      }
      final snaps = await Future.wait(reads);
      for (final s in snaps) {
        if (!s.exists) continue;
        final status = (s.data()?['status'] ?? '').toString();
        switch (status) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            break;
          case 'leave':
            leave++;
            break;
          default:
            break;
        }
      }
    }

    final markedDays = present + absent + late + leave;
    final attendanceRate = markedDays <= 0 ? 0.0 : (present / markedDays) * 100;

    // Fees pending.
    final feeSnap = await db
        .collection('schools')
        .doc(schoolId)
        .collection('studentFees')
        .where('studentId', isEqualTo: widget.studentId)
        .get();

    num pendingFees = 0;
    for (final doc in feeSnap.docs) {
      final data = doc.data();
      final bal = data['balance'] ?? data['pendingAmount'];
      final balNum = _readNum(bal);
      if (balNum > 0) {
        pendingFees += balNum;
        continue;
      }

      final status = (data['status'] ?? '').toString().toLowerCase().trim();
      if (status == 'pending' || status == 'due') {
        pendingFees += _readNum(data['amount']);
      }
    }

    // Homework due count (class-level, not per-student submissions).
    int homeworkDue = 0;
    final hwSnap = await db
        .collection('schools')
        .doc(schoolId)
        .collection('homework')
        .where('classId', isEqualTo: classId)
        .where('section', isEqualTo: sectionId)
        .get();

    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final doc in hwSnap.docs) {
      final data = doc.data();
      final raw = data['dueDate'];
      DateTime? due;
      if (raw is Timestamp) due = raw.toDate();
      if (raw is DateTime) due = raw;
      if (raw is String) due = DateTime.tryParse(raw);
      if (due == null) continue;
      if (!due.isBefore(todayStart)) homeworkDue++;
    }

    // Latest exam grade (best-effort: last 5 exams for the class).
    String? latestExamTitle;
    String? latestExamGrade;

    final examsSnap = await db
        .collection('schools')
        .doc(schoolId)
        .collection('exams')
        .where('classId', isEqualTo: classId)
        .where('section', isEqualTo: sectionId)
        .get();

    final exams = examsSnap.docs.map(Exam.fromDoc).toList(growable: false);
    exams.sort((a, b) {
      final ad = a.createdAt;
      final bd = b.createdAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    for (final e in exams.take(5)) {
      final marksDoc = await db
          .collection('schools')
          .doc(schoolId)
          .collection('exams')
          .doc(e.id)
          .collection('marks')
          .doc(widget.studentId)
          .get();

      if (!marksDoc.exists) continue;

      final marks = ExamMarks.fromDoc(marksDoc);
      final calc = calcTotals(exam: e, marks: marks);

      final t = e.examType.trim();
      latestExamTitle = t.isEmpty ? e.examName : '$t • ${e.examName}';
      latestExamGrade = gradeForPercent(calc.percent, system: grading);
      break;
    }

    return _StudentReport(
      studentName: name,
      classId: classId,
      sectionId: sectionId,
      attendanceRate: attendanceRate,
      attendanceMarkedDays: markedDays,
      present: present,
      absent: absent,
      late: late,
      leave: leave,
      pendingFees: pendingFees,
      homeworkDueCount: homeworkDue,
      latestExamTitle: latestExamTitle,
      latestExamGrade: latestExamGrade,
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8FAFC);
    const accent = Color(0xFF7C3AED);

    return AdminLayout(
      title: 'Student Report',
      body: Container(
        color: bg,
        child: FutureBuilder<_StudentReport>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Failed: ${snapshot.error}'));
            }
            final r = snapshot.data;
            if (r == null) return const Center(child: Text('No data'));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Card(
                  borderColor: accent.withAlpha(60),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: accent.withAlpha(20),
                        child: const Icon(Icons.person_rounded, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Class ${r.classId}${r.sectionId.isEmpty ? '' : ' • ${r.sectionId}'}',
                              style: const TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        accent: accent,
                        title: 'Attendance',
                        value: '${r.attendanceRate.toStringAsFixed(0)}%',
                        icon: Icons.fact_check_rounded,
                        subtitle: '${r.attendanceMarkedDays} marked days (last 30)',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(
                        accent: accent,
                        title: 'Fees Pending',
                        value: '₹${r.pendingFees.round()}',
                        icon: Icons.payments_rounded,
                        subtitle: 'From studentFees',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        accent: accent,
                        title: 'Homework Due',
                        value: '${r.homeworkDueCount}',
                        icon: Icons.menu_book_rounded,
                        subtitle: 'Class-level due items',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(
                        accent: accent,
                        title: 'Latest Exam',
                        value: r.latestExamGrade ?? '—',
                        icon: Icons.auto_graph_rounded,
                        subtitle: r.latestExamTitle ?? 'No marks yet',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Card(
                  borderColor: accent.withAlpha(60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance breakdown (last 30 days)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(label: 'Present', value: r.present, color: const Color(0xFF16A34A)),
                          _Chip(label: 'Absent', value: r.absent, color: const Color(0xFFDC2626)),
                          _Chip(label: 'Late', value: r.late, color: const Color(0xFFF59E0B)),
                          _Chip(label: 'Leave', value: r.leave, color: const Color(0xFF6366F1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Note: Attendance percent is based on days where a student record exists in the attendance collection.',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StudentReport {
  const _StudentReport({
    required this.studentName,
    required this.classId,
    required this.sectionId,
    required this.attendanceRate,
    required this.attendanceMarkedDays,
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.pendingFees,
    required this.homeworkDueCount,
    required this.latestExamTitle,
    required this.latestExamGrade,
  });

  final String studentName;
  final String classId;
  final String sectionId;

  final double attendanceRate;
  final int attendanceMarkedDays;
  final int present;
  final int absent;
  final int late;
  final int leave;

  final num pendingFees;
  final int homeworkDueCount;

  final String? latestExamTitle;
  final String? latestExamGrade;
}

class _Card extends StatelessWidget {
  const _Card({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.accent,
    required this.title,
    required this.value,
    required this.icon,
    required this.subtitle,
  });

  final Color accent;
  final String title;
  final String value;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
      backgroundColor: color.withAlpha(18),
      side: BorderSide(color: color.withAlpha(60)),
    );
  }
}
