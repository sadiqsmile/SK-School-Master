import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/classes/providers/classes_provider.dart' as classes_stream;
import 'package:school_app/features/school_admin/classes/providers/sections_provider.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/current_school_provider.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  String? _classId;
  String? _sectionId;

  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  Future<_AttendanceReport>? _future;

  String _dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _classKey(String c, String s) => "class_${c}_$s";

  List<String> _getDates() {
    final days = _range.end.difference(_range.start).inDays;
    return List.generate(
        days + 1,
        (i) => _dateKey(_range.start.add(Duration(days: i))));
  }

  Future<_AttendanceReport> _buildReport(String schoolId) async {
    final db = FirebaseFirestore.instance;

    final dates = _getDates();
    final classKey = _classKey(_classId!, _sectionId!);

    int present = 0, absent = 0, late = 0, leave = 0, total = 0;

    List<_Day> daily = [];

    for (final date in dates) {
      final doc = await db
          .collection('schools')
          .doc(schoolId)
          .collection('attendance')
          .doc(date)
          .collection('meta')
          .doc(classKey)
          .get();

      if (!doc.exists) continue;

      final data = doc.data() as Map<String, dynamic>;
      final c = data['counts'] ?? {};

      int p = c['present'] ?? 0;
      int a = c['absent'] ?? 0;
      int l = c['late'] ?? 0;
      int lv = c['leave'] ?? 0;
      int t = c['total'] ?? 0;

      present += p;
      absent += a;
      late += l;
      leave += lv;
      total += t;

      daily.add(_Day(date, p, a, l, lv));
    }

    double rate = total == 0 ? 0 : (present / total) * 100;

    return _AttendanceReport(
        present, absent, late, leave, total, rate, daily);
  }

  void _generate(String schoolId) {
    if (_classId == null || _sectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select class & section")));
      return;
    }

    setState(() {
      _future = _buildReport(schoolId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);
    final classes = ref.watch(classes_stream.classesProvider);

    return AdminLayout(
      title: "Attendance Reports",
      body: schoolAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (schoolDoc) {
          if (schoolDoc.id.isEmpty) {
            return const Center(child: Text("Invalid school"));
          }

          final schoolId = schoolDoc.id;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Card(
                child: Column(
                  children: [
                    /// CLASS
                    classes.when(
                      data: (snap) => DropdownButtonFormField<String>(
                        value: _classId,
                        hint: const Text("Select Class"),
                        items: snap.docs.map((d) {
                          final data =
                              d.data() as Map<String, dynamic>?;
                          final name =
                              (data?['name'] ?? d.id).toString();

                          return DropdownMenuItem(
                            value: d.id,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _classId = v;
                            _sectionId = null;
                          });
                        },
                      ),
                      loading: () =>
                          const CircularProgressIndicator(),
                      error: (e, _) => Text("$e"),
                    ),

                    const SizedBox(height: 10),

                    /// SECTION
                    if (_classId == null)
                      const Text("Select class first")
                    else
                      ref.watch(sectionsProvider(_classId!)).when(
                            data: (snap) =>
                                DropdownButtonFormField<String>(
                              value: _sectionId,
                              hint:
                                  const Text("Select Section"),
                              items: snap.docs.map((d) {
                                final data =
                                    d.data() as Map<String, dynamic>?;
                                final name =
                                    (data?['name'] ?? d.id)
                                        .toString();

                                return DropdownMenuItem(
                                  value: d.id,
                                  child: Text(name),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _sectionId = v),
                            ),
                            loading: () =>
                                const CircularProgressIndicator(),
                            error: (e, _) => Text("$e"),
                          ),

                    const SizedBox(height: 10),

                    /// DATE
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _range = picked);
                        }
                      },
                      child: Text(
                          "${_dateKey(_range.start)} → ${_dateKey(_range.end)}"),
                    ),

                    const SizedBox(height: 10),

                    /// BUTTON
                    ElevatedButton(
                      onPressed: () => _generate(schoolId),
                      child: const Text("Generate Report"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// RESULT
              if (_future == null)
                const Text("Generate report")
              else
                FutureBuilder<_AttendanceReport>(
                  future: _future,
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final r = snap.data!;

                    return Column(
                      children: [
                        Text(
                            "Attendance: ${r.rate.toStringAsFixed(1)}%"),
                        const SizedBox(height: 10),
                        Text(
                            "P:${r.present} A:${r.absent} L:${r.late} Lv:${r.leave}"),
                        const SizedBox(height: 10),
                        ...r.daily.map((d) => ListTile(
                              title: Text(d.date),
                              trailing: Text(
                                  "P${d.p} A${d.a} L${d.l} Lv${d.lv}"),
                            ))
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceReport {
  final int present, absent, late, leave, total;
  final double rate;
  final List<_Day> daily;

  _AttendanceReport(this.present, this.absent, this.late,
      this.leave, this.total, this.rate, this.daily);
}

class _Day {
  final String date;
  final int p, a, l, lv;

  _Day(this.date, this.p, this.a, this.l, this.lv);
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}