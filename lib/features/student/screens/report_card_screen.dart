import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportCardScreen extends StatefulWidget {
  final String schoolId;
  final String studentId;

  const ReportCardScreen({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  String? selectedExam;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        title: const Text("Report Card"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('exam_results')
            .where('studentId', isEqualTo: widget.studentId)
            .where('published', isEqualTo: true)
            .snapshots(),

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

          final examDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['examName'] == selectedExam;
          }).toList();

          final firstData = examDocs.isNotEmpty
              ? examDocs.first.data() as Map<String, dynamic>
              : <String, dynamic>{};

          double totalObtained = 0.0;
          double totalMax = 0.0;

          for (final doc in examDocs) {
            final data = doc.data() as Map<String, dynamic>;
            totalObtained += (data['marksObtained'] ?? 0).toDouble();
            totalMax += (data['maxMarks'] ?? 0).toDouble();
          }

          final double percentage =
              totalMax == 0 ? 0.0 : (totalObtained / totalMax) * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
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

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: const BoxDecoration(
                          color: Color(0xffEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 34,
                          color: Color(0xff5B5FEF),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "SK SCHOOL MASTER",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff111827),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        selectedExam ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          Expanded(
                            child: _topStat(
                              "Total",
                              "${totalObtained.toStringAsFixed(0)}/${totalMax.toStringAsFixed(0)}",
                            ),
                          ),
                          Expanded(
                            child: _topStat(
                              "Percent",
                              "${percentage.toStringAsFixed(1)}%",
                            ),
                          ),
                          Expanded(
                            child: _topStat(
                              "Result",
                              percentage >= 35 ? "PASS" : "FAIL",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff5B5FEF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            _downloadPdf(
                              examName: selectedExam ?? '',
                              studentName: firstData['studentName'] ?? '',
                              examDocs: examDocs,
                              totalObtained: totalObtained,
                              totalMax: totalMax,
                              percentage: percentage,
                            );
                          },
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Download Report Card",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      ...examDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xffF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['subjectName'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Grade: ${data['grade']}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${data['marksObtained']}/${data['maxMarks']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff5B5FEF),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['remarks'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _topStat(String label, String value) {
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
      fillColor: Colors.white,
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
              Icons.assignment_rounded,
              size: 42,
              color: Color(0xff5B5FEF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Report Cards",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Published results will appear here\nonce released by school admin.",
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

  Future<void> _downloadPdf({
    required String examName,
    required String studentName,
    required List<QueryDocumentSnapshot> examDocs,
    required double totalObtained,
    required double totalMax,
    required double percentage,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        "SK SCHOOL MASTER",
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        examName,
                        style: const pw.TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Student Name",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(studentName),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Percentage",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text("${percentage.toStringAsFixed(1)}%"),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                      children: [
                        _pdfCell("Subject", bold: true),
                        _pdfCell("Marks", bold: true),
                        _pdfCell("Grade", bold: true),
                        _pdfCell("Remarks", bold: true),
                      ],
                    ),
                    ...examDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return pw.TableRow(
                        children: [
                          _pdfCell(data['subjectName'] ?? ''),
                          _pdfCell("${data['marksObtained']}/${data['maxMarks']}"),
                          _pdfCell(data['grade'] ?? ''),
                          _pdfCell(data['remarks'] ?? ''),
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 30),

                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Total",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        "${totalObtained.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 50),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 6),
                        pw.Text("Class Teacher"),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 120, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 6),
                        pw.Text("Principal"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
