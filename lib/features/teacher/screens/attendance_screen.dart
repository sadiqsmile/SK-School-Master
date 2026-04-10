import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'student_history_screen.dart';
import 'monthly_analytics_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final String className;
  final String section;

  const AttendanceScreen({
    super.key,
    required this.className,
    required this.section,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, String?> attendance = {};
  bool isSaving = false;
  bool isHoliday = false;

  Future<String> _getSchoolId() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc['schoolId'];
  }

  /// ---------------- SAVE ----------------
  Future<void> _confirmSave() async {
    final total = attendance.length;
    final present = attendance.values.where((e) => e == 'P').length;

    if (isHoliday || present == total) {
      final result = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Warning"),
          content: Text(
            isHoliday
                ? "You marked this day as Holiday"
                : "All students are Present",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Return"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Save"),
            ),
          ],
        ),
      );

      if (result != true) return;
    }

    await _saveAttendance();
  }

  Future<void> _saveAttendance() async {
    setState(() => isSaving = true);

    final schoolId = await _getSchoolId();
    final today = DateTime.now().toIso8601String().split('T')[0];

    /// UNIQUE DOC ID
    final docId = "${widget.className}_${widget.section}_$today";

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .doc(docId)
        .set({
      'className': widget.className,
      'section': widget.section,
      'date': today,
      'students': attendance,
      'isHoliday': isHoliday,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() => isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance Saved / Updated ✅")),
    );

    Navigator.pop(context);
  }

  /// ---------------- PIE CHART (FIX 2) ----------------
  Widget _buildPieChart(int present, int absent, int totalStudents) {
    if (isHoliday) {
      return _holidayCard();
    }
    if (totalStudents == 0) {
      return _emptyCard();
    }
    double presentPercent = (present / totalStudents) * 100;
    double absentPercent = (absent / totalStudents) * 100;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: _glassDecoration(),
      child: Row(
        children: [
          /// LEFT SIDE COUNTS
          Column(
            children: [
              Text("P = $present",
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("A = $absent",
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 20),
          /// PIE CHART
          Expanded(
            child: SizedBox(
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 45,
                      sections: [
                        PieChartSectionData(
                          value: present.toDouble(),
                          color: Colors.green,
                          title: "${presentPercent.toStringAsFixed(0)}%",
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: absent.toDouble(),
                          color: Colors.red,
                          title: "${absentPercent.toStringAsFixed(0)}%",
                          radius: 50,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${presentPercent.toStringAsFixed(0)}%",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Glass effect (FIX 3) ---
  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
        )
      ],
    );
  }

  // --- Holiday card (FIX 4) ---
  Widget _holidayCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(),
      child: const Column(
        children: [
          Text("Holiday",
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("H",
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange)),
        ],
      ),
    );
  }

  // --- Empty card for 0 students ---
  Widget _emptyCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(),
      child: const Center(
        child: Text("No attendance marked yet"),
      ),
    );
  }

  /// ---------------- REAL TOGGLE (FIX 6) ----------------
  Widget _buildSwitch(String? status, VoidCallback onTap) {
    final isPresent = status == 'P';

    return GestureDetector(
      onTap: isHoliday ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 70,
        height: 34,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: status == null
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : isPresent
                    ? [Color(0xFF22C55E), Color(0xFF4ADE80)]
                    : [Color(0xFFEF4444), Color(0xFFF87171)],
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          alignment:
              isPresent ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text("${widget.className} - ${widget.section}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () async {
              final schoolId = await _getSchoolId();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MonthlyAnalyticsScreen(
                    schoolId: schoolId,
                    className: widget.className,
                    section: widget.section,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: _getSchoolId(),
        builder: (context, schoolSnapshot) {
          if (!schoolSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final schoolId = schoolSnapshot.data as String;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .collection('students')
                .where('className', isEqualTo: widget.className)
                .where('section', isEqualTo: widget.section)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final students = snapshot.data!.docs;

              for (var s in students) {
                attendance.putIfAbsent(s.id, () => null);
              }

                int totalStudents = attendance.length;
                int present = attendance.values.where((e) => e == 'P').length;
                int absent = attendance.values.where((e) => e == 'A').length;
                int unmarked = totalStudents - (present + absent);
                double presentPercent = totalStudents == 0 ? 0 : (present / totalStudents) * 100;
                double absentPercent = totalStudents == 0 ? 0 : (absent / totalStudents) * 100;

                return Column(
                children: [
                  /// Buttons
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                setState(() {
                                  isHoliday = false;
                                  for (var key in attendance.keys) {
                                    attendance[key] = 'P';
                                  }
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: Text("Present All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E42), Color(0xFFFDE68A)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                setState(() {
                                  isHoliday = true;
                                  for (var key in attendance.keys) {
                                    attendance[key] = null;
                                  }
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: Text("Holiday", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Pie Chart
                  _buildPieChart(present, absent, totalStudents),

                  /// Counts (add unmarked)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("P = $present", style: const TextStyle(color: Colors.green)),
                        Text("A = $absent", style: const TextStyle(color: Colors.red)),
                        Text("- = $unmarked", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),

                  /// List
                  Expanded(
                    child: ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final doc = students[index];
                        final name = doc['name'];

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: _glassDecoration(),
                          child: ListTile(
                            tileColor: Colors.transparent,
                            title: Text(name),
                            onTap: () async {
                              final schoolId = await _getSchoolId();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentHistoryScreen(
                                    studentId: doc.id,
                                    studentName: name,
                                    schoolId: schoolId,
                                  ),
                                ),
                              );
                            },
                            trailing: _buildSwitch(
                              attendance[doc.id],
                              () {
                                setState(() {
                                  final current = attendance[doc.id];
                                  if (current == null) {
                                    attendance[doc.id] = 'P';
                                  } else if (current == 'P') {
                                    attendance[doc.id] = 'A';
                                  } else {
                                    attendance[doc.id] = null;
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  /// Save Button (premium look)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: isSaving ? null : _confirmSave,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Save Attendance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}