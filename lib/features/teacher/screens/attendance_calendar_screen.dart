import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

import 'edit_attendance_screen.dart';

class AttendanceCalendarScreen extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;

  const AttendanceCalendarScreen({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
  });

  @override
  State<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends State<AttendanceCalendarScreen> {
  DateTime? selectedDay;
  Map<String, dynamic>? selectedData;

  /// 🔥 LOAD SELECTED DAY DATA
  Future<void> _loadSelectedDay(DateTime date) async {
    String dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .where('className', isEqualTo: widget.className)
        .where('section', isEqualTo: widget.section)
        .where('date', isEqualTo: dateStr)
        .get();

    if (snapshot.docs.isEmpty) {
      setState(() {
        selectedData = {
          'date': dateStr,
          'present': 0,
          'absent': 0,
          'holiday': false,
          'percent': 0.0,
        };
      });
      return;
    }

    final data = snapshot.docs.first.data();
    final students =
        Map<String, dynamic>.from(data['students'] ?? {});

    int present = 0;
    int absent = 0;
    students.forEach((key, value) {
      if (value == 'P' || value == true) present++;
      if (value == 'A' || value == false) absent++;
    });
    final totalStudents = students.length;
    double percent = totalStudents == 0 ? 0 : (present / totalStudents) * 100;

    setState(() {
      selectedData = {
        'date': dateStr,
        'present': present,
        'absent': absent,
        'holiday': data['isHoliday'] ?? false,
        'percent': percent,
      };
    });
  }

  /// 🔥 SMALL STAT BOX
  Widget _statBox(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calendar View")),
      body: Column(
        children: [

          /// 📅 CALENDAR
          TableCalendar(
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            focusedDay: selectedDay ?? DateTime.now(),

            selectedDayPredicate: (day) =>
                isSameDay(selectedDay, day),

            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                selectedData = null;
              });

              _loadSelectedDay(selected);
            },

            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isSelected = isSameDay(selectedDay, day);

                return Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${day.day}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🔄 LOADING
          if (selectedDay != null && selectedData == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),

          /// 📊 RESULT CARD
          if (selectedData != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    selectedData!['date'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (selectedData!['holiday'] == true)
                    const Text(
                      "Holiday",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else ... [
                    Text(
                      "${selectedData!['percent'].toStringAsFixed(0)}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Attendance",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statBox("P", selectedData!['present'], Colors.green),
                        _statBox("A", selectedData!['absent'], Colors.red),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditAttendanceScreen(
                              schoolId: widget.schoolId,
                              className: widget.className,
                              section: widget.section,
                              date: selectedData!['date'],
                            ),
                          ),
                        );
                        if (result == true) {
                          setState(() {
                            selectedData = null;
                          });
                          _loadSelectedDay(selectedDay!);
                        }
                      },
                      child: const Text("Edit Attendance"),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}