import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddPeriodScreen extends StatefulWidget {

  final String schoolId;
  final String classId;
  final String sectionId;

  const AddPeriodScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.sectionId,
  });

  @override
  State<AddPeriodScreen> createState() =>
      _AddPeriodScreenState();
}

class _AddPeriodScreenState
    extends State<AddPeriodScreen> {

  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];

  String? selectedDay;

  int period = 1;

  String? selectedTeacherId;
  String? selectedTeacherName;

  String? selectedSubject;

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  bool isSaving = false;

  String _formatTime(TimeOfDay t) {

    final h =
        t.hour.toString().padLeft(2, '0');

    final m =
        t.minute.toString().padLeft(2, '0');

    return "$h:$m";
  }

  Future<void> _pickStartTime() async {

    final picked = await showTimePicker(
      context: context,
      initialTime:
          const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() => startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {

    final picked = await showTimePicker(
      context: context,
      initialTime:
          const TimeOfDay(hour: 9, minute: 45),
    );

    if (picked != null) {
      setState(() => endTime = picked);
    }
  }

  Future<void> _save() async {

    if (selectedDay == null ||
        selectedTeacherId == null ||
        selectedSubject == null ||
        startTime == null ||
        endTime == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Fill all fields",
          ),
        ),
      );

      return;
    }

    setState(() => isSaving = true);

    try {

      final docId =
          "${widget.classId}_${widget.sectionId}";

      final docRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('timetables')
          .doc(docId);

      final doc = await docRef.get();

      Map<String, dynamic> timetable = {};

      if (doc.exists) {
        timetable =
            doc.data()?['days']
                as Map<String, dynamic>? ?? {};
      }

      final currentPeriods =
          List<Map<String, dynamic>>.from(
        timetable[selectedDay] ?? [],
      );

      // ✅ PERIOD CLASH CHECK
      final clash = currentPeriods.any((e) {

        return e['period'] == period;

      });

      if (clash) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Period already exists",
            ),
          ),
        );

        setState(() => isSaving = false);

        return;
      }

      currentPeriods.add({

        "period": period,

        "subject": selectedSubject,

        "teacherId": selectedTeacherId,

        "teacherName": selectedTeacherName,

        "startTime":
            _formatTime(startTime!),

        "endTime":
            _formatTime(endTime!),
      });

      currentPeriods.sort((a, b) {

        return a['period']
            .compareTo(b['period']);

      });

      timetable[selectedDay!] = currentPeriods;

      await docRef.set({

        "classId": widget.classId,

        "sectionId": widget.sectionId,

        "days": timetable,

        "updatedAt":
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Period Added Successfully ✅",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Period"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: 500),

            child: Column(
              children: [

                DropdownButtonFormField<String>(
                  value: selectedDay,

                  decoration: InputDecoration(
                    labelText: "Day",

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  items: days.map((e) {

                    return DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    );

                  }).toList(),

                  onChanged: (v) {
                    setState(() => selectedDay = v);
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<int>(
                  value: period,

                  decoration: InputDecoration(
                    labelText: "Period",

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  items: List.generate(10, (i) {

                    final p = i + 1;

                    return DropdownMenuItem(
                      value: p,
                      child: Text("Period $p"),
                    );

                  }),

                  onChanged: (v) {
                    if (v != null) {
                      setState(() => period = v);
                    }
                  },
                ),

                const SizedBox(height: 18),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(widget.schoolId)
                      .collection('teachers')
                      .snapshots(),

                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {

                      return const LinearProgressIndicator();
                    }

                    final docs = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: selectedTeacherId,

                      decoration: InputDecoration(
                        labelText: "Teacher",

                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),

                      items: docs.map((doc) {

                        final data =
                            doc.data()
                                as Map<String, dynamic>;

                        return DropdownMenuItem(
                          value: doc.id,

                          child: Text(
                            data['name'] ?? '',
                          ),
                        );

                      }).toList(),

                      onChanged: (v) {

                        if (v == null) return;

                        final teacher =
                            docs.firstWhere(
                          (e) => e.id == v,
                        );

                        final data =
                            teacher.data()
                                as Map<String, dynamic>;

                        setState(() {

                          selectedTeacherId = v;

                          selectedTeacherName =
                              data['name'];

                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 18),

                TextField(
                  onChanged: (v) {
                    selectedSubject = v;
                  },

                  decoration: InputDecoration(
                    labelText: "Subject",

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton(

                        onPressed:
                            _pickStartTime,

                        child: Text(

                          startTime == null
                              ? "Start Time"
                              : _formatTime(
                                  startTime!,
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: OutlinedButton(

                        onPressed:
                            _pickEndTime,

                        child: Text(

                          endTime == null
                              ? "End Time"
                              : _formatTime(
                                  endTime!,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton(
                    onPressed:
                        isSaving ? null : _save,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xff5B5FEF),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),

                    child:
                        isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Save Period",

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
