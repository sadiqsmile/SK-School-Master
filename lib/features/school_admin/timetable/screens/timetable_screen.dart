import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_period_screen.dart';

class TimetableScreen extends StatefulWidget {

  final String schoolId;

  const TimetableScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<TimetableScreen> createState() =>
      _TimetableScreenState();
}

class _TimetableScreenState
    extends State<TimetableScreen> {

  String selectedClass = "7";
  String selectedSection = "A";

  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];

  String get docId =>
      "${selectedClass}_$selectedSection";

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Timetable"),
      ),

      floatingActionButton:
          FloatingActionButton.extended(

        onPressed: () {

          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (_) => AddPeriodScreen(
                schoolId: widget.schoolId,
                classId: selectedClass,
                sectionId: selectedSection,
              ),
            ),
          );
        },

        icon: const Icon(Icons.add),

        label: const Text("Add Period"),
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),

            child: Row(
              children: [

                Expanded(
                  child:
                      DropdownButtonFormField<String>(

                    value: selectedClass,

                    decoration:
                        const InputDecoration(
                      labelText: "Class",
                    ),

                    items:
                        List.generate(12, (i) {

                      final c = (i + 1).toString();

                      return DropdownMenuItem(
                        value: c,
                        child: Text("Class $c"),
                      );

                    }),

                    onChanged: (v) {

                      if (v != null) {

                        setState(() {
                          selectedClass = v;
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child:
                      DropdownButtonFormField<String>(

                    value: selectedSection,

                    decoration:
                        const InputDecoration(
                      labelText: "Section",
                    ),

                    items:
                        ["A", "B", "C", "D"]
                            .map((e) {

                      return DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      );

                    }).toList(),

                    onChanged: (v) {

                      if (v != null) {

                        setState(() {
                          selectedSection = v;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('timetables')
                  .doc(docId)
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data =
                    snapshot.data!.data()
                        as Map<String, dynamic>?;

                final timetable =
                    data?['days']
                        as Map<String, dynamic>? ?? {};

                return ListView.builder(

                  padding:
                      const EdgeInsets.all(16),

                  itemCount: days.length,

                  itemBuilder: (context, index) {

                    final day = days[index];

                    final periods =
                        List<Map<String, dynamic>>.from(
                      timetable[day] ?? [],
                    );

                    return Card(
                      margin:
                          const EdgeInsets.only(
                        bottom: 18,
                      ),

                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Text(
                              day,

                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 14),

                            if (periods.isEmpty)

                              const Text(
                                "No periods added",
                              ),

                            ...periods.map((e) {

                              return ListTile(

                                leading:
                                    CircleAvatar(
                                  child: Text(
                                    e['period']
                                        .toString(),
                                  ),
                                ),

                                title: Text(
                                  e['subject'],
                                ),

                                subtitle: Text(
                                  "${e['teacherName']} • "
                                  "${e['startTime']} - "
                                  "${e['endTime']}",
                                ),
                              );

                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
