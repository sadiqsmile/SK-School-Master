import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:school_app/core/widgets/app_cached_image.dart';
import 'package:school_app/features/teacher/screens/crop_screen.dart';
import 'package:school_app/features/teacher/attendance/screens/quick_attendance_screen.dart';
import 'package:school_app/features/teacher/screens/attendance_calendar_screen.dart';
import 'package:school_app/features/teacher/screens/analytics_dashboard_screen.dart';
import 'package:school_app/features/teacher/screens/student_history_screen.dart';
import 'package:school_app/features/teacher/screens/teacher_announcements_screen.dart';
import 'package:school_app/features/teacher/screens/teacher_timetable_screen.dart';
import 'package:school_app/core/services/image_service.dart';

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
  String teacherId = "";
  Map<String, dynamic> teacherData = {};
  String schoolName = "";
  String schoolLogo = "";

  File? image;
  Uint8List? webImage;

  bool isLoading = false;
  bool dashboardReady = false;
  String themeMode = "auto";

  @override
  void initState() {
    super.initState();
    loadTeacherData();
  }

  // ==========================
  // LOAD DATA
  // ==========================
  Future<void> loadTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      email = user.email ?? "";

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      schoolId = userData["schoolId"] ?? "";

      teacherId = userData["teacherId"] ?? user.uid;

      if (schoolId.isEmpty) {
        if (mounted) {setState(() {dashboardReady = true; });

}
        return;
      }

      final teacherDoc = await FirebaseFirestore.instance
          .collection("schools")
          .doc(schoolId)
          .collection("teachers")
          .doc(teacherId)
          .get();

      if (teacherDoc.exists) {
        final data = teacherDoc.data()!;
        teacherName = data["name"] ?? "";
        teacherData = data;

        final keys = List<String>.from(
          data["assignmentKeys"] ?? [],
        );

        if (keys.isNotEmpty) {
          final parts = keys.first.split("_");

          if (parts.length == 2) {
            className = parts[0].replaceAll("Class ", "").trim();
            section = parts[1].trim();
          }
        }
      }




   // Save FCM token to teacher document

if (!kIsWeb) {

  final fcmToken =
      await FirebaseMessaging.instance
          .getToken();

  if (fcmToken != null &&
      schoolId.isNotEmpty &&
      teacherId.isNotEmpty) {

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('teachers')
        .doc(teacherId)
        .update({
      'fcmToken': fcmToken,
    });
  }
}

      if (mounted) {

  setState(() {

    dashboardReady = true;
  });
}
    } catch (e) {
     debugPrint("Load Teacher Error: $e");

if (mounted) {

  setState(() {

    dashboardReady = true;
  });
}
    
    
    
    }
  }

  // ==========================
  // PICK IMAGE
  // ==========================
  Future<void> pickImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || schoolId.isEmpty) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    final cropped = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CropScreen(
          imageBytes: bytes,
        ),
      ),
    );

    if (cropped == null) return;

    setState(() => isLoading = true);

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(cropped),
        quality: 85,
        minWidth: 600,
