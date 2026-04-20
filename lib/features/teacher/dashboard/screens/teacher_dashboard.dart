import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:school_app/features/teacher/screens/attendance_screen.dart';
import 'package:school_app/features/teacher/screens/attendance_calendar_screen.dart';
import 'package:school_app/features/teacher/screens/analytics_dashboard_screen.dart';
import 'package:school_app/features/teacher/screens/student_history_screen.dart';
import 'package:school_app/features/teacher/screens/crop_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final ImagePicker _picker = ImagePicker();

  String teacherName = "";
  String email = "";
  String schoolId = "";
  String className = "";
  String section = "";

  bool isLoading = false;
  File? image;
  Uint8List? webImage;

  String themeMode = "auto";

  @override
  void initState() {
    super.initState();
    loadTeacherData();
  }

  Future<void> loadTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    email = user.email ?? "";

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    schoolId = userData["schoolId"] ?? "";
    final teacherId = userData["teacherId"] ?? user.uid;

    final teacherDoc = await FirebaseFirestore.instance
        .collection("schools")
        .doc(schoolId)
        .collection("teachers")
        .doc(teacherId)
        .get();

    if (teacherDoc.exists) {
      final data = teacherDoc.data()!;
      teacherName = data["name"] ?? "";

      final keys = List<String>.from(data["assignmentKeys"] ?? []);
      if (keys.isNotEmpty) {
        final parts = keys.first.split("_");
        if (parts.length == 2) {
          className = parts[0].replaceAll("Class ", "").trim();
          section = parts[1].trim();
        }
      }
    }

    if (mounted) setState(() {});
  }

  // ================= THEME =================
  bool get isDark {
    if (themeMode == "dark") return true;
    if (themeMode == "light") return false;
    return DateTime.now().hour >= 18 ||
        DateTime.now().hour < 6;
  }

  List<Color> bgTheme() {
    if (isDark) {
      return [
        const Color(0xFF050505),
        const Color(0xFF121212),
      ];
    }

    return [
      const Color(0xFFF7F8FC),
      const Color(0xFFEDEFF7),
    ];
  }

  Color textMain() =>
      isDark ? Colors.white : Colors.black87;

  Color textSub() =>
      isDark ? Colors.white70 : Colors.black54;

  // ================= IMAGE =================
  Future<void> pickImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picked =
        await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => isLoading = true);

    final bytes = await picked.readAsBytes();

    final cropped = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CropScreen(imageBytes: bytes),
      ),
    );

    if (cropped == null) {
      setState(() => isLoading = false);
      return;
    }

    if (kIsWeb) {
      webImage = cropped;
      await uploadImage(cropped, user.uid);
    } else {
      final dir = await getTemporaryDirectory();

      final temp = File("${dir.path}/temp.jpg");
      await temp.writeAsBytes(cropped);

      final compressed = await compressImage(temp);

      image = compressed;

      final uploadBytes =
          await compressed.readAsBytes();

      await uploadImage(uploadBytes, user.uid);
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();

    final path =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result =
        await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      path,
      quality: 70,
      minWidth: 700,
      minHeight: 700,
    );

    return result == null ? file : File(result.path);
  }

  Future<void> uploadImage(
      Uint8List bytes, String uid) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child("teacher_profiles")
        .child("$uid.jpg");

    await ref.putData(bytes);

    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection("schools")
        .doc(schoolId)
        .collection("teachers")
        .doc(uid)
        .set(
      {"photoUrl": url},
      SetOptions(merge: true),
    );
  }

  // ================= HELPERS =================
  String greet() {
    final h = DateTime.now().hour;

    if (h < 12) return "Good Morning 👋";
    if (h < 17) return "Good Afternoon ☀️";
    return "Good Evening 🌙";
  }

  String time12() {
    final now = DateTime.now();

    int h = now.hour;
    final m =
        now.minute.toString().padLeft(2, '0');

    final suffix =
        h >= 12 ? "PM" : "AM";

    if (h == 0) h = 12;
    if (h > 12) h -= 12;

    return "$h:$m $suffix";
  }

  // ================= UI =================
  Widget glass({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.80),
            borderRadius:
                BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? Colors.white12
                  : Colors.black12,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(
                    isDark ? 0.20 : 0.06),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget chip(
      String text,
      Color color,
      ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(25),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget menu(
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration:
          const Duration(milliseconds: 400),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: InkWell(
        borderRadius:
            BorderRadius.circular(24),
        onTap: onTap,
        child: glass(
          child: Container(
            padding:
                const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                Icon(
                  icon,
                  color: textMain(),
                  size: 30,
                ),
                const SizedBox(
                    height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: textMain(),
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget todayCard() {
    final today =
        DateTime.now().toIso8601String().split("T")[0];

    final docId =
        "${className}_${section}_$today";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("schools")
          .doc(schoolId)
          .collection("attendance")
          .doc(docId)
          .snapshots(),
      builder: (context, snap) {
        int p = 0;
        int a = 0;

        String title = "Holiday";
        Color titleColor = Colors.orange;

        final isSunday =
            DateTime.now().weekday ==
                DateTime.sunday;

        if (snap.hasData &&
            snap.data!.exists) {
          final data = snap.data!.data()
              as Map<String, dynamic>;

          final students =
              Map<String, dynamic>.from(
                  data["students"] ??
                      {});

          p = students.values
              .where((e) => e == "P")
              .length;

          a = students.values
              .where((e) => e == "A")
              .length;

          final total = p + a;

          if (total > 0) {
            final per =
                ((p / total) * 100)
                    .round();

            title = "$per%";
            titleColor =
                textMain();
          }
        }

        if (isSunday) {
          title = "Sunday";
          titleColor = Colors.yellow;
          p = 0;
          a = 0;
        }

        return glass(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  "Today's Attendance",
                  style: TextStyle(
                    color: textSub(),
                  ),
                ),
                const SizedBox(
                    height: 18),
                TweenAnimationBuilder<
                    double>(
                  tween: Tween(
                    begin: 0,
                    end: double.tryParse(
                          title.replaceAll(
                              "%", ""),
                        ) ??
                        0,
                  ),
                  duration:
                      const Duration(
                    milliseconds:
                        800,
                  ),
                  builder: (context,
                      value,
                      child) {
                    final t = title
                            .contains("%")
                        ? "${value.toInt()}%"
                        : title;

                    return Text(
                      t,
                      style:
                          TextStyle(
                        fontSize:
                            36,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            titleColor,
                      ),
                    );
                  },
                ),
                const SizedBox(
                    height: 18),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceEvenly,
                  children: [
                    chip(
                        "P: $p",
                        Colors.green),
                    chip(
                        "A: $a",
                        Colors.red),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
          bgTheme()[0],

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.transparent,
        title: Text(
          "Dashboard",
          style: TextStyle(
            color: textMain(),
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.palette_outlined,
              color: textMain(),
            ),
            onSelected: (v) {
              setState(() {
                themeMode = v;
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: "light",
                child:
                    Text("☀️ Light"),
              ),
              PopupMenuItem(
                value: "dark",
                child:
                    Text("🌙 Dark"),
              ),
              PopupMenuItem(
                value: "auto",
                child:
                    Text("🌈 Auto"),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_none,
              color: textMain(),
            ),
          ),
        ],
      ),

      body: user == null
          ? const Center(
              child:
                  Text("No User"))
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                      16),
              child: Column(
                children: [
                  Align(
                    alignment:
                        Alignment
                            .centerLeft,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          greet(),
                          style:
                              TextStyle(
                            color:
                                textMain(),
                            fontSize:
                                28,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                            height:
                                4),
                        Text(
                          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} • ${time12()}",
                          style:
                              TextStyle(
                            color:
                                textSub(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                      height: 18),

                  // HEADER
                  StreamBuilder<
                      DocumentSnapshot>(
                    stream:
                        FirebaseFirestore
                            .instance
                            .collection(
                                "schools")
                            .doc(
                                schoolId)
                            .collection(
                                "teachers")
                            .doc(
                                user.uid)
                            .snapshots(),
                    builder:
                        (context,
                            snap) {
                      String? url;

                      if (snap.hasData &&
                          snap.data!
                              .exists) {
                        final d = snap
                                .data!
                                .data()
                            as Map<
                                String,
                                dynamic>?;

                        url = d?[
                            "photoUrl"];
                      }

                      ImageProvider?
                          provider;

                      if (webImage !=
                          null) {
                        provider =
                            MemoryImage(
                                webImage!);
                      } else if (image !=
                          null) {
                        provider =
                            FileImage(
                                image!);
                      } else if (url !=
                          null) {
                        provider =
                            NetworkImage(
                                url);
                      }

                      return glass(
                        child:
                            Padding(
                          padding:
                              const EdgeInsets.all(
                                  18),
                          child:
                              Row(
                            children: [
                              GestureDetector(
                                onTap:
                                    pickImage,
                                child:
                                    CircleAvatar(
                                  radius:
                                      34,
                                  backgroundColor:
                                      Colors.white,
                                  backgroundImage:
                                      provider,
                                  child: provider ==
                                          null
                                      ? const Icon(
                                          Icons.person)
                                      : null,
                                ),
                              ),
                              const SizedBox(
                                  width:
                                      14),
                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teacherName,
                                      style:
                                          TextStyle(
                                        color:
                                            textMain(),
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize:
                                            22,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      style:
                                          TextStyle(
                                        color:
                                            textSub(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isLoading)
                                const CircularProgressIndicator()
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                      height: 18),

                  todayCard(),

                  const SizedBox(
                      height: 18),

                  GridView.count(
                    crossAxisCount:
                        2,
                    shrinkWrap:
                        true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisSpacing:
                        14,
                    mainAxisSpacing:
                        14,
                    childAspectRatio:
                        1.10,
                    children: [
                      menu(
                        Icons.check,
                        "Attendance",
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      AttendanceScreen(
                                className:
                                    className,
                                section:
                                    section,
                                schoolId:
                                    schoolId,
                              ),
                            ),
                          );
                        },
                      ),
                      menu(
                        Icons.calendar_month,
                        "Calendar",
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      AttendanceCalendarScreen(
                                className:
                                    className,
                                section:
                                    section,
                                schoolId:
                                    schoolId,
                              ),
                            ),
                          );
                        },
                      ),
                      menu(
                        Icons.bar_chart,
                        "Analytics",
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      AnalyticsDashboardScreen(
                                className:
                                    className,
                                section:
                                    section,
                                schoolId:
                                    schoolId,
                              ),
                            ),
                          );
                        },
                      ),
                      menu(
                        Icons.people,
                        "Students",
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      StudentHistoryScreen(
                                className:
                                    className,
                                section:
                                    section,
                                schoolId:
                                    schoolId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 120),
                ],
              ),
            ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .endDocked,

      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            const Color(
                0xFF6366F1),
        elevation: 8,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AttendanceScreen(
                className:
                    className,
                section:
                    section,
                schoolId:
                    schoolId,
              ),
            ),
          );
        },
        child: const Icon(
          Icons.check,
          color: Colors.white,
        ),
      ),

      bottomNavigationBar:
          Container(
        margin:
            const EdgeInsets.all(
                14),
        padding:
            const EdgeInsets.symmetric(
                vertical:
                    14),
        decoration:
            BoxDecoration(
          color: isDark
              ? const Color(
                  0xFF1B1B1B)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(
                  32),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              color: Colors.black
                  .withOpacity(
                      0.08),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceEvenly,
          children: [
            Icon(Icons.home,
                color: const Color(
                    0xFF6366F1)),
            Icon(
              Icons.bar_chart,
              color: textMain(),
            ),
            Icon(
              Icons.calendar_today,
              color: textMain(),
            ),
            Icon(
              Icons.person_outline,
              color: textMain(),
            ),
          ],
        ),
      ),
    );
  }
}