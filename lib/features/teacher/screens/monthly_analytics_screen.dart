import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyAnalyticsScreen extends StatelessWidget {
  final String schoolId;
  final String className;
  final String section;

  const MonthlyAnalyticsScreen({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Analytics")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('attendance')
            .where('className', isEqualTo: className)
            .where('section', isEqualTo: section)
            .where(
              'date',
              isGreaterThanOrEqualTo:
                  startOfMonth.toIso8601String().split('T')[0],
            )
            .where(
              'date',
              isLessThanOrEqualTo:
                  endOfMonth.toIso8601String().split('T')[0],
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          int present = 0;
          int absent = 0;
          int holiday = 0;
          int totalDays = 0;

          List<double> values = [];
          List<String> labels = [];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final dateStr = data['date'] ?? "";
            if (dateStr.isEmpty) continue;
            final date = DateTime.tryParse(dateStr);
            if (date == null) continue;
            if (date.weekday == DateTime.sunday) continue;

            final day = dateStr.split('-').last;
            final students = Map<String, dynamic>.from(data['students'] ?? {});
            final isHolidayDay = data['isHoliday'] ?? false;
            if (isHolidayDay) {
              holiday++;
              continue;
            }
            int p = 0;
            int a = 0;
            students.forEach((key, value) {
              if (value == 'P') p++;
              if (value == 'A') a++;
            });
            double percent = (p + a) == 0 ? 0 : (p / (p + a)) * 100;
            values.add(percent);
            labels.add(day);
            present += p;
            absent += a;
            totalDays++;
          }

          /// 🔥 SORT DATA (IMPORTANT)
          final combined = List.generate(values.length, (i) => {
                'day': int.parse(labels[i]),
                'value': values[i],
              });

          combined.sort(
  (a, b) => (a['day'] as int).compareTo(b['day'] as int),
);

          values =
              combined.map((e) => e['value'] as double).toList();
          labels =
              combined.map((e) => e['day'].toString()).toList();

          double overallPercent =
              (present + absent) == 0
                  ? 0
                  : (present / (present + absent)) * 100;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// 🔥 MAIN CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${overallPercent.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Overall Attendance",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔥 GRAPH
                if (values.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: CustomPaint(
                      painter: _BarChartPainter(
                        values: values,
                        labels: labels,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                /// 🔥 P / A / H COUNTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _count("P", present, Colors.green),
                    _count("A", absent, Colors.red),
                    _count("H", holiday, Colors.orange),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _count(String label, int value, Color color) {
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

/// 🔥 CLEAN BAR GRAPH
class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _BarChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (values.length * 2);

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = i * barWidth * 2;
      final barHeight = (values[i] / 100) * size.height;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            size.height - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(6),
        ),
        paint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 10, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x, size.height + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}