minHeight: 600,
        format: CompressFormat.jpeg,
      );

      final url = await ImageService.uploadImage(
        schoolId: schoolId,
        module: 'teachers',
        type: 'profile',
        fileName: teacherId,
        bytes: Uint8List.fromList(compressed),
      );

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('teachers')
          .doc(teacherId)
          .update({
        'photoUrl': url,
      });

      teacherData['photoUrl'] = url;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        'Teacher photo update error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================
  // THEME
  // ==========================
  bool get isDark {
    if (themeMode == "dark") return true;
    if (themeMode == "light") return false;

    final h = DateTime.now().hour;
    return h >= 18 || h < 6;
  }

  Color textMain() => isDark ? Colors.white : Colors.black87;

  Color textSub() => isDark ? Colors.white70 : Colors.black54;

  Color bg() => isDark ? const Color(0xFF0B0B0B) : const Color(0xFFF4F5F8);

  // ==========================
  // HELPERS
  // ==========================
  String greet() {
    final h = DateTime.now().hour;

    if (h < 12) return "Good Morning 👋";
    if (h < 17) return "Good Afternoon ☀️";
    return "Good Evening 🌙";
  }

  String time12() {
    final now = DateTime.now();

    int h = now.hour;
    final m = now.minute.toString().padLeft(2, '0');

    final suffix = h >= 12 ? "PM" : "AM";

    if (h == 0) h = 12;
    if (h > 12) h -= 12;

    return "$h:$m $suffix";
  }

  Widget glass({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget menu(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: glass(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: textMain(),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: textMain(),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================
  // BOTTOM SHEET
  // ==========================
  void openAttendanceHub() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Wrap(
            runSpacing: 12,
            children: [
              tile(
                Icons.check_circle,
                "Quick Attendance",
                () {
                  Navigator.pop(context);
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuickAttendanceScreen(
                        schoolId: schoolId,
                        teacherId: teacherId,
                        teacherData: teacherData,
                      ),
                    ),
                  );
                },
              ),
              tile(
                Icons.calendar_month,
                "Calendar",
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceCalendarScreen(
                        className: className,
                        section: section,
                        schoolId: schoolId,
                      ),
                    ),
                  );
                },
              ),
              tile(
                Icons.bar_chart,
                "Analytics",
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalyticsDashboardScreen(
                        className: className,
                        section: section,
                        schoolId: schoolId,
                      ),
                    ),
                  );
                },
              ),
              tile(
                Icons.people,
                "Student History",
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentHistoryScreen(
                        className: className,
                        section: section,
                        schoolId: schoolId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget tile(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: textMain(),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textMain(),
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  // ==========================
  // TODAY CARD
  // ==========================
  Widget todayCard() {
    if (schoolId.isEmpty || className.isEmpty || section.isEmpty) {
      return glass(
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final today = DateTime.now().toIso8601String().split("T")[0];

    final docId = "${className}_${section}_$today";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("schools")
          .doc(schoolId)
          .collection("attendance")
          .doc(docId)
          .snapshots(),
      builder: (_, snap) {
        String title = "0%";
        int p = 0;
        int a = 0;
        Color color = textMain();

        if (DateTime.now().weekday == DateTime.sunday) {
          title = "Sunday";
          color = Colors.orange;
        }

        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;

          final students = Map<String, dynamic>.from(
            data["students"] ?? {},
          );

          final vals =
              students.values.map((e) => e.toString().toLowerCase()).toList();

          p = vals.where((v) => v.contains("present") || v == "p").length;

          a = vals.where((v) => v.contains("absent") || v == "a").length;

          final total = p + a;

          if (total > 0) {
            title = "${((p / total) * 100).round()}%";
          }
        }

        return glass(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  "Today's Attendance",
                  style: TextStyle(
                    color: textSub(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    chip(
                      "P: $p",
                      Colors.green,
                    ),
                    chip(
                      "A: $a",
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bg(),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
       
       
       title: schoolId.isEmpty

    ? const SizedBox()

    : StreamBuilder<
       
       
       
       DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .snapshots(),

  builder: (context, snapshot) {

    String liveSchoolName = "School";
    String liveLogo = "";

    if (snapshot.hasData &&
        snapshot.data!.exists) {

      final data =
          snapshot.data!.data()
              as Map<String, dynamic>;

      liveSchoolName =
          data['name'] ?? 'School';

      final logo =
          data['logo'] ?? '';

      final updatedAt =
          data['logoUpdatedAt'] ?? '';

      liveLogo =
          "$logo?v=$updatedAt";
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        Container(
          width: 44,
          height: 44,

          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius:
                BorderRadius.circular(12),
          ),

          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(12),

            child: liveLogo.isNotEmpty

                ? 
                
                AppCachedImage(

  imageUrl: liveLogo,

  width: 44,
  height: 44,

  radius: 12,
)
               






                : const Icon(
                    Icons.school,
                  ),
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            liveSchoolName,

            overflow:
                TextOverflow.ellipsis,

            style: TextStyle(
              color: textMain(),
              fontSize: 20,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  },
), 

   
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.palette_outlined,
              color: textMain(),
            ),
            onSelected: (v) async {
              if (v == "logout") {
                await FirebaseAuth.instance.signOut();

                if (!mounted) return;

                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
                return;
              }

              setState(() {
                themeMode = v;
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: "light",
                child: Text("☀️ Light"),
              ),
              PopupMenuItem(
                value: "dark",
                child: Text("🌙 Dark"),
              ),
              PopupMenuItem(
                value: "auto",
                child: Text("🌈 Auto"),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: "logout",
                child: Text("🚪 Logout"),
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
        child: Text("No User"),
      )

    : !dashboardReady

        ? const Center(
            child:
                CircularProgressIndicator(),
          )
        
          
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greet(),
                              style: TextStyle(
                                color: textMain(),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} • ${time12()}",
                              style: TextStyle(
                                color: textSub(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // PROFILE CARD
                      glass(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              profileAvatar(user),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teacherName,
                                      style: TextStyle(
                                        color: textMain(),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        color: textSub(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      todayCard(),

                      const SizedBox(height: 18),

                      GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 1100
                            ? 5
                            : MediaQuery.of(context).size.width > 700
                                ? 3
                                : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio:
                            MediaQuery.of(context).size.width > 1100
                                ? 1.7
                                : 1.45,
                        children: [
                          
                          
                        if (teacherData['classTeacherOf'] != null)

  menu(
    Icons.check_circle,
    "Mark Attendance",
    () {

      Navigator.push(
        context,
        MaterialPageRoute(
        builder: (_) => QuickAttendanceScreen(

            schoolId: schoolId,

            teacherId: teacherId,

            teacherData: teacherData,
          ),
        ),
      );
    },
  ),

menu(
  Icons.analytics,
  "Attendance Reports",
  openAttendanceHub,
),


                          menu(
                            Icons.schedule,
                            "Time Table",
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeacherTimetableScreen(
                                    schoolId: schoolId,
                                    teacherName:
                                        teacherData['name'] ?? teacherName,
                                  ),
                                ),
                              );
                            },
                          ),
                          menu(
                            Icons.edit_note,
                            "Marks",
                            () {},
                          ),
                          menu(
                            Icons.people,
                            "Students",
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentHistoryScreen(
                                    className: className,
                                    section: section,
                                    schoolId: schoolId,
                                  ),
                                ),
                              );
                            },
                          ),
                          menu(
                            Icons.campaign_outlined,
                            "Announcements",
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeacherAnnouncementsScreen(
                                    schoolId: schoolId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuickAttendanceScreen(
                schoolId: schoolId,
                teacherId: teacherId,
                teacherData: teacherData,
              ),
            ),
          );
        },
        child: const Icon(Icons.check),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(
              Icons.home,
              color: Color(0xFF6366F1),
            ),
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





Widget profileAvatar(User user) {

  if (schoolId.isEmpty ||
      teacherId.isEmpty) {

    return const SizedBox();
  }

  return StreamBuilder<
  
  
  DocumentSnapshot>(

    stream: FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('teachers')
        .doc(teacherId)
        .snapshots(),

    builder: (context, snapshot) {

      final data = snapshot.hasData
          ? snapshot.data!.data()
              as Map<String, dynamic>
          : <String, dynamic>{};

      final url =
          data["photoUrl"] ?? '';

      final updatedAt =
          data["photoUpdatedAt"] ?? '';

      return GestureDetector(

        onTap: pickImage,


  child: Container(

    width: 70,
height: 70,

    decoration: BoxDecoration(

      shape: BoxShape.circle,

      border: Border.all(
        color: Colors.white,
        width: 2,
      ),
    ),





   child: ClipOval(

  child: OverflowBox(

    maxWidth: 130,
    maxHeight: 130,

    child: Transform.scale(

      scale: 1.15,

      child: AppCachedImage(

        imageUrl:
            "$url?v=$updatedAt",

        width: 40,
        height: 40,

        radius: 100,
      ),
    ),
  ),
),
  ),
      );
    },
  );
}
} 
