// features/teacher/attendance/screens/teacher_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/teacher/attendance/models/attendance_status.dart';
import 'package:school_app/features/teacher/attendance/providers/students_by_class_section_provider.dart';
import 'package:school_app/features/teacher/attendance/services/teacher_attendance_service.dart';
import 'package:school_app/features/teacher/providers/teacher_profile_provider.dart';
import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({
    super.key,
    required this.classId,
    required this.sectionId,
  });

  final String classId;
  final String sectionId;

  @override
  ConsumerState<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState
    extends ConsumerState<TeacherAttendanceScreen> {
  final _statuses = <String, AttendanceStatus>{};
  bool _isSaving = false;

  String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Color _statusColor(AttendanceStatus s) {
    return switch (s) {
      AttendanceStatus.present => const Color(0xFF16A34A),
      AttendanceStatus.absent => const Color(0xFFDC2626),
      AttendanceStatus.late => const Color(0xFFF59E0B),
      AttendanceStatus.leave => const Color(0xFF6366F1),
    };
  }

  String _prettyDate(DateTime dt) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dd = dt.day.toString().padLeft(2, '0');
    final m = months[dt.month - 1];
    return '$dd $m ${dt.year}';
  }

  Future<void> _pickStatus(String studentId) async {
    final current = _statuses[studentId] ?? AttendanceStatus.present;

    final chosen = await showModalBottomSheet<AttendanceStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Set status',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              for (final s in AttendanceStatus.values)
                ListTile(
                  leading: Icon(Icons.circle, color: _statusColor(s)),
                  title: Text(s.label),
                  trailing: s == current
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.of(context).pop(s),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen == null) return;
    if (!mounted) return;
    setState(() => _statuses[studentId] = chosen);
  }

  void _markAllPresent(Iterable<String> studentIds) {
    setState(() {
      for (final id in studentIds) {
        _statuses[id] = AttendanceStatus.present;
      }
    });
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final auth = ref.read(authStateProvider).value;
    if (auth == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You are not logged in.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final school = await ref.read(currentSchoolProvider.future);
      final dateKey = _dateKey(DateTime.now());

      await TeacherAttendanceService().submitAttendance(
        schoolId: school.id,
        teacherUid: auth.uid,
        dateKey: dateKey,
        classId: widget.classId,
        sectionId: widget.sectionId,
        statuses: Map<String, AttendanceStatus>.from(_statuses),
      );

      int present = 0;
      int absent = 0;
      int late = 0;
      int leave = 0;
      for (final s in _statuses.values) {
        switch (s) {
          case AttendanceStatus.present:
            present++;
          case AttendanceStatus.absent:
            absent++;
          case AttendanceStatus.late:
            late++;
          case AttendanceStatus.leave:
            leave++;
        }
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Attendance Submitted'),
            content: Text(
              'Present: $present\n'
              'Absent: $absent\n'
              'Late: $late\n'
              'Leave: $leave',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      navigator.pop();
    } on AttendanceAlreadyMarkedException {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Attendance already marked for this class/section today.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to submit attendance: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(teacherAssignmentsProvider);
    final isAssigned = assignments.any(
      (a) => a.classId == widget.classId && a.sectionId == widget.sectionId,
    );

    if (!isAssigned) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Attendance • ${widget.classId} - ${widget.sectionId}'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'You are not assigned to this class/section.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final studentsAsync = ref.watch(
      studentsByClassSectionProvider(
        TeacherClassSectionKey(
          classId: widget.classId,
          sectionId: widget.sectionId,
        ),
      ),
    );

    final date = DateTime.now();
    final dateKey = _dateKey(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Attendance"),
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load students: $e')),
        data: (snapshot) {
          final docs = snapshot.docs;

          // Ensure every student has a status default.
          for (final doc in docs) {
            _statuses.putIfAbsent(doc.id, () => AttendanceStatus.present);
          }

          if (docs.isEmpty) {
            return const Center(
              child: Text('No students found for this class/section.'),
            );
          }

          int present = 0;
          int absent = 0;
          int late = 0;
          int leave = 0;
          for (final doc in docs) {
            final s = _statuses[doc.id] ?? AttendanceStatus.present;
            switch (s) {
              case AttendanceStatus.present:
                present++;
              case AttendanceStatus.absent:
                absent++;
              case AttendanceStatus.late:
                late++;
              case AttendanceStatus.leave:
                leave++;
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Class ${widget.classId}${widget.sectionId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${_prettyDate(date)}  •  Students: ${docs.length}',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CountChip(
                          label: 'Present',
                          value: present,
                          color: _statusColor(AttendanceStatus.present),
                        ),
                        _CountChip(
                          label: 'Absent',
                          value: absent,
                          color: _statusColor(AttendanceStatus.absent),
                        ),
                        _CountChip(
                          label: 'Late',
                          value: late,
                          color: _statusColor(AttendanceStatus.late),
                        ),
                        _CountChip(
                          label: 'Leave',
                          value: leave,
                          color: _statusColor(AttendanceStatus.leave),
                        ),
                        _CountChip(
                          label: 'Total',
                          value: docs.length,
                          color: const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () => _markAllPresent(
                                      docs.map((d) => d.id),
                                    ),
                            icon: const Icon(Icons.done_all_rounded),
                            label: const Text('Mark All Present'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _submit,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(_isSaving
                                ? 'Submitting...'
                                : 'Submit Attendance'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tip: swipe → present/absent, tap → late/leave. Default is Present.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saves to: $dateKey / class_${widget.classId}_${widget.sectionId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();
                    final name = (data['name'] ?? '').toString();
                    final admissionNo = (data['admissionNo'] ?? doc.id).toString();

                    final status = _statuses[doc.id] ?? AttendanceStatus.present;
                    final statusColor = _statusColor(status);

                    return Dismissible(
                      key: ValueKey<String>('att_${doc.id}'),
                      direction: _isSaving
                          ? DismissDirection.none
                          : DismissDirection.horizontal,
                      background: Container(
                        color: _statusColor(AttendanceStatus.present),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text(
                          'PRESENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      secondaryBackground: Container(
                        color: _statusColor(AttendanceStatus.absent),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text(
                          'ABSENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          setState(() =>
                              _statuses[doc.id] = AttendanceStatus.present);
                        } else if (direction == DismissDirection.endToStart) {
                          setState(() =>
                              _statuses[doc.id] = AttendanceStatus.absent);
                        }
                        // Don't actually dismiss the tile.
                        return false;
                      },
                      child: ListTile(
                        onTap: _isSaving ? null : () => _pickStatus(doc.id),
                        title: Text(name.isEmpty ? 'Student' : name),
                        subtitle: Text('Admission: $admissionNo'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusColor.withAlpha(80)),
                          ),
                          child: Text(
                            status.label.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      backgroundColor: color.withAlpha(18),
      side: BorderSide(color: color.withAlpha(60)),
    );
  }
}
