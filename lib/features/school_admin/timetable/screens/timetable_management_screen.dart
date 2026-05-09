import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../timetable/services/timetable_service.dart';

class TimetableManagementScreen extends StatefulWidget {
  final String schoolId;

  const TimetableManagementScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<TimetableManagementScreen> createState() =>
      _TimetableManagementScreenState();
}

class _TimetableManagementScreenState extends State<TimetableManagementScreen> {
  final TimetableService _service = TimetableService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text("Timetable Management"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff5B5FEF),
        onPressed: _showAddTimetableSheet,
        icon: const Icon(Icons.add),
        label: const Text("Add Period"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getTimetable(widget.schoolId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${data['subjectName']} • ${data['periodName']}",
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${data['className']} - ${data['section']}",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _service.deleteTimetable(
                              schoolId: widget.schoolId,
                              timetableId: doc.id,
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _badge(data['day'] ?? ''),
                        const SizedBox(width: 10),
                        _badge("${data['startTime']} - ${data['endTime']}"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        data['teacherName'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xff5B5FEF),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddTimetableSheet() {
    final periodController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();
    final teacherController = TextEditingController();
    final subjectController = TextEditingController();

    String selectedDay = "Monday";
    QueryDocumentSnapshot? selectedClass;
    String? selectedSection;

    final days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Add Timetable",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(height: 28),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('schools')
                          .doc(widget.schoolId)
                          .collection('classes')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final docs = snapshot.data!.docs;
                        return DropdownButtonFormField<QueryDocumentSnapshot>(
                          value: selectedClass,
                          decoration: _inputDecoration("Select Class"),
                          items: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc,
                              child: Text(data['className']),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setSheetState(() {
                              selectedClass = v;
                              selectedSection = null;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    if (selectedClass != null)
                      DropdownButtonFormField<String>(
                        value: selectedSection,
                        decoration: _inputDecoration("Select Section"),
                        items: List<String>.from(
                          (selectedClass!.data()
                                  as Map<String, dynamic>)['sections'] ??
                              [],
                        ).map((section) {
                          return DropdownMenuItem(
                            value: section,
                            child: Text(section),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setSheetState(() => selectedSection = v);
                        },
                      ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: _inputDecoration("Select Day"),
                      items: days.map((day) {
                        return DropdownMenuItem(value: day, child: Text(day));
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setSheetState(() => selectedDay = v);
                      },
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: periodController,
                      decoration: _inputDecoration("Period Name"),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startController,
                            decoration: _inputDecoration("Start Time"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endController,
                            decoration: _inputDecoration("End Time"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: subjectController,
                      decoration: _inputDecoration("Subject Name"),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: teacherController,
                      decoration: _inputDecoration("Teacher Name"),
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff5B5FEF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (selectedClass == null ||
                              selectedSection == null) {
                            return;
                          }
                          final classData =
                              selectedClass!.data() as Map<String, dynamic>;
                          await _service.addTimetable(
                            schoolId: widget.schoolId,
                            data: {
                              "classId": classData['classId'],
                              "className": classData['className'],
                              "section": selectedSection,
                              "day": selectedDay,
                              "periodName": periodController.text.trim(),
                              "startTime": startController.text.trim(),
                              "endTime": endController.text.trim(),
                              "subjectName": subjectController.text.trim(),
                              "teacherName": teacherController.text.trim(),
                            },
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Save Timetable",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xffF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffEEF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xff5B5FEF),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 90,
            width: 90,
            decoration: const BoxDecoration(
              color: Color(0xffEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_outlined,
              size: 42,
              color: Color(0xff5B5FEF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Timetable Added",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Class timetable periods\nwill appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
