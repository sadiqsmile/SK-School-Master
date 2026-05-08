import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/marks_service.dart';

class ResultsScreen extends StatefulWidget {
  final String schoolId;

  const ResultsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final MarksService _service = MarksService();

  String? selectedExam;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        title: const Text("Results Management"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // export template
            },
            icon: const Icon(Icons.download),
          ),
          IconButton(
            onPressed: () {
              // import marks
            },
            icon: const Icon(Icons.upload_file),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getResults(widget.schoolId),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return _emptyState();
          }

          final examNames = docs.map((e) {
            final data = e.data() as Map<String, dynamic>;
            return data['examName'].toString();
          }).toSet().toList();

          selectedExam ??= examNames.first;

          final filtered = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['examName'] == selectedExam;
          }).toList();

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: selectedExam,
                  decoration: _inputDecoration("Select Exam"),
                  items: examNames.map((exam) {
                    return DropdownMenuItem(
                      value: exam,
                      child: Text(exam),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedExam = v;
                    });
                  },
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final percentage =
                        ((data['marksObtained'] ?? 0) /
                                (data['maxMarks'] ?? 100)) *
                            100;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
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
                                      data['studentName'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xff111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${data['subjectName']} • ${data['className']} ${data['section']}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: data['published'] == true
                                      ? const Color(0xffDCFCE7)
                                      : const Color(0xffFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  data['published'] == true
                                      ? "Published"
                                      : "Draft",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: data['published'] == true
                                        ? const Color(0xff166534)
                                        : const Color(0xff92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: _resultStat(
                                  "Marks",
                                  "${data['marksObtained']}/${data['maxMarks']}",
                                ),
                              ),
                              Expanded(
                                child: _resultStat(
                                  "Grade",
                                  data['grade'] ?? '-',
                                ),
                              ),
                              Expanded(
                                child: _resultStat(
                                  "Percent",
                                  "${percentage.toStringAsFixed(0)}%",
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff5B5FEF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: data['published'] == true
                                  ? null
                                  : () {
                                      _service.publishResult(
                                        schoolId: widget.schoolId,
                                        resultId: doc.id,
                                      );
                                    },
                              child: Text(
                                data['published'] == true
                                    ? "Published"
                                    : "Publish Result",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
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

  Widget _resultStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xff111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
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
              Icons.assessment_rounded,
              size: 42,
              color: Color(0xff5B5FEF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Results Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Student results will appear here\nonce marks are entered.",
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
