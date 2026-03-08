import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/classes/providers/classes_provider.dart' as classes_stream;
import 'package:school_app/features/school_admin/classes/providers/sections_provider.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/current_school_provider.dart';

class FeeReportsScreen extends ConsumerStatefulWidget {
  const FeeReportsScreen({super.key});

  @override
  ConsumerState<FeeReportsScreen> createState() => _FeeReportsScreenState();
}

class _FeeReportsScreenState extends ConsumerState<FeeReportsScreen> {
  String? _classId;
  String? _sectionId;

  Future<_FeeReport>? _future;

  num _readNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  Iterable<List<T>> _chunks<T>(List<T> items, int size) sync* {
    for (int i = 0; i < items.length; i += size) {
      yield items.sublist(i, (i + size).clamp(0, items.length));
    }
  }

  ({num collected, num pending}) _interpretFeeDoc(Map<String, dynamic> data) {
    // Best-effort parsing to support multiple shapes.
    // Preferred:
    // - totalAmount + balance
    // - OR paidAmount + balance
    // - OR status + amount

    final balance = data['balance'] ?? data['pendingAmount'];
    final pending = _readNum(balance);

    final paidAmount = data['paidAmount'];
    final collected = _readNum(paidAmount);

    if (collected > 0 || pending > 0) {
      return (collected: collected, pending: pending);
    }

    final status = (data['status'] ?? '').toString().toLowerCase().trim();
    final amount = _readNum(data['amount']);

    if (status == 'paid') {
      return (collected: amount, pending: 0);
    }

    if (status == 'pending' || status == 'due') {
      return (collected: 0, pending: amount);
    }

    // If we only have totalAmount + balance, infer collected.
    final totalAmount = _readNum(data['totalAmount']);
    if (totalAmount > 0 && pending > 0) {
      return (collected: (totalAmount - pending).clamp(0, totalAmount), pending: pending);
    }

    return (collected: 0, pending: 0);
  }

  Future<_FeeReport> _buildReport({
    required String schoolId,
    required String? classId,
    required String? sectionId,
  }) async {
    final db = FirebaseFirestore.instance;

    // Load students to map studentId -> class/section.
    final studentsSnap = await db
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .get();

    final Map<String, ({String classId, String sectionId})> studentClass = {};
    for (final doc in studentsSnap.docs) {
      final data = doc.data();
      final c = (data['classId'] ?? '').toString();
      final s = (data['section'] ?? '').toString();
      if (c.trim().isEmpty || s.trim().isEmpty) continue;
      studentClass[doc.id] = (classId: c, sectionId: s);
    }

    final String classFilter = (classId ?? '').trim();
    final String sectionFilter = (sectionId ?? '').trim();

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> feeDocs = [];

    final feesCol = db
        .collection('schools')
        .doc(schoolId)
        .collection('studentFees');

    if (classFilter.isNotEmpty && sectionFilter.isNotEmpty) {
      // Efficient path if studentFees doesn't include classId/section: query by studentId in batches.
      final studentIds = studentClass.entries
          .where((e) =>
              e.value.classId == classFilter &&
              e.value.sectionId == sectionFilter)
          .map((e) => e.key)
          .toList(growable: false);

      for (final chunk in _chunks(studentIds, 10)) {
        if (chunk.isEmpty) continue;
        final snap = await feesCol.where('studentId', whereIn: chunk).get();
        feeDocs.addAll(snap.docs);
      }
    } else {
      // No filter: load all fee docs.
      final snap = await feesCol.get();
      feeDocs.addAll(snap.docs);
    }

    num totalCollected = 0;
    num totalPending = 0;

    final Map<String, _FeeBucket> byClass = {};
    final Map<String, _FeeBucket> bySection = {};

    for (final doc in feeDocs) {
      final data = doc.data();
      final studentId = (data['studentId'] ?? doc.id).toString();
      final bucket = _interpretFeeDoc(data);

      // Apply filter (if we loaded all).
      final cls = studentClass[studentId];
      if (classFilter.isNotEmpty && sectionFilter.isNotEmpty) {
        if (cls == null) continue;
        if (cls.classId != classFilter || cls.sectionId != sectionFilter) continue;
      }

      totalCollected += bucket.collected;
      totalPending += bucket.pending;

      if (cls != null) {
        final classKey = cls.classId;
        final sectionKey = '${cls.classId}-${cls.sectionId}';

        byClass[classKey] =
            (byClass[classKey] ?? const _FeeBucket()).add(
          bucket.collected,
          bucket.pending,
        );
        bySection[sectionKey] =
            (bySection[sectionKey] ?? const _FeeBucket()).add(
          bucket.collected,
          bucket.pending,
        );
      }
    }

    final rate = (totalCollected + totalPending) <= 0
        ? 0.0
        : (totalCollected / (totalCollected + totalPending)) * 100;

    return _FeeReport(
      classId: classFilter,
      sectionId: sectionFilter,
      totalCollected: totalCollected,
      totalPending: totalPending,
      collectionRate: rate,
      byClass: byClass,
      bySection: bySection,
    );
  }

  void _generate(String schoolId) {
    setState(() {
      _future = _buildReport(
        schoolId: schoolId,
        classId: _classId,
        sectionId: _sectionId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF1FCFB);
    const accent = Color(0xFF14B8A6);

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
      title: 'Fee Reports',
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
                _Card(
                  borderColor: accent.withAlpha(60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Filters (optional)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
                          return decoratedDropdown<String?>(
                            label: 'Class (optional)',
                            value: _classId,
                            hintText: 'All classes',
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All classes'),
                              ),
                              for (final c in items)
                                DropdownMenuItem<String?>(
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
                          'Section filter becomes available after selecting a class.',
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

                                return decoratedDropdown<String?>(
                                  label: 'Section (optional)',
                                  value: _sectionId,
                                  hintText: 'All sections',
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All sections'),
                                    ),
                                    for (final s in sections)
                                      DropdownMenuItem<String?>(
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
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _generate(schoolId),
                        icon: const Icon(Icons.analytics_rounded),
                        label: const Text('Generate report'),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Note: Fee reports are based on the `studentFees` collection. If you haven\'t started recording student fees yet, totals may show as 0.',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_future == null)
                  const _HintCard(
                    text:
                        'Tap “Generate report” to calculate totals. Use class/section filters if you want a focused view.',
                  )
                else
                  FutureBuilder<_FeeReport>(
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
                        return _WarnCard(message: snapshot.error.toString());
                      }
                      final report = snapshot.data;
                      if (report == null) return const _WarnCard(message: 'No data');

                      String scope;
                      if (report.classId.isEmpty) {
                        scope = 'All classes';
                      } else if (report.sectionId.isEmpty) {
                        scope = 'Class ${report.classId}';
                      } else {
                        scope = 'Class ${report.classId}${report.sectionId}';
                      }

                      final topClasses = report.byClass.entries.toList(growable: false)
                        ..sort((a, b) => b.value.total.compareTo(a.value.total));
                      final topSections = report.bySection.entries.toList(growable: false)
                        ..sort((a, b) => b.value.total.compareTo(a.value.total));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _Stat(
                                  accent: accent,
                                  title: 'Total Collected',
                                  value: _currency(report.totalCollected),
                                  icon: Icons.check_circle_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Stat(
                                  accent: accent,
                                  title: 'Pending',
                                  value: _currency(report.totalPending),
                                  icon: Icons.timelapse_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _Card(
                            borderColor: accent.withAlpha(60),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Collection rate • $scope',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (report.collectionRate / 100).clamp(0, 1).toDouble(),
                                  minHeight: 10,
                                  backgroundColor: accent.withAlpha(20),
                                  valueColor: const AlwaysStoppedAnimation(accent),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${report.collectionRate.toStringAsFixed(0)}% collected',
                                  style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (report.classId.isEmpty) ...[
                            _Card(
                              borderColor: accent.withAlpha(60),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Top classes (by total amount)',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 10),
                                  if (topClasses.isEmpty)
                                    const Text('No fee data found.', style: TextStyle(color: Color(0xFF6B7280)))
                                  else
                                    ...topClasses.take(6).map(
                                      (e) => _RowItem(
                                        label: 'Class ${e.key}',
                                        collected: e.value.collected,
                                        pending: e.value.pending,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _Card(
                              borderColor: accent.withAlpha(60),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Top sections (by total amount)',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 10),
                                  if (topSections.isEmpty)
                                    const Text('No fee data found.', style: TextStyle(color: Color(0xFF6B7280)))
                                  else
                                    ...topSections.take(6).map(
                                      (e) => _RowItem(
                                        label: 'Section ${e.key}',
                                        collected: e.value.collected,
                                        pending: e.value.pending,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
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

String _currency(num v) {
  // Keep simple; can be replaced with intl later.
  final rounded = v.round();
  return '₹$rounded';
}

class _FeeReport {
  const _FeeReport({
    required this.classId,
    required this.sectionId,
    required this.totalCollected,
    required this.totalPending,
    required this.collectionRate,
    required this.byClass,
    required this.bySection,
  });

  final String classId;
  final String sectionId;

  final num totalCollected;
  final num totalPending;
  final double collectionRate;

  final Map<String, _FeeBucket> byClass;
  final Map<String, _FeeBucket> bySection;
}

class _FeeBucket {
  const _FeeBucket({this.collected = 0, this.pending = 0});

  final num collected;
  final num pending;

  num get total => collected + pending;

  _FeeBucket add(num c, num p) {
    return _FeeBucket(collected: collected + c, pending: pending + p);
  }
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
          Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.collected,
    required this.pending,
  });

  final String label;
  final num collected;
  final num pending;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '${_currency(collected)} collected',
            style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 10),
          Text(
            '${_currency(pending)} pending',
            style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Card(
      borderColor: const Color(0x3314B8A6),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF14B8A6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarnCard extends StatelessWidget {
  const _WarnCard({required this.message});

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
