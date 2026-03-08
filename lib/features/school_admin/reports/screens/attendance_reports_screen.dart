import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/classes/providers/classes_provider.dart' as classes_stream;
import 'package:school_app/features/school_admin/classes/providers/sections_provider.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/current_school_provider.dart';

class AttendanceReportsScreen extends ConsumerStatefulWidget {
  const AttendanceReportsScreen({super.key});

  @override
  ConsumerState<AttendanceReportsScreen> createState() =>
      _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState
    extends ConsumerState<AttendanceReportsScreen> {
  String? _classId;
  String? _sectionId;

  DateTimeRange _range = _defaultRange();

  Future<_AttendanceReport>? _future;

  static DateTimeRange _defaultRange() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(const Duration(days: 6));
    return DateTimeRange(start: start, end: end);
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

  List<String> _dateKeysInRange(DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    final days = end.difference(start).inDays;
    if (days < 0) return const [];

    final keys = <String>[];
    for (int i = 0; i <= days; i++) {
      keys.add(_dateKey(start.add(Duration(days: i))));
    }
    return keys;
  }

  Future<int> _countStudents({
    required FirebaseFirestore db,
    required String schoolId,
    required String classId,
    required String sectionId,
  }) async {
    final q = db
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .where('classId', isEqualTo: classId)
        .where('section', isEqualTo: sectionId);

    try {
      final agg = await q.count().get();
      final c = agg.count;
      if (c != null) return c;
    } catch (_) {
      // Fall through to non-aggregate count.
    }

    final snap = await q.get();
    return snap.size;
  }

  Future<_AttendanceReport> _buildReport({
    required String schoolId,
    required String classId,
    required String sectionId,
    required DateTimeRange range,
  }) async {
    final db = FirebaseFirestore.instance;

    final keys = _dateKeysInRange(range);
    if (keys.length > 120) {
      throw Exception(
        'Date range too large (${keys.length} days). Please select a smaller range (<= 120 days).',
      );
    }

    final totalStudents = await _countStudents(
      db: db,
      schoolId: schoolId,
      classId: classId,
      sectionId: sectionId,
    );

    final classKey = _classKey(classId, sectionId);
    if (classKey == 'class__') {
      throw Exception('Invalid class/section selection');
    }

    final metaReads = <Future<DocumentSnapshot<Map<String, dynamic>>>>[];
    for (final k in keys) {
      metaReads.add(
        db
            .collection('schools')
            .doc(schoolId)
            .collection('attendance')
            .doc(k)
            .collection('meta')
            .doc(classKey)
            .get(),
      );
    }

    final metaSnaps = await Future.wait(metaReads);

    int present = 0;
    int absent = 0;
    int late = 0;
    int leave = 0;
    int total = 0;

    final daily = <_AttendanceDaySummary>[];

    for (final snap in metaSnaps) {
      if (!snap.exists) continue;
      final data = snap.data() ?? const <String, dynamic>{};
      final date = (data['date'] ?? snap.reference.parent.parent?.id ?? '').toString();

      final counts = data['counts'];
      int p = 0, a = 0, l = 0, lv = 0, t = 0;
      if (counts is Map) {
        p = (counts['present'] as num?)?.toInt() ?? 0;
        a = (counts['absent'] as num?)?.toInt() ?? 0;
        l = (counts['late'] as num?)?.toInt() ?? 0;
        lv = (counts['leave'] as num?)?.toInt() ?? 0;
        t = (counts['total'] as num?)?.toInt() ?? 0;
      }

      present += p;
      absent += a;
      late += l;
      leave += lv;
      total += t;

      daily.add(
        _AttendanceDaySummary(
          dateKey: date,
          present: p,
          absent: a,
          late: l,
          leave: lv,
          total: t,
        ),
      );
    }

    daily.sort((a, b) => b.dateKey.compareTo(a.dateKey));

    final rate = total <= 0 ? 0.0 : (present / total) * 100;

    return _AttendanceReport(
      classId: classId,
      sectionId: sectionId,
      range: range,
      totalStudents: totalStudents,
      present: present,
      absent: absent,
      late: late,
      leave: leave,
      total: total,
      attendanceRate: rate,
      daily: daily,
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() => _range = picked);
  }

  void _generate(String schoolId) {
    final classId = (_classId ?? '').trim();
    final sectionId = (_sectionId ?? '').trim();
    if (classId.isEmpty || sectionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class and section.')),
      );
      return;
    }

    setState(() {
      _future = _buildReport(
        schoolId: schoolId,
        classId: classId,
        sectionId: sectionId,
        range: _range,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF2F8FF);
    const accent = Color(0xFF3B82F6);

    final schoolAsync = ref.watch(currentSchoolProvider);
    final classesAsync = ref.watch(classes_stream.classesProvider);

    Widget decoratedDropdown<T>({
      required String label,
      required T? value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
      String? hintText,
    }) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            hint: hintText == null ? null : Text(hintText),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
    }

    return AdminLayout(
      title: 'Attendance Reports',
      body: Container(
        color: bg,
        child: schoolAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load school: $e')),
          data: (schoolDoc) {
            final schoolId = schoolDoc.id;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _FilterCard(
                  accent: accent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      classesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Failed to load classes: $e'),
                        data: (snap) {
                          final items = snap.docs
                              .map((d) {
                                final data = d.data();
                                final name = (data['name'] ?? d.id).toString();
                                return (id: d.id, name: name);
                              })
                              .toList(growable: false)
                            ..sort((a, b) => a.name.compareTo(b.name));

                          if (_classId == null && items.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(() => _classId = items.first.id);
                            });
                          }

                          return decoratedDropdown<String>(
                            label: 'Class',
                            value: _classId,
                            hintText: items.isEmpty ? 'No classes' : 'Select class',
                            items: [
                              for (final c in items)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _classId = v;
                                _sectionId = null;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_classId == null)
                        const Text(
                          'Select a class to load sections.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        )
                      else
                        ref.watch(sectionsProvider(_classId!)).when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text('Failed to load sections: $e'),
                              data: (snap) {
                                final sections = snap.docs
                                    .map((d) {
                                      final data = d.data();
                                      final name = (data['name'] ?? d.id).toString();
                                      return (id: d.id, name: name);
                                    })
                                    .toList(growable: false)
                                  ..sort((a, b) => a.name.compareTo(b.name));

                                if (_sectionId == null && sections.isNotEmpty) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    setState(() => _sectionId = sections.first.id);
                                  });
                                }

                                return decoratedDropdown<String>(
                                  label: 'Section',
                                  value: _sectionId,
                                  hintText:
                                      sections.isEmpty ? 'No sections' : 'Select section',
                                  items: [
                                    for (final s in sections)
                                      DropdownMenuItem(
                                        value: s.id,
                                        child: Text(s.name),
                                      ),
                                  ],
                                  onChanged: (v) {
                                    setState(() => _sectionId = v);
                                  },
                                );
                              },
                            ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickRange,
                        icon: const Icon(Icons.date_range_rounded),
                        label: Text(
                          'Date range: ${_dateKey(_range.start)} → ${_dateKey(_range.end)}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _generate(schoolId),
                        icon: const Icon(Icons.analytics_rounded),
                        label: const Text('Generate report'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_future == null)
                  const _EmptyState()
                else
                  FutureBuilder<_AttendanceReport>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: accent),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return _ErrorCard(message: snapshot.error.toString());
                      }
                      final report = snapshot.data;
                      if (report == null) {
                        return const _ErrorCard(message: 'No data');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  accent: accent,
                                  title: 'Total Students',
                                  value: '${report.totalStudents}',
                                  icon: Icons.groups_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  accent: accent,
                                  title: 'Attendance Rate',
                                  value: '${report.attendanceRate.toStringAsFixed(0)}%',
                                  icon: Icons.percent_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _FilterCard(
                            accent: accent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Class ${report.classId} • ${report.sectionId} summary',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _CountChip(
                                      label: 'Present',
                                      value: report.present,
                                      color: const Color(0xFF16A34A),
                                    ),
                                    _CountChip(
                                      label: 'Absent',
                                      value: report.absent,
                                      color: const Color(0xFFDC2626),
                                    ),
                                    _CountChip(
                                      label: 'Late',
                                      value: report.late,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                    _CountChip(
                                      label: 'Leave',
                                      value: report.leave,
                                      color: const Color(0xFF6366F1),
                                    ),
                                    _CountChip(
                                      label: 'Total Marked',
                                      value: report.total,
                                      color: accent,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Marked days in range: ${report.daily.length}',
                                  style: const TextStyle(color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _FilterCard(
                            accent: accent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Daily breakdown',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (report.daily.isEmpty)
                                  const Text(
                                    'No attendance was marked in this date range.',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  )
                                else
                                  ...report.daily.map(
                                    (d) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: accent.withAlpha(18),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                d.dateKey,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'P ${d.present}  A ${d.absent}  L ${d.late}  Lv ${d.leave}',
                                              style: const TextStyle(
                                                color: Color(0xFF374151),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceReport {
  const _AttendanceReport({
    required this.classId,
    required this.sectionId,
    required this.range,
    required this.totalStudents,
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.total,
    required this.attendanceRate,
    required this.daily,
  });

  final String classId;
  final String sectionId;
  final DateTimeRange range;

  final int totalStudents;
  final int present;
  final int absent;
  final int late;
  final int leave;
  final int total;

  final double attendanceRate;

  final List<_AttendanceDaySummary> daily;
}

class _AttendanceDaySummary {
  const _AttendanceDaySummary({
    required this.dateKey,
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.total,
  });

  final String dateKey;
  final int present;
  final int absent;
  final int late;
  final int leave;
  final int total;
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withAlpha(50)),
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.accent,
    required this.title,
    required this.value,
    required this.icon,
  });

  final Color accent;
  final String title;
  final String value;
  final IconData icon;

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
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const _FilterCard(
      accent: Color(0xFF3B82F6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate a report',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Pick a class, section and date range, then tap “Generate report”.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(90)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}
