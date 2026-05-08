import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'attendance_screen.dart';

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
    extends State<AnalyticsDashboardScreen> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

                // Totals and chart data must be inside builder for UI updates
                final docs = snapshot.data!.docs;
                int totalPresent = 0;
                int totalAbsent = 0;
                int totalHoliday = 0;
                Map<int, double> dailyPercent = {};
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dateStr = data['date'];
                  if (dateStr == null) continue;
                  final parsed = DateTime.tryParse(dateStr);
                  if (parsed == null) continue;
                  if (parsed.month != selectedMonth.month) continue;
                  final students = Map<String, dynamic>.from(data['students'] ?? {});
                  int p = students.values.where((e) => e == 'P').length;
                  int a = students.values.where((e) => e == 'A').length;
                  int h = students.values.where((e) => e == 'H').length;
                  totalPresent += p;
                  totalAbsent += a;
                  totalHoliday += h;
                  int total = p + a;
                  double percent = total == 0 ? 0 : (p / total) * 100;
                  dailyPercent[parsed.day] = percent;
                }
                print("DATA COUNT: "+docs.length.toString());
                print("DAILY MAP: $dailyPercent");

                double overall = dailyPercent.isEmpty
                    ? 0
                    : dailyPercent.values.reduce((a, b) => a + b) / dailyPercent.length;
                print("OVERALL = $overall");
                _controller.forward(from: 0);

                if (dailyPercent.isEmpty) {
                  return const Center(child: Text("No chart data"));
                }

                List<int> days = dailyPercent.keys.toList()..sort();
                List<double> percents = days.map((d) => dailyPercent[d]!).toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      // HEADER with animation (🔥 NEW GRADIENT CONTAINER)
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
                            /// 🔥 OVERALL %
                            AnimatedBuilder(
                              animation: _animation,
                              builder: (_, __) {
                                return Text(
                                  "${(overall * _animation.value).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            /// 🔥 CHART with percent above bar, horizontal scroll, 7 bars visible, premium spacing (SAFE STRUCTURE)
                            SizedBox(
                              height: 220,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(days.length, (i) {
                                    final percent = percents[i];
                                    final day = days[i];
                                    final date = DateTime(selectedMonth.year, selectedMonth.month, day);
                                    final isSunday = date.weekday == DateTime.sunday;
                                    final isHoliday = percent == 0;
                                    double displayPercent = percent;
                                    if (isSunday || isHoliday) {
                                      displayPercent = 100;
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () {},
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              // % TEXT
                                              Text(
                                                "${percent.toStringAsFixed(0)}%",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              // BAR
                                              AnimatedBuilder(
                                                animation: _animation,
                                                builder: (context, child) {
                                                  return Container(
                                                    height: (displayPercent / 100) * 120 * _animation.value,
                                                    width: 12,
                                                    decoration: BoxDecoration(
                                                      color: isSunday
                                                          ? Colors.red
                                                          : isHoliday
                                                              ? Colors.orange
                                                              : Colors.white,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 6),
                                              // DAY
                                              Text(
                                                "$day",
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// 🔥 P A H as button style
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "P: $totalPresent",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "A: $totalAbsent",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "H: $totalHoliday",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Optionally remove stats row if not needed
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
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }
}