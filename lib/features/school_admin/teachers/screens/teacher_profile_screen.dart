// features/school_admin/teachers/screens/teacher_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edit_teacher_profile_screen.dart';
import 'assign_subject_screen.dart';
import 'package:flutter/foundation.dart';

import 'package:school_app/core/widgets/app_cached_image.dart';
import 'package:school_app/core/services/image_service.dart';

class TeacherProfileScreen extends StatefulWidget {
  final String schoolId;
  final String teacherId;

  const TeacherProfileScreen({
    super.key,
    required this.schoolId,
    required this.teacherId,
  });

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  bool _uploadingPhoto = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(widget.teacherId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.hasData
            ? snapshot.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};

        return Scaffold(
          appBar: AppBar(
            title: const Text("Teacher Profile"),
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : _body(context, data),
        );
      },
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> data) {
    final assignments = List<String>.from(data['assignmentKeys'] ?? []);

    final subjects = List<String>.from(data['subjects'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PROFILE HEADER
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff5B5FEF),
                          Color(0xff3B82F6),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: AppCachedImage(
                                  imageUrl: data['photoUrl'],
                                  width: 84,
                                  height: 84,
                                  radius: 100,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _uploadingPhoto
                                    ? null
                                    : () => _updateTeacherPhoto(data),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: _uploadingPhoto
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 16,
                                          color: Color(0xff5B5FEF),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['email'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data['phone'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 18,
                    right: 18,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            _openEditProfile(context, data);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            _confirmDelete(context);
                          },
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.menu_book),
                  label: const Text("Assign Subject"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignSubjectScreen(
                          schoolId: widget.schoolId,
                          teacherId: widget.teacherId,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _infoCard(
                    Icons.badge_outlined,
                    "Role",
                    (data['role'] ?? 'Teacher').toString().toUpperCase(),
                  ),
                  _infoCard(
                    Icons.school_outlined,
                    "Qualification",
                    data['qualification'] ?? '-',
                  ),
                  _infoCard(
                    Icons.person_outline,
                    "Gender",
                    data['gender'] ?? '-',
                  ),
                  _infoCard(
                    Icons.calendar_month_outlined,
                    "D.O.B",
                    _formatDob(data['dob']),
                  ),
                  _infoCard(
                    Icons.bloodtype_outlined,
                    "Blood Group",
                    data['bloodGroup'] ?? '-',
                  ),
                  _infoCard(
                    Icons.phone_outlined,
                    "Emergency Contact",
                    data['emergencyContact'] ?? '-',
                  ),
                  _infoCard(
                    Icons.location_on_outlined,
                    "Address",
                    data['address'] ?? '-',
                    multiLine: true,
                  ),
                  _infoCard(
                    Icons.credit_card_outlined,
                    "Aadhar No",
                    data['aadharNo'] ?? '-',
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(top: 22, bottom: 12),
                child: Text(
                  'Class Teacher',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              Builder(
                builder: (context) {
                  final classTeacher = data['classTeacherOf'];

                  if (classTeacher == null ||
                      classTeacher['classId'] == null ||
                      classTeacher['sectionId'] == null) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "${classTeacher['classId']}"
                      "${classTeacher['sectionId']}",
                    ),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.only(top: 22, bottom: 12),
                child: Text(
                  'Assigned Classes',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: assignments.map((assignment) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      assignment.replaceAll("_", " "),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff5B5FEF),
                      ),
                    ),
                  );
                }).toList(),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 22, bottom: 12),
                child: Text(
                  'Subjects',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: subjects.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff5B5FEF),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String caption, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 26,
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff374151),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTeacherPhoto(
    Map<String, dynamic> data,
  ) async {
    setState(() {
      _uploadingPhoto = true;
    });

    try {
      final bytes = await ImageService.pickCropCompressImage();

      if (bytes == null) return;

      final url = await ImageService.uploadImage(
        schoolId: widget.schoolId,
        module: 'teachers',
        type: 'profile',
        fileName: widget.teacherId,
        bytes: bytes,
      );

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(widget.teacherId)
          .update({
        'photoUrl': url,
        'photoUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Delete Teacher?"),
          content: const Text(
            "This teacher will be moved to archived teachers. You can restore later from settings.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('schools')
                    .doc(widget.schoolId)
                    .collection('teachers')
                    .doc(widget.teacherId)
                    .update({
                  'archived': true,
                  'archivedAt': Timestamp.now(),
                });

                if (context.mounted) Navigator.pop(context);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openEditProfile(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTeacherProfileScreen(
          schoolId: widget.schoolId,
          teacherId: widget.teacherId,
          data: data,
        ),
      ),
    );
  }

  String _formatDob(dynamic dob) {
    if (dob == null || dob.toString().isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(dob.toString());

      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
    } catch (e) {
      return dob.toString();
    }
  }

  Widget _avatarFallback(
    Map<String, dynamic> data,
  ) {
    final name = (data['name'] ?? '').toString();

    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xff5B5FEF),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String title,
    String value, {
    bool multiLine = false,
  }) {
    return Container(
      width: 220,
      constraints: multiLine ? const BoxConstraints(minHeight: 120) : null,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xffF4F5FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xff5B5FEF),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? "-" : value,
            maxLines: multiLine ? null : 2,
            softWrap: multiLine,
            overflow: multiLine ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xff1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
