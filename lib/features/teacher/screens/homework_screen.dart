import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../homework/services/homework_service.dart';

class HomeworkScreen extends StatefulWidget {
  final String schoolId;
  final String teacherId;
  final Map<String, dynamic> teacherData;

  const HomeworkScreen({
    super.key,
    required this.schoolId,
    required this.teacherId,
    required this.teacherData,
  });

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final HomeworkService _service = HomeworkService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text("Homework"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff5B5FEF),
        onPressed: _showAddHomeworkSheet,
        icon: const Icon(Icons.add),
        label: const Text("Add Homework"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getHomework(widget.schoolId),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
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
                                data['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff111827),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${data['subjectName']} • ${data['className']}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _service.deleteHomework(
                              schoolId: widget.schoolId,
                              homeworkId: doc.id,
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
                    Text(
                      data['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
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
                            "Due: ${data['dueDate']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xff5B5FEF),
                            ),
                          ),
                        ),
                      ],
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

  void _showAddHomeworkSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dueDateController = TextEditingController();
    Map<String, dynamic>? selectedClass;
    List<String> selectedSections = [];

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
                      "Add Homework",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: titleController,
                      decoration: _inputDecoration("Homework Title"),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: descriptionController,
                      maxLines: 5,
                      decoration: _inputDecoration("Description"),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedClass,
                      decoration: _inputDecoration("Select Class"),
                      items: List<Map<String, dynamic>>.from(
                        widget.teacherData['assignedClasses'] ?? [],
                      ).map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item['className']),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setSheetState(() {
                          selectedClass = v;
                          selectedSections.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    if (selectedClass != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select Sections",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List<String>.from(
                              selectedClass!['sections'] ?? [],
                            ).map((section) {
                              final isSelected =
                                  selectedSections.contains(section);
                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    if (isSelected) {
                                      selectedSections.remove(section);
                                    } else {
                                      selectedSections.add(section);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xff5B5FEF)
                                        : const Color(0xffEEF2FF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    section,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xff5B5FEF),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: dueDateController,
                      readOnly: true,
                      decoration: _inputDecoration("Due Date").copyWith(
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) {
                          dueDateController.text =
                              "${picked.day}/${picked.month}/${picked.year}";
                        }
                      },
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
                          final subject = widget.teacherData['subject'];
                          await _service.addHomework(
                            schoolId: widget.schoolId,
                            data: {
                              "title": titleController.text.trim(),
                              "description": descriptionController.text.trim(),
                              "subjectId": subject?['subjectId'],
                              "subjectName": subject?['name'],
                              "classId": selectedClass?['classId'],
                              "className": selectedClass?['className'],
                              "sections": selectedSections,
                              "teacherId": widget.teacherId,
                              "teacherName": widget.teacherData['name'],
                              "dueDate": dueDateController.text,
                            },
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Publish Homework",
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
              Icons.menu_book_outlined,
              size: 42,
              color: Color(0xff5B5FEF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Homework Added",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Homework created by teachers\nwill appear here.",
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
