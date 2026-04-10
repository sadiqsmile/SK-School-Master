import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;

  const AnalyticsDashboardScreen({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
  });

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends State<AnalyticsDashboardScreen> {

  DateTime selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  List<DateTime> months = List.generate(
    12,
    (index) => DateTime(DateTime.now().year, index + 1),
  );

  String getMonthYear(DateTime date) {
    const m = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return "${m[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Analytics"),
      ),

      body: Column(
        children: [

          /// ✅ DROPDOWN (VISIBLE)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DateTime>(
                  isExpanded: true,
                  value: selectedMonth,
                  items: months.map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(getMonthYear(month)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value!;
                    });
                  },
                ),
              ),
            ),
          ),

          /// ✅ DATA + GRAPH
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('attendance')
                  .where('className', isEqualTo: widget.className)
                  .where('section', isEqualTo: widget.section)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                Map<String, List<Map<String, dynamic>>> groupedData = {};

                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = data['date'];

                  groupedData.putIfAbsent(date, () => []);
                  groupedData[date]!.add(data);
                }

                List<String> sortedDates = groupedData.keys.toList()
                  ..sort((a, b) =>
                      DateTime.parse(a).compareTo(DateTime.parse(b)));

                List<BarChartGroupData> barGroups = [];
                List<String> labels = [];

                int totalPresent = 0;
                int totalAbsent = 0;
                int totalHoliday = 0;

                int index = 0;

                for (var date in sortedDates) {
                  final d = DateTime.parse(date);

                  if (d.month != selectedMonth.month ||
                      d.year != selectedMonth.year) continue;

                  if (d.weekday == DateTime.sunday) continue;

                  final dayDocs = groupedData[date]!;

                  int p = 0;
                  int a = 0;
                  bool isHoliday = false;

                  for (var data in dayDocs) {
                    if (data['isHoliday'] == true) {
                      isHoliday = true;
                      break;
                    }
                  }

                  if (isHoliday) {
                    totalHoliday++;
                    continue;
                  }

                  for (var data in dayDocs) {
                    final students =
                        Map<String, dynamic>.from(data['students'] ?? {});

                    students.forEach((key, value) {
                      if (value == 'P' || value == true) p++;
                      if (value == 'A' || value == false) a++;
                    });
                  }

                  totalPresent += p;
                  totalAbsent += a;

                  int total = p + a;
                  if (total == 0) continue;

                  double percent = (p / total) * 100;

                  barGroups.add(
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: percent,
                          color: Colors.blue,
                          width: 14,
                        ),
                      ],
                    ),
                  );

                  labels.add("${d.day}");
                  index++;
                }

                double overall =
                    (totalPresent + totalAbsent) == 0
                        ? 0
                        : (totalPresent /
                                (totalPresent + totalAbsent)) *
                            100;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      /// HEADER
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${overall.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text("Overall Attendance",
                                style:
                                    TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// GRAPH
                      SizedBox(
                        height: 250,
                        child: BarChart(
                          BarChartData(
                            maxY: 100,
                            barGroups: barGroups,
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 20,
                                  getTitlesWidget:
                                      (value, meta) =>
                                          Text("${value.toInt()}%"),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget:
                                      (value, meta) {
                                    int i = value.toInt();
                                    if (i >= labels.length)
                                      return const SizedBox();
                                    return Text(labels[i]);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// STATS
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _stat("P", totalPresent, Colors.green),
                          _stat("A", totalAbsent, Colors.red),
                          _stat("H", totalHoliday, Colors.orange),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}