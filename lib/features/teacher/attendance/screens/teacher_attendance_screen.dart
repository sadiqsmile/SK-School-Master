import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:school_app/core/helpers/student_helper.dart';
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
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        _isOffline = results.isEmpty ||
            (results.length == 1 &&
                results.first == ConnectivityResult.none);
      });
    });
  }

  Widget _quickBtn(
    String studentId,
    AttendanceStatus status,
    Color color,
  ) {
    final selected = _statuses[studentId] == status;

    return Expanded(
      child: GestureDetector(
        onTap: _isSaving
            ? null
            : () {
                setState(() {
                  _statuses[studentId] = status;
                });
              },
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? color
                : Colors.grey.shade200,
            borderRadius:
                BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              status.label[0],
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.black,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _dateKey(DateTime dt) {
    final y =
        dt.year.toString().padLeft(4, '0');
    final m =
        dt.month.toString().padLeft(2, '0');
    final d =
        dt.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }

  String _prettyDate(DateTime dt) {
    const months = [
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
      'Dec'
    ];

    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _statusColor(
      AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.leave:
        return Colors.blue;
    }
  }

  void _markAllPresent(
      Iterable<String> ids) {
    setState(() {
      for (final id in ids) {
        _statuses[id] =
            AttendanceStatus.present;
      }
    });
  }

  void _markAllHoliday(
      Iterable<String> ids) {
    setState(() {
      for (final id in ids) {
        _statuses[id] =
            AttendanceStatus.leave;
      }
    });
  }

  Future<void> _submit() async {
    final auth =
        ref.read(authStateProvider).value;

    if (auth == null) return;

    setState(() => _isSaving = true);

    try {
      final school = await ref
          .read(currentSchoolProvider.future);

      final allHoliday =
          _statuses.isNotEmpty &&
              _statuses.values.every(
                (e) =>
                    e ==
                    AttendanceStatus.leave,
              );

     await TeacherAttendanceService()
    .submitAttendance(
  schoolId: school.id,
  teacherUid: auth.uid,
  dateKey: _dateKey(DateTime.now()),
  classId: widget.classId,
  sectionId: widget.sectionId,
  statuses: Map.from(_statuses),
);

      FirestoreSyncTracker.instance
          .notifyWriteQueued();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            allHoliday
                ? "Holiday Saved"
                : "Attendance Saved",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignments =
        ref.watch(
            teacherAssignmentsProvider);

    final isAssigned =
        assignments.any(
      (a) =>
          a.classId ==
              widget.classId &&
          a.sectionId ==
              widget.sectionId,
    );

    if (!isAssigned) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text("Attendance"),
        ),
        body: const Center(
          child: Text(
              "Not assigned"),
        ),
      );
    }

    final studentsAsync = ref.watch(
      studentsByClassSectionProvider(
        TeacherClassSectionKey(
          classId: widget.classId,
          sectionId:
              widget.sectionId,
        ),
      ),
    );

    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Attendance"),
        actions: const [
          FirestoreSyncStatusAction()
        ],
      ),
      body: studentsAsync.when(
        loading: () => const Center(
          child:
              CircularProgressIndicator(),
        ),
        error: (e, _) =>
            Center(child: Text("$e")),
        data: (snapshot) {
          final docs = snapshot.docs;

          for (final doc in docs) {
            _statuses.putIfAbsent(
              doc.id,
              () => AttendanceStatus
                  .present,
            );
          }

          return Column(
            children: [
              if (_isOffline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.orange.shade100,
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Offline Mode — Attendance will sync automatically',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.all(
                        12),
                child: Text(
                  "Class ${widget.classId}${widget.sectionId} • ${_prettyDate(today)}",
                ),
              ),

              Expanded(
                child:
                    ListView.builder(
                  itemCount:
                      docs.length,
                  itemBuilder:
                      (context, i) {
                    final doc =
                        docs[i];

                   final name =

    StudentHelper
        .name(doc);




                    final status =
                        _statuses[
                            doc.id]!;

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal:
                            10,
                        vertical: 5,
                      ),
                      child:
                          ListTile(
                        
                        
                       leading:
    CircleAvatar(

  backgroundColor:
      Colors.deepPurple
          .withOpacity(0.12),

  backgroundImage:

      StudentHelper
              .hasPhoto(
                  doc)

          ? NetworkImage(

              StudentHelper
                  .photo(
                      doc),
            )

          : null,

  child:

      StudentHelper
              .hasPhoto(
                  doc)

          ? null

          : Text(

              StudentHelper
                  .initial(
                      doc),
            ),
),

title:
    Text(
  name,
),





                        subtitle:
                            Row(
                          children: [
                            _quickBtn(
                              doc.id,
                              AttendanceStatus.present,
                              Colors.green,
                            ),
                            const SizedBox(
                                width:
                                    6),
                            _quickBtn(
                              doc.id,
                              AttendanceStatus.absent,
                              Colors.red,
                            ),
                            const SizedBox(
                                width:
                                    6),
                            _quickBtn(
                              doc.id,
                              AttendanceStatus.leave,
                              Colors.orange,
                            ),
                          ],
                        ),
                        trailing:
                            Text(
                          status
                              .label,
                          style:
                              TextStyle(
                            color:
                                _statusColor(
                              status,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                          12),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed: () =>
                              _markAllPresent(
                            docs.map(
                              (e) =>
                                  e.id,
                            ),
                          ),
                          child: const Text(
                              "Present All"),
                        ),
                      ),
                      const SizedBox(
                          width: 10),
                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed: () =>
                              _markAllHoliday(
                            docs.map(
                              (e) =>
                                  e.id,
                            ),
                          ),
                          child: const Text(
                              "Holiday"),
                        ),
                      ),
                      const SizedBox(
                          width: 10),
                      Expanded(
                        child:
                            ElevatedButton(
                          onPressed:
                              _isSaving
                                  ? null
                                  : _submit,
                          child: Text(
                            _isSaving
                                ? "Saving..."
                                : "Save",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}