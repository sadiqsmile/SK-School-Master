import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentHistoryScreen extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;

  const StudentHistoryScreen({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
  });

  @override
  State<StudentHistoryScreen> createState() =>
      _StudentHistoryScreenState();
}

class _StudentHistoryScreenState
    extends State<StudentHistoryScreen> {
  String search = "";

  DateTime now = DateTime.now();

  Future<Map<String, dynamic>> getStats(
      String studentId) async {
    final snap = await FirebaseFirestore.instance
        .collection("schools")
        .doc(widget.schoolId)
        .collection("attendance")
        .where("className",
            isEqualTo: widget.className)
        .where("section",
            isEqualTo: widget.section)
        .get();

    int p = 0;
    int a = 0;
    int h = 0;

    List<Map<String, dynamic>> recent = [];

    for (var doc in snap.docs) {
      final data = doc.data();

      final date =
          data["date"]?.toString() ?? "";

      final dt = DateTime.tryParse(date);
      if (dt == null) continue;

      final students =
          Map<String, dynamic>.from(
              data["students"] ?? {});

      final status = students[studentId]
              ?.toString()
              .toUpperCase() ??
          "H";

      if (dt.month == now.month &&
          dt.year == now.year) {
        if (status == "P") p++;
        if (status == "A") a++;
        if (status == "H") h++;
      }

      recent.add({
        "date": dt,
        "status": status,
      });
    }

    recent.sort((a, b) => b["date"]
        .compareTo(a["date"]));

    recent = recent.take(6).toList();

    final total = p + a;
    final percent =
        total == 0 ? 0 : ((p / total) * 100).round();

    return {
      "p": p,
      "a": a,
      "h": h,
      "percent": percent,
      "recent": recent,
    };
  }

  String dayName(int w) {
    const d = [
      "",
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun"
    ];
    return d[w];
  }

  Color statusColor(String s) {
    if (s == "P") return Colors.green;
    if (s == "A") return Colors.red;
    return Colors.blue;
  }

  void openStudent(
      String name,
      String studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StudentCalendarScreen(
          schoolId: widget.schoolId,
          className: widget.className,
          section: widget.section,
          studentId: studentId,
          name: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Students"),
        centerTitle: true,
        backgroundColor:
            Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) {
                setState(() {
                  search = v
                      .trim()
                      .toLowerCase();
                });
              },
              decoration:
                  InputDecoration(
                hintText:
                    "Search student...",
                prefixIcon:
                    const Icon(Icons.search),
                filled: true,
                fillColor:
                    Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                          18),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore
                      .instance
                      .collection(
                          "schools")
                      .doc(widget
                          .schoolId)
                      .collection(
                          "students")
                      .where(
                          "className",
                          isEqualTo:
                              widget.className)
                      .where(
                          "section",
                          isEqualTo:
                              widget.section)
                      .snapshots(),
              builder:
                  (context,
                      snapshot) {
                if (!snapshot
                    .hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final docs = snapshot
                    .data!.docs
                    .where((e) {
                  final data = e.data()
                      as Map<String,
                          dynamic>;

                  final name = data[
                              "name"]
                          ?.toString()
                          .toLowerCase() ??
                      "";

                  return name
                      .contains(
                          search);
                }).toList();

                return ListView.builder(
                  itemCount:
                      docs.length,
                  itemBuilder:
                      (context,
                          i) {
                    final doc =
                        docs[i];
                    final data = doc
                            .data()
                        as Map<String,
                            dynamic>;

                    final name =
                        data["name"];

                    return FutureBuilder<
                        Map<String,
                            dynamic>>(
                      future:
                          getStats(
                              doc.id),
                      builder:
                          (context,
                              stat) {
                        if (!stat
                            .hasData) {
                          return const SizedBox();
                        }

                        final s = stat
                            .data!;

                        final recent =
                            List<Map<
                                String,
                                dynamic>>.from(
                          s["recent"],
                        );

                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal:
                                12,
                            vertical:
                                6,
                          ),
                          child:
                              InkWell(
                            borderRadius:
                                BorderRadius.circular(
                                    18),
                            onTap: () =>
                                openStudent(
                              name,
                              doc.id,
                            ),
                            child:
                                Container(
                              padding:
                                  const EdgeInsets.all(
                                      14),
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .white,
                                borderRadius:
                                    BorderRadius.circular(
                                        18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .black12,
                                    blurRadius:
                                        6,
                                  )
                                ],
                              ),
                              child:
                                  Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius:
                                        24,
                                    backgroundColor:
                                        Colors.indigo.shade100,
                                    child:
                                        const Icon(
                                      Icons.person,
                                      color:
                                          Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(
                                      width:
                                          12),
                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                18,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(
                                            height:
                                                4),
                                        Text(
                                          "${s["percent"]}% Attendance",
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.green.shade700,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(
                                            height:
                                                8),
                                        Wrap(
                                          spacing:
                                              6,
                                          runSpacing:
                                              6,
                                          children: recent
                                              .map(
                                                  (e) {
                                            final dt =
                                                e["date"]
                                                    as DateTime;

                                            final st =
                                                e["status"];

                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    8,
                                                vertical:
                                                    5,
                                              ),
                                              decoration:
                                                  BoxDecoration(
                                                color: statusColor(st).withOpacity(.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child:
                                                  Text(
                                                "${dt.day} ${dayName(dt.weekday)}=$st",
                                                style:
                                                    TextStyle(
                                                  fontSize:
                                                      11,
                                                  color:
                                                      statusColor(st),
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons
                                        .arrow_forward_ios,
                                    size: 16,
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class StudentCalendarScreen
    extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;
  final String studentId;
  final String name;

  const StudentCalendarScreen({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
    required this.studentId,
    required this.name,
  });

  @override
  State<StudentCalendarScreen>
      createState() =>
          _StudentCalendarScreenState();
}

class _StudentCalendarScreenState
    extends State<StudentCalendarScreen> {
  DateTime current =
      DateTime.now();

  String dayNameShort(int i) {
    const d = [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun"
    ];
    return d[i];
  }

  Future<Map<int, String>>
      loadMonth() async {
    final snap =
        await FirebaseFirestore
            .instance
            .collection("schools")
            .doc(widget.schoolId)
            .collection(
                "attendance")
            .where("className",
                isEqualTo:
                    widget.className)
            .where("section",
                isEqualTo:
                    widget.section)
            .get();

    Map<int, String> map = {};

    for (var doc in snap.docs) {
      final data = doc.data();

      final date =
          data["date"]?.toString() ??
              "";

      final dt =
          DateTime.tryParse(date);

      if (dt == null) continue;

      if (dt.month !=
              current.month ||
          dt.year !=
              current.year) {
        continue;
      }

      final students =
          Map<String, dynamic>.from(
              data["students"] ??
                  {});

      map[dt.day] = students[
                  widget.studentId]
              ?.toString()
              .toUpperCase() ??
          "H";
    }

    return map;
  }

  Color statusColor(String s) {
    if (s == "P") return Colors.green;
    if (s == "A") return Colors.red;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(
                current.year,
                current.month + 1,
                0)
            .day;

    final firstDay =
        DateTime(current.year,
                current.month, 1)
            .weekday;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(widget.name),
        centerTitle: true,
        backgroundColor:
            Colors.transparent,
        elevation: 0,
      ),
      body:
          FutureBuilder<Map<int, String>>(
        future: loadMonth(),
        builder:
            (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final map =
              snap.data!;

          return Column(
            children: [
              const SizedBox(
                  height: 8),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        current =
                            DateTime(
                          current.year,
                          current.month -
                              1,
                          1,
                        );
                      });
                    },
                    icon: const Icon(
                        Icons.chevron_left),
                  ),
                  Text(
                    "${monthName(current.month)} ${current.year}",
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        current =
                            DateTime(
                          current.year,
                          current.month +
                              1,
                          1,
                        );
                      });
                    },
                    icon: const Icon(
                        Icons.chevron_right),
                  ),
                ],
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal:
                            10),
                child: Row(
                  children: List.generate(
                    7,
                    (i) => Expanded(
                      child: Center(
                        child: Text(
                          dayNameShort(
                              i),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                  height: 10),

              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.all(
                          10),
                  itemCount:
                      daysInMonth +
                          firstDay -
                          1,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        7,
                    mainAxisSpacing:
                        8,
                    crossAxisSpacing:
                        8,
                  ),
                  itemBuilder:
                      (context,
                          i) {
                    if (i <
                        firstDay -
                            1) {
                      return const SizedBox();
                    }

                    final day =
                        i -
                            firstDay +
                            2;

                    final st =
                        map[day] ??
                            "-";

                    return Container(
                      decoration:
                          BoxDecoration(
                        color: Colors
                            .white,
                        borderRadius:
                            BorderRadius.circular(
                                10),
                        border:
                            Border.all(
                          color: Colors
                              .black12,
                        ),
                      ),
                      child:
                          Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            "$day",
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                              height:
                                  6),
                          Container(
                            height:
                                6,
                            width:
                                28,
                            decoration:
                                BoxDecoration(
                              color: st ==
                                      "-"
                                  ? Colors.grey.shade300
                                  : statusColor(st),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }

  String monthName(int m) {
    const months = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];

    return months[m];
  }
}