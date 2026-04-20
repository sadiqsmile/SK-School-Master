import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;
  final String? selectedDate;

  const AttendanceScreen({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
    this.selectedDate,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, String> studentNames = {};
  Map<String, String?> attendance = {};

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  int present = 0;
  int absent = 0;
  bool isSaving = false;

  late String today;

  bool get isSunday => DateTime.now().weekday == DateTime.sunday;

  @override
  void initState() {
    super.initState();
    today = widget.selectedDate ?? DateTime.now().toIso8601String().split('T')[0];
    loadData();
  }

  // 🔥 LOAD DATA
  Future<void> loadData() async {
    final studentsSnap = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .where('className', isEqualTo: widget.className)
        .where('section', isEqualTo: widget.section)
        .get();

    for (var doc in studentsSnap.docs) {
      studentNames[doc.id] = doc['name'] ?? doc.id;
      attendance.putIfAbsent(doc.id, () => 'A');
    }

    final docId = "${widget.className}_${widget.section}_$today";

    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .doc(docId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final saved = Map<String, dynamic>.from(data['students']);
      attendance = saved.map((k, v) => MapEntry(k, v.toString()));
    }

    calculate();
    setState(() {});
  }

  // 🔥 CALCULATE
  void calculate() {
    present = attendance.values.where((e) => e == 'P').length;
    absent = attendance.values.where((e) => e == 'A').length;
  }

  // 🔥 SAVE
  Future<void> saveAttendance() async {
    if (isSunday) return;

    setState(() => isSaving = true);

    final docId = "${widget.className}_${widget.section}_$today";

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .doc(docId)
        .set({
      'date': today,
      'className': widget.className,
      'section': widget.section,
      'students': attendance,
      'isHoliday': false,
    });

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance Saved")),
    );
  }

  // 🔥 TOGGLE
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

  // 🔥 TOP CARD
  Widget topCard() {
    double percent =
        (present + absent) == 0 ? 0 : (present / (present + absent)) * 100;

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
          Text(today, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text("${percent.toStringAsFixed(0)}%",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const Text("Attendance", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("P = $present",
                  style: const TextStyle(color: Colors.white)),
              Text("A = $absent",
                  style: const TextStyle(color: Colors.white)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isSunday) {
      return Scaffold(
        appBar: AppBar(title: Text("${widget.className}-${widget.section}")),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Sunday",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Attendance Disabled"),
              ],
            ),
          ),
        ),
      );
    }

    final filteredKeys = attendance.keys.where((id) {
      final name =
          studentNames[id]?.toLowerCase() ?? id.toLowerCase();
      return name.contains(searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className}-${widget.section}"),
      ),
      body: Column(
        children: [
          topCard(),

          // 🔍 SEARCH
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
                prefixIcon: const Icon(Icons.search),
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
                    onPressed: () {
                      setState(() {
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
                    onPressed: () {
                      setState(() {
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

          const SizedBox(height: 10),

          // STUDENTS
          Expanded(
            child: ListView(
              children: filteredKeys.map((id) {
                return ListTile(
                  title: Text(studentNames[id] ?? id),
                  trailing: buildToggle(id),
                );
              }).toList(),
            ),
          ),

          // SAVE
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: isSaving ? null : saveAttendance,
              child: isSaving
                  ? const CircularProgressIndicator()
                  : const Text("Save Attendance"),
            ),
          )
        ],
      ),
    );
  }
}