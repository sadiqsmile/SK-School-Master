import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/academic/providers/academic_years_provider.dart';
import 'package:school_app/features/school_admin/academic/services/academic_year_service.dart';
import 'package:school_app/features/school_admin/academic/services/promotion_service.dart';
import 'package:school_app/features/school_admin/academic/services/student_academic_year_backfill_service.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/current_school_provider.dart';

class PromoteStudentsScreen extends ConsumerStatefulWidget {
  const PromoteStudentsScreen({super.key});

  @override
  ConsumerState<PromoteStudentsScreen> createState() => _PromoteStudentsScreenState();
}

class _PromoteStudentsScreenState extends ConsumerState<PromoteStudentsScreen> {
  String? _fromYear;
  String? _toYear;
  bool _running = false;
  bool _setActiveToYearAfterPromotion = true;

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(academicYearsProvider);
    final schoolAsync = ref.watch(currentSchoolProvider);
    final effectiveYear = ref.watch(effectiveAcademicYearIdProvider);

    return AdminLayout(
      title: 'Promote Students',
      body: schoolAsync.when(
        data: (schoolDoc) {
          final schoolId = schoolDoc.id;

          return yearsAsync.when(
            data: (snap) {
              final years = snap.docs.map((d) => d.id).toList();

              // If years collection is empty (or orderBy failed), fall back
              // to a computed current year.
              if (years.isEmpty) {
                years.add(effectiveYear);
              }

              years.sort((a, b) => b.compareTo(a));

              if (years.isNotEmpty) {
                // Prefer the school's active academic year when present.
                // This keeps promotion aligned with the year used across the app.
                final fromDefault = years.contains(effectiveYear)
                    ? effectiveYear
                    : (years.length >= 2 ? years[1] : years.first);
                final toDefault = _nextAcademicYearId(fromDefault);

                _fromYear ??= fromDefault;
                _toYear ??= toDefault;

                // Ensure the computed "next" year exists in the dropdown.
                if (_toYear != null && !years.contains(_toYear)) {
                  years.insert(0, _toYear!);
                }

                // Ensure active year is also selectable even if it wasn't saved yet.
                if (!years.contains(effectiveYear)) {
                  years.add(effectiveYear);
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'At the end of the academic year, students move to the next class (e.g. 5 → 6).\n'
                      'Class 10 students are marked as Graduated (archived, not deleted).',
                      style: TextStyle(height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String?>('from_$_fromYear'),
                      initialValue: _fromYear,
                      decoration: const InputDecoration(
                        labelText: 'From Academic Year',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final y in years)
                          DropdownMenuItem(value: y, child: Text(y)),
                      ],
                      onChanged: _running
                          ? null
                          : (v) => setState(() {
                                _fromYear = v;
                              }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String?>('to_$_toYear'),
                      initialValue: _toYear,
                      decoration: const InputDecoration(
                        labelText: 'To Academic Year',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final y in years)
                          DropdownMenuItem(value: y, child: Text(y)),
                      ],
                      onChanged: _running
                          ? null
                          : (v) => setState(() {
                                _toYear = v;
                              }),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _setActiveToYearAfterPromotion,
                      onChanged: _running
                          ? null
                          : (v) => setState(() {
                                _setActiveToYearAfterPromotion = v;
                              }),
                      title: const Text('Set active academic year to "To" after promotion'),
                      subtitle: const Text(
                        'This becomes the default year for new students and year-scoped flows.',
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: _running
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);

                              final from = _fromYear;
                              final to = _toYear;
                              if (from == null || to == null) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Select From and To academic years'),
                                  ),
                                );
                                return;
                              }

                              try {
                                await AcademicYearService().ensureAcademicYear(
                                  schoolId: schoolId,
                                  academicYearId: from,
                                );
                                await AcademicYearService().ensureAcademicYear(
                                  schoolId: schoolId,
                                  academicYearId: to,
                                );

                                // Keep the active year in sync with the admin's intent.
                                await AcademicYearService().setActiveAcademicYearId(
                                  schoolId: schoolId,
                                  academicYearId: from,
                                );

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Academic years saved. Active year: $from',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Failed to save academic years: $e')),
                                );
                              }
                            },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Academic Years (if new)'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _running
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final from = _fromYear;
                              if (from == null) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Select a "From" academic year first'),
                                  ),
                                );
                                return;
                              }

                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Backfill academicYear?'),
                                  content: Text(
                                    'This will set academicYear = $from for students where academicYear is missing.\n\n'
                                    'It will NOT overwrite students that already have an academicYear.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Backfill'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;

                              setState(() => _running = true);
                              try {
                                final result = await StudentAcademicYearBackfillService()
                                    .backfillMissingAcademicYear(
                                  schoolId: schoolId,
                                  academicYearId: from,
                                );

                                if (!context.mounted) return;
                                await showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Backfill complete'),
                                    content: Text(
                                      'Updated: ${result.updated}\n'
                                      'Skipped: ${result.skipped}\n'
                                      'Batches: ${result.batches}',
                                    ),
                                    actions: [
                                      FilledButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Backfill failed: $e')),
                                );
                              } finally {
                                if (mounted) setState(() => _running = false);
                              }
                            },
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text('Backfill missing academicYear (older students)'),
                    ),
                    const SizedBox(height: 20),
                    _PromotionRulesCard(),
                    const Spacer(),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _running
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final dialogContext = context;

                                final from = _fromYear;
                                final to = _toYear;
                                if (from == null || to == null) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Select From and To academic years'),
                                    ),
                                  );
                                  return;
                                }
                                if (from == to) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('From and To years must be different'),
                                    ),
                                  );
                                  return;
                                }

                                // Pre-check: warn if target classes are missing.
                                PromotionPrecheckResult? precheckResult;
                                try {
                                  precheckResult = await PromotionService().precheck(
                                    schoolId: schoolId,
                                    fromAcademicYear: from,
                                  );
                                } catch (_) {
                                  // Non-blocking: allow promotion even if precheck fails.
                                }

                                if (!dialogContext.mounted) return;

                                final missing =
                                    precheckResult?.missingTargetClassNames ?? const <String, int>{};
                                final missingLines = missing.entries
                                    .toList()
                                  ..sort((a, b) => b.value.compareTo(a.value));
                                final missingText = missingLines.isEmpty
                                    ? 'All required target classes exist.'
                                    : missingLines
                                        .map((e) => '${e.key}: ${e.value} students')
                                        .join('\n');

                                final confirmed = await showDialog<bool>(
                                  context: dialogContext,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Start promotion?'),
                                    content: Text(
                                      'Promote all students from $from to $to?\n\n'
                                      'This will update each student\'s class + academicYear and create a history snapshot.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Start'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true) return;

                                setState(() => _running = true);
                                try {
                                  // Show pre-check report (if any) before doing writes.
                                  final pc = precheckResult;
                                  if (pc != null && dialogContext.mounted) {
                                    final proceed = await showDialog<bool>(
                                      context: dialogContext,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Promotion pre-check'),
                                        content: Text(
                                          'Students in "$from": ${pc.totalStudents}\n'
                                          'Will promote: ${pc.willPromote}\n'
                                          'Will graduate: ${pc.willGraduate}\n'
                                          'Will skip: ${pc.willSkip}\n\n'
                                          'Missing target classes:\n$missingText\n\n'
                                          'Proceed anyway?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Proceed'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (proceed != true) {
                                      if (mounted) setState(() => _running = false);
                                      return;
                                    }
                                  }

                                  final result = await PromotionService().promoteAll(
                                    schoolId: schoolId,
                                    fromAcademicYear: from,
                                    toAcademicYear: to,
                                  );

                                  if (_setActiveToYearAfterPromotion) {
                                    await AcademicYearService().setActiveAcademicYearId(
                                      schoolId: schoolId,
                                      academicYearId: to,
                                    );
                                  }

                                  if (!dialogContext.mounted) return;

                                  await showDialog<void>(
                                    context: dialogContext,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Promotion complete'),
                                      content: Text(
                                        'Promoted: ${result.promoted}\n'
                                        'Graduated: ${result.graduated}\n'
                                        'Skipped: ${result.skipped}\n'
                                        'Batches: ${result.batches}',
                                      ),
                                      actions: [
                                        FilledButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Promotion failed: $e')),
                                  );
                                } finally {
                                  if (mounted) setState(() => _running = false);
                                }
                              },
                        icon: _running
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.trending_up_rounded),
                        label: Text(_running ? 'Promoting...' : 'Start Promotion'),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              // If academicYears collection is empty, orderBy('startYear') can
              // fail until docs exist. Provide a fallback UI.
              final fallback = ref.read(currentAcademicYearIdProvider);
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Academic years not set yet ($e).'),
                    const SizedBox(height: 12),
                    Text('Suggested current year: $fallback'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _running
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await AcademicYearService().ensureAcademicYear(
                                  schoolId: schoolId,
                                  academicYearId: fallback,
                                );
                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Academic year created.')),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                // Use captured messenger rather than accessing context after async.
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            },
                      child: const Text('Create Academic Year'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _PromotionRulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promotion mapping',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text('LKG → UKG'),
          Text('UKG → 1'),
          Text('1 → 2'),
          Text('2 → 3'),
          Text('3 → 4'),
          Text('4 → 5'),
          Text('5 → 6'),
          Text('6 → 7'),
          Text('7 → 8'),
          Text('8 → 9'),
          Text('9 → 10'),
          Text('10 → Graduated'),
        ],
      ),
    );
  }
}

String _nextAcademicYearId(String fromAcademicYearId) {
  // Expecting "YYYY-YYYY".
  final parts = fromAcademicYearId.split('-');
  if (parts.length == 2) {
    final start = int.tryParse(parts[0]);
    final end = int.tryParse(parts[1]);
    if (start != null && end != null) {
      return '${start + 1}-${end + 1}';
    }
  }

  final now = DateTime.now();
  final start = now.year;
  return '${start + 1}-${start + 2}';
}
