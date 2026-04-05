import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/teacher/attendance/models/attendance_status.dart';
import 'package:school_app/features/teacher/attendance/providers/students_by_class_section_provider.dart';
import 'package:school_app/features/teacher/attendance/services/teacher_attendance_service.dart';
import 'package:school_app/features/teacher/providers/teacher_profile_provider.dart';
import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/core/offline/firestore_sync_tracker.dart';
import 'package:school_app/core/offline/firestore_sync_status_action.dart';

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

  // ✅ QUICK BUTTON
  Widget _quickBtn(
    String studentId,
    AttendanceStatus status,
    Color color,
  ) {
    final isSelected = _statuses[studentId] == status;

    return Expanded(
      child: GestureDetector(
        onTap: _isSaving
            ? null
            : () => setState(() => _statuses[studentId] = status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              status.label[0],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

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
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickStatus(String studentId) async {
    final chosen = await showModalBottomSheet<AttendanceStatus>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AttendanceStatus.values.map((s) {
            return ListTile(
              title: Text(s.label),
              onTap: () => Navigator.pop(context, s),
            );
          }).toList(),
        ),
      ),
    );

    if (chosen != null) {
      setState(() => _statuses[studentId] = chosen);
    }
  }

  void _markAllPresent(Iterable<String> ids) {
    setState(() {
      for (var id in ids) {
        _statuses[id] = AttendanceStatus.present;
      }
    });
  }

  Future<void> _submit() async {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;

    setState(() => _isSaving = true);

    try {
      final school = await ref.read(currentSchoolProvider.future);

      await TeacherAttendanceService().submitAttendance(
        schoolId: school.id,
        teacherUid: auth.uid,
        dateKey: _dateKey(DateTime.now()),
        classId: widget.classId,
        sectionId: widget.sectionId,
        statuses: Map.from(_statuses),
      );

      FirestoreSyncTracker.instance.notifyWriteQueued();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance Saved")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(teacherAssignmentsProvider);

    final isAssigned = assignments.any(
      (a) => a.classId == widget.classId && a.sectionId == widget.sectionId,
    );

    if (!isAssigned) {
      return Scaffold(
        appBar: AppBar(title: const Text("Attendance")),
        body: const Center(child: Text("Not assigned")),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Attendance"),
        actions: const [FirestoreSyncStatusAction()],
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (snapshot) {
          final docs = snapshot.docs;

          for (var doc in docs) {
            _statuses.putIfAbsent(doc.id, () => AttendanceStatus.present);
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Class ${widget.classId}${widget.sectionId} • ${_prettyDate(date)}",
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final name = doc['name'] ?? '';

                    final status = _statuses[doc.id]!;
                    final color = _statusColor(status);

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(name),
                        subtitle: Row(
                          children: [
                            _quickBtn(doc.id, AttendanceStatus.present, Colors.green),
                            const SizedBox(width: 6),
                            _quickBtn(doc.id, AttendanceStatus.absent, Colors.red),
                            const SizedBox(width: 6),
                            _quickBtn(doc.id, AttendanceStatus.late, Colors.orange),
                          ],
                        ),
                        trailing: Text(
                          status.label,
                          style: TextStyle(color: color),
                        ),
                        onTap: () => _pickStatus(doc.id),
                      ),
                    );
                  },
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _markAllPresent(docs.map((e) => e.id)),
                          child: const Text("All Present"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          child: Text(_isSaving ? "Saving..." : "Save"),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}