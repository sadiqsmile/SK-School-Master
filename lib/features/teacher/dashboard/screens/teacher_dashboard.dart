import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:school_app/features/teacher/screens/crop_screen.dart';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';



class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String teacherName = "";
  String email = "";
  String schoolId = "";
  String className = "";
  String section = "";

  int present = 0;
  int absent = 0;

  bool _isLoading = false;
  File? _image;
  Uint8List? _webImage;

  final ImagePicker _picker = ImagePicker();

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
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();
    if (userData == null) return;

    schoolId = userData['schoolId'] ?? "";
    final teacherId = userData['teacherId'];

    final teacherDoc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('teachers')
        .doc(teacherId)
        .get();

    final data = teacherDoc.data();
    if (data != null) {
      teacherName = data['name'] ?? "";

      final keys = List<String>.from(data['assignmentKeys'] ?? []);

      if (keys.isNotEmpty) {
        final key = keys.first;
        final parts = key.split('_');
        if (parts.length == 2) {
          className = parts[0].replaceAll("Class ", "").trim();
          section = parts[1].trim();
        }
      }
    }

    await loadTodayAttendance();
    setState(() {});
  }

  Future<void> loadTodayAttendance() async {
    if (schoolId.isEmpty || className.isEmpty) return;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final docId = "${className}_${section}_$today";

    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .doc(docId)
        .get();

    if (!doc.exists) {
      present = 0;
      absent = 0;
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final students = Map<String, dynamic>.from(data['students'] ?? {});

    present = students.values.where((e) => e == 'P').length;
    absent = students.values.where((e) => e == 'A').length;
  }

  // 🔥 IMAGE UPLOAD FLOW

  Future<String?> _uploadToFirebase(Uint8List bytes, String uid) async {
    final refStorage = FirebaseStorage.instance
        .ref()
        .child('teacher_profiles')
        .child('$uid.jpg');

    await refStorage.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await refStorage.getDownloadURL();
  }

  Future<void> _saveImageUrl(String url, String uid) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('teachers')
        .doc(uid)
        .set({'photoUrl': url}, SetOptions(merge: true));
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final path =
        "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      path,
      quality: 70,
      minWidth: 500,
      minHeight: 500,
    );

    return result == null ? file : File(result.path);
  }

  Future<void> _pickImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => _isLoading = true);

      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      // 🔥 STEP 1: OPEN CROP SCREEN
      final croppedBytes = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CropScreen(imageBytes: bytes),
        ),
      );

      if (croppedBytes == null) return;

      // 🌐 WEB
      if (kIsWeb) {
        _webImage = croppedBytes;

        final url = await _uploadToFirebase(croppedBytes, user.uid);
        if (url != null) await _saveImageUrl(url, user.uid);
        return;
      }

      // 📱 MOBILE
      final temp = await getTemporaryDirectory();
      final file = File("${temp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg");

      await file.writeAsBytes(croppedBytes);

      final compressed = await _compressImage(file);
      final compressedBytes = await compressed.readAsBytes();

      setState(() => _image = compressed);

      final url = await _uploadToFirebase(compressedBytes, user.uid);
      if (url != null) await _saveImageUrl(url, user.uid);

    } catch (e) {
      print("ERROR: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔥 PREMIUM HEADER

  Widget profileHeader(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('teachers')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          photoUrl = data?['photoUrl'];
        }

        ImageProvider? imageProvider;

        if (_webImage != null) {
          imageProvider = MemoryImage(_webImage!);
        } else if (_image != null) {
          imageProvider = FileImage(_image!);
        } else if (photoUrl != null) {
          imageProvider = NetworkImage(photoUrl);
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    if (_isLoading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(teacherName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text(email,
                      style: const TextStyle(color: Colors.white70)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget todayCard() {
    int total = present + absent;
    double percent = total == 0 ? 0 : (present / total) * 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text("Today Attendance",
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(total == 0 ? "No Data" : "${percent.toStringAsFixed(0)}%",
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("P: $present",
                  style: const TextStyle(color: Colors.green)),
              Text("A: $absent",
                  style: const TextStyle(color: Colors.red)),
            ],
          )
        ],
      ),
    );
  }

  Widget actionButton(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Dashboard")),
      body: user == null
          ? const Center(child: Text("No user"))
          : SingleChildScrollView(
              child: Column(
                children: [
                  profileHeader(user),
                  todayCard(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      actionButton("Attendance", Icons.check, () {}),
                      actionButton("Calendar", Icons.calendar_month, () {}),
                    ],
                  ),
                  Row(
                    children: [
                      actionButton("Analytics", Icons.analytics, () {}),
                      actionButton("Students", Icons.people, () {}),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}