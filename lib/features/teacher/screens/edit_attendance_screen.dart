import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAttendanceScreen extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;
  final String date;

  const EditAttendanceScreen({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
    required this.date,
  });

  @override
  State<EditAttendanceScreen> createState() =>
      _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
    bool isHoliday = false;
    bool hasLoaded = false;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  Map<String, String?> attendance = {};
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  // Removed isHoliday logic, now only UI lock for Sunday

  int present = 0;
  int absent = 0;

  @override
  void initState() {
    super.initState();
    if (!hasLoaded) {
      _loadData();
      hasLoaded = true;
    }
  }

  void calculate() {
    // 🔥 IF ALL ARE H → RESET
    if (attendance.values.isNotEmpty &&
        attendance.values.every((v) => v == 'H')) {
      present = 0;
      absent = 0;
      return;
    }
    present = attendance.values.where((e) => e == 'P').length;
    absent = attendance.values.where((e) => e == 'A').length;
  }

  Future<void> _loadData() async {
    final studentSnap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .where('className', isEqualTo: widget.className)
        .where('section', isEqualTo: widget.section)
        .get();

    students = studentSnap.docs.map((e) {
      return {
        'id': e.id,
        'name': e['name'],
      };
    }).toList();

    final attSnap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .doc("${widget.className}_${widget.section}_${widget.date}")
        .get();

    if (attSnap.exists) {
      final data = attSnap.data()!;
      final saved = Map<String, dynamic>.from(data['students'] ?? {});

      saved.forEach((key, value) {
        attendance[key] = value.toString();
      });
      // If all values are H, treat as holiday and update all
      if (attendance.values.isNotEmpty && attendance.values.every((v) => v == 'H')) {
        isHoliday = true;
        attendance = {
          for (var key in attendance.keys) key: 'H'
        };
      }
    }
    if (isHoliday) {
      attendance = {
        for (var key in attendance.keys) key: 'H'
      };
    }

    for (var s in students) {
      attendance.putIfAbsent(s['id'], () => 'A');
    }

    calculate();
    setState(() => isLoading = false);
  }

  Future<void> _updateAttendance() async {
    final selected = DateTime.parse(widget.date);
    final isSunday = selected.weekday == DateTime.sunday;
    if (isSunday) return;

    final docId = "${widget.className}_${widget.section}_${widget.date}";
    Map<String, String> finalAttendance = {};
    for (var s in students) {
      finalAttendance[s['id']] = attendance[s['id']] ?? 'A';
    }

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .doc(docId)
        .set({
      'className': widget.className,
      'section': widget.section,
      'date': widget.date,
      'students': finalAttendance,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updated Successfully ✅")),
    );

    Navigator.pop(context, true);
  }

  void toggle(String id) {
    final selected = DateTime.parse(widget.date);
    final isSunday = selected.weekday == DateTime.sunday;
    if (isSunday) return;
    // Protect toggle if all are H (holiday)
    if (attendance.values.isNotEmpty && attendance.values.every((v) => v == 'H')) return;
    setState(() {
      if (attendance[id] == 'P') {
        attendance[id] = 'A';
      } else {
        attendance[id] = 'P';
      }
      calculate();
    });
  }

  Widget buildToggle(String id) {
    final value = attendance[id];

    Color bgColor;
    String text;

    if (value == 'P') {
      bgColor = const Color(0xFF4CAF50); // Green
      text = 'P';
    } else if (value == 'A') {
      bgColor = const Color(0xFFE53935); // Red
      text = 'A';
    } else {
      bgColor = const Color(0xFF1E88E5); // Blue (H)
      text = 'H';
    }

    return GestureDetector(
      onTap: () {
        if (isHoliday) return;

        setState(() {
          if (value == 'P') {
            attendance[id] = 'A';
          } else {
            attendance[id] = 'P';
          }
          calculate();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 70,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: value == 'P'
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: bgColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget headerCard() {
    double percent = (present + absent) == 0
        ? 0
        : (present / (present + absent)) * 100;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(widget.date, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            (attendance.values.isNotEmpty && attendance.values.every((v) => v == 'H'))
                ? "Holiday"
                : "${percent.toStringAsFixed(0)}%",
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.white54,
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          if (attendance.values.isNotEmpty && attendance.values.every((v) => v == 'H'))
            const Text(
              "H",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          const Text("Attendance", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          if (!(attendance.values.isNotEmpty && attendance.values.every((v) => v == 'H')))
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("P = $present", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("A = $absent", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = DateTime.parse(widget.date);
    final isSunday = selected.weekday == DateTime.sunday;
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit ${widget.date}"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isSunday
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Sunday", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text("No Attendance", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    headerCard(),
                    // SEARCH UI
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search student...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    // BUTTONS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSunday ? null : () {
                                setState(() {
                                  isHoliday = false; // 🔥 CRITICAL FIX
                                  attendance.updateAll((k, v) => 'P');
                                  calculate();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: const Text("Present All"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSunday ? null : () {
                                setState(() {
                                  isHoliday = true;
                                  attendance.updateAll((k, v) => 'H');
                                  calculate();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue),
                              child: const Text("Holiday", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // FILTERED STUDENT LIST
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final filteredStudents = students.where((s) {
                            final name = s['name'].toString().toLowerCase();
                            return name.contains(searchQuery);
                          }).toList();
                          return ListView.builder(
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, i) {
                              final s = filteredStudents[i];
                              print("Student "+s['name']+" = "+(attendance[s['id']] ?? 'null'));
                              return ListTile(
                                title: Text(s['name']),
                                trailing: buildToggle(s['id']),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // SAVE
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ElevatedButton(
                        onPressed: isSunday ? null : _updateAttendance,
                        child: const Text("Update Attendance"),
                      ),
                    )
                  ],
                ),
    );
  }
}