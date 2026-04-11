import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom Toggle Widget
Widget customToggle(String? status, VoidCallback onTap) {
  final isPresent = status == 'P';
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 90,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: status == null
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : isPresent
                  ? [Colors.green, Colors.greenAccent]
                  : [Colors.red, Colors.redAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment:
            isPresent ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status ?? "-",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

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
  Map<String, String?> attendance = {};
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  // New variables for analytics and search
  int present = 0;
  int absent = 0;
  TextEditingController searchController = TextEditingController();
  String search = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void calculate() {
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
        .where('className', isEqualTo: widget.className)
        .where('section', isEqualTo: widget.section)
        .where('date', isEqualTo: widget.date)
        .get();

    if (attSnap.docs.isNotEmpty) {
      final data = attSnap.docs.first.data();
      final saved = Map<String, dynamic>.from(data['students'] ?? {});
      saved.forEach((key, value) {
        if (value == true) {
          attendance[key] = 'P';
        } else if (value == false) {
          attendance[key] = 'A';
        } else {
          attendance[key] = value;
        }
      });
    }

    students.forEach((s) {
      attendance.putIfAbsent(s['id'], () => null);
    });
    calculate();
    setState(() => isLoading = false);
  }

  Future<void> _updateAttendance() async {
    final docId = "${widget.className}_${widget.section}_${widget.date}";
    Map<String, String?> finalAttendance = {};
    for (var s in students) {
      final id = s['id'];
      finalAttendance[id] = attendance[id] ?? 'A';
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updated Successfully ✅")),
    );
    Navigator.pop(context, true);
  }

  void _toggle(String id) {
    final current = attendance[id];
    setState(() {
      if (current == null) {
        attendance[id] = 'P';
      } else if (current == 'P') {
        attendance[id] = 'A';
      } else {
        attendance[id] = null;
      }
      calculate();
    });
  }

  Widget headerCard() {
    double percent = (present + absent) == 0
        ? 0
        : (present / (present + absent)) * 100;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            widget.date,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            "${percent.toStringAsFixed(0)}%",
            style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          const Text("Attendance",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("P = $present",
                  style: const TextStyle(color: Colors.green)),
              Text("A = $absent",
                  style: const TextStyle(color: Colors.red)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = students.where((s) {
      return s['name'].toLowerCase().contains(search);
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit ${widget.date}"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                headerCard(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Search student...",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        search = value.toLowerCase();
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              for (var key in attendance.keys) {
                                attendance[key] = 'P';
                              }
                              calculate();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text("Present All"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              for (var key in attendance.keys) {
                                attendance[key] = null;
                              }
                              calculate();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text("Holiday"),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      return ListTile(
                        title: Text(s['name']),
                        trailing: customToggle(attendance[s['id']], () {
                          _toggle(s['id']);
                        }),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: _updateAttendance,
                    child: const Text("Update Attendance"),
                  ),
                )
              ],
            ),
    );
  }
}