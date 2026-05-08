import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ParentMarksAnalyticsScreen extends StatelessWidget {
  final String schoolId;
  final String studentId;
  final Map<String, dynamic> studentData;

  const ParentMarksAnalyticsScreen({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.studentData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Marks Analytics"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('exam_results')
            .where('studentId', isEqualTo: studentId)
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

          double totalObtained = 0;
          double totalMax = 0;
          Map<String, double> subjectPercentages = {};

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final obtained = (data['marksObtained'] ?? 0).toDouble();
            final max = (data['maxMarks'] ?? 0).toDouble();

            totalObtained += obtained;
            totalMax += max;

            final percentage = max == 0 ? 0 : (obtained / max) * 100;
            subjectPercentages[data['subjectName']] = percentage.toDouble();
          }

          final overall =
              totalMax == 0 ? 0.0 : (totalObtained / totalMax) * 100;

          String bestSubject = '';
          double bestValue = 0;
          String weakSubject = '';
          double weakValue = 100;

          subjectPercentages.forEach((subject, value) {
            if (value > bestValue) {
              bestValue = value;
              bestSubject = subject;
            }
            if (value < weakValue) {
              weakValue = value;
              weakSubject = subject;
            }
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Overall Performance",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 50,
                          sectionsSpace: 4,
                          sections: [
                            PieChartSectionData(
                              value: overall,
                              title: "${overall.toStringAsFixed(0)}%",
                              radius: 70,
                              color: const Color(0xff5B5FEF),
                              titleStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: 100 - overall,
                              title: "",
                              radius: 70,
                              color: const Color(0xffE5E7EB),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${overall.toStringAsFixed(1)}% Average",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff111827),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      title: "Best Subject",
                      value: bestSubject,
                      subtitle: "${bestValue.toStringAsFixed(1)}%",
                      color: const Color(0xffDCFCE7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      title: "Weak Subject",
                      value: weakSubject,
                      subtitle: "${weakValue.toStringAsFixed(1)}%",
                      color: const Color(0xffFEE2E2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Subject Performance",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ...subjectPercentages.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text("${entry.value.toStringAsFixed(1)}%"),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LinearProgressIndicator(
                                value: entry.value / 100,
                                minHeight: 12,
                                backgroundColor: const Color(0xffE5E7EB),
                                color: const Color(0xff5B5FEF),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle),
        ],
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
              Icons.analytics_outlined,
              size: 42,
              color: Color(0xff5B5FEF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Analytics Available",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Published marks analytics\nwill appear here.",
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
