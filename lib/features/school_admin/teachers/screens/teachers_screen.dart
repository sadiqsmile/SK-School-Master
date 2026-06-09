import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/core/widgets/profile_avatar.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'teacher_profile_screen.dart';
import '../services/teacher_export_service.dart';
import '../services/teacher_import_service.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:school_app/core/services/image_service.dart';




Future<void> uploadTeacherPhotos(
  BuildContext context,
  String schoolId,
) async {

  final result =
      await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.image,
    withData: true,
  );

  if (result == null) return;

  int uploaded = 0;

  for (final file in result.files) {

    try {

      final email = file.name
          .replaceAll(
            RegExp(r'\.[^/.]+$'),
            '',
          )
          .trim()
          .toLowerCase();

      final fileBytes = file.bytes;

      if (fileBytes == null) continue;

      final compressed =
          await FlutterImageCompress
              .compressWithList(

        fileBytes,

        quality: 55,

        minWidth: 300,
        minHeight: 300,

        format:
            CompressFormat.jpeg,
      );

      final teacherSnap =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .collection('teachers')
              .where(
                'email',
                isEqualTo: email,
              )
              .limit(1)
              .get();

      if (teacherSnap.docs.isEmpty) {
        continue;
      }

      final teacherDoc =
          teacherSnap.docs.first;

      final teacherId =
          teacherDoc.id;

      final url =
          await ImageService.uploadImage(

        schoolId: schoolId,

        module: 'teachers',

        type: 'profile',

        fileName: teacherId,

        bytes: compressed,
      );

      await teacherDoc.reference.update({
        'photoUrl': url,
      });

      uploaded++;

    } catch (e) {

      debugPrint(
        'Teacher Photo Upload Error: $e',
      );
    }
  }

  if (context.mounted) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(
          '$uploaded teacher photos uploaded',
        ),
      ),
    );
  }
}

class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync =
        ref.watch(teachersProvider);

    final schoolIdAsync = ref.watch(schoolIdProvider);

    return AdminLayout(
      title: 'Teachers',
      onSettingsPressed: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _TeacherSettingsSheet(context: context),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () =>
            context.go(
          '/add-teacher',
        ),
        icon: const Icon(
          Icons.person_add_alt_1,
        ),
        label: const Text(
          'Add Teacher',
        ),
      ),
      body: teachersAsync.when(
        loading: () =>
            const Center(
          child:
              CircularProgressIndicator(),
        ),
        error: (e, _) =>
            Center(
          child: Text(
            'Error: $e',
          ),
        ),
        data: (snapshot) {
          final teachers = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['archived'] != true;
          }).toList();

          if (teachers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      size: 42,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "No Active Teachers",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff374151),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Add teachers to manage classes,\nsubjects and timetable.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/add-teacher');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Teacher"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder:
                (context, box) {
              final mobile =
                  box.maxWidth <
                      760;

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  13,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    _heroHeader(
                      teachers
                          .length,
                    ),

                    const SizedBox(
                      height: 18,
                    ),




                    GridView.count(
                      crossAxisCount:
                          mobile
                              ? 2
                              : 4,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      crossAxisSpacing:
                          14,
                      mainAxisSpacing:
                          14,
                      childAspectRatio:
                          mobile
                              ? 2.1
                              : 2.8,
                      children: [
                        _statCard(
                          'Total',
                          teachers
                              .length
                              .toString(),
                          Icons.groups_rounded,
                          const Color(
                            0xFF2563EB,
                          ),
                          const Color(
                            0xFF3B82F6,
                          ),
                        ),
                        _statCard(
                          'Assigned',
                          teachers
                              .where(
                                (
                                  e,
                                ) {
                                  final d = e
                                          .data()
                                      as Map<String,
                                          dynamic>;

                                  final a = d[
                                          'assignmentKeys'] ??
                                      [];

                                  return a
                                      .isNotEmpty;
                                },
                              )
                              .length
                              .toString(),
                          Icons.school_rounded,
                          const Color(
                            0xFF10B981,
                          ),
                          const Color(
                            0xFF059669,
                          ),
                        ),
                        _statCard(
                          'Unassigned',
                          teachers
                              .where(
                                (
                                  e,
                                ) {
                                  final d = e
                                          .data()
                                      as Map<String,
                                          dynamic>;

                                  final a = d[
                                          'assignmentKeys'] ??
                                      [];

                                  return a
                                      .isEmpty;
                                },
                              )
                              .length
                              .toString(),
                          Icons.pending_actions_rounded,
                          const Color(
                            0xFFEF4444,
                          ),
                          const Color(
                            0xFFDC2626,
                          ),
                        ),
                        _statCard(
                          'Active',
                          teachers
                              .length
                              .toString(),
                          Icons.verified_user_rounded,
                          const Color(
                            0xFF8B5CF6,
                          ),
                          const Color(
                            0xFF6366F1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    ListView.builder(
                      itemCount:
                          teachers
                              .length,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        final doc =
                            teachers[
                                index];

                        final data = doc
                                .data()
                            as Map<String,
                                dynamic>;

                        final teacherId =
                            doc.id;

                        final name =
                            (data['name'] ??
                                    '')
                                .toString();

                        final email =
                            (data['email'] ??
                                    '')
                                .toString();

                        final phone =
                            (data['phone'] ??
                                    '')
                                .toString();

                        final photoUrl =
                          (data['photoUrl'] ??
                              '')
                            .toString();

                        final assignmentKeys =
                            (data['assignmentKeys'] ??
                                    [])
                                as List;

                       return _teacherCard(
  context: context,
  ref: ref,
  schoolId: schoolIdAsync.value ?? '',
  teacherId: teacherId,
  name: name,
  email: email,
  phone: phone,
  photoUrl: photoUrl,
  assignmentKeys: assignmentKeys,

  classTeacher: data['classTeacherOf'],

  attendanceClasses: List<String>.from(
    data['attendanceClasses'] ?? [],
  ),

  subjects: List<String>.from(
    data['subjects'] ?? [],
  ),
);



                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _heroHeader(
    int total,
  ) {
   
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF0EA5E9),
            Color(0xFF2563EB),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x220EA5E9,
            ),
            blurRadius: 24,
            offset: Offset(
              0,
              12,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          const Text(
            'Staff Management 👨‍🏫',
            style: TextStyle(
              color:
                  Colors.white70,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          const Text(
            'Teachers Dashboard',
            style: TextStyle(
              color:
                  Colors.white,
              fontSize: 26,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            '$total teachers registered in your school.',
            style:
                const TextStyle(
              color:
                  Colors.white70,
            ),
          ),
        ],
      ),
    );
  }



Widget _statCard(
  String title,
  String value,
  IconData icon,
  Color start,
  Color end,
) {
  return Container(

    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),

    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),

      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),

    child: Row(
      children: [

        Container(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(12),

            gradient: LinearGradient(
              colors: [start, end],
            ),
          ),

          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}




Widget _teacherCard({
  required BuildContext context,
  required WidgetRef ref,
  required String schoolId,
  required String teacherId,
  required String name,
  required String email,
  required String phone,
  required String photoUrl,
  required List assignmentKeys,

  required dynamic classTeacher,
  required List<String> attendanceClasses,
  required List<String> subjects,
})
  
  
   {
    final assignmentTags = assignmentKeys
        .map((e) => e.toString())
        .toSet()
        .toList();

final classTeacherText =
    classTeacher == null
        ? 'Not Assigned'
        : '${classTeacher['classId']} ${classTeacher['sectionId']}';



    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherProfileScreen(
              schoolId: schoolId,
              teacherId: teacherId,
            ),
          ),
        );
      },
      child: Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x12000000,
            ),
            blurRadius: 18,
            offset: Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          
          Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    ProfileAvatar(
      name: name,
      imageUrl: photoUrl,
      radius: 25,
    ),

    const SizedBox(width: 20),

    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            ' $name',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text('📞  $phone'),

          const SizedBox(height: 8),

          Text('✉️ : $email'),

          const SizedBox(height: 8),

          Text('🎓 Class Teacher : $classTeacherText'),

          const SizedBox(height: 8),

          Text(
            '📚 Subject : ${subjects.isEmpty ? "Not Assigned" : subjects.join(", ")}',
          ),
        ],
      ),
    ),
  ],
),

      const SizedBox(height: 16),

Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    // LEFT
    Expanded(
      flex: 3,
      child: const SizedBox.shrink(),
    ),

    const SizedBox(width: 20),

  ],
),

        ],
      ),
    ),
    );
   
  }


  Future<void>
      _resetAssignments(
    BuildContext context,
    WidgetRef ref,
    String teacherId,
  ) async {
    final ok =
        await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
        title: const Text(
          'Reset Assignment',
        ),
        content: const Text(
          'Remove all assigned classes?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),
            child:
                const Text(
              'Cancel',
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child:
                const Text(
              'Reset',
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final school = await ref.read(
      currentSchoolProvider.future,
    );

    await FirebaseFirestore
        .instance
        .collection('schools')
        .doc(school.id)
        .collection('teachers')
        .doc(teacherId)
        .update({
      'assignmentKeys': [],
    });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Assignments cleared',
          ),
        ),
      );
    }
  }
}






// ─── Teacher Settings Bottom Sheet ─────────────────────────────────────────

class _TeacherSettingsSheet extends ConsumerWidget {
  final BuildContext context;
  const _TeacherSettingsSheet({required this.context});

  @override
  Widget build(
  BuildContext ctx,
  WidgetRef ref,
)
      
   {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      
      
    child: SingleChildScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          // handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffE5E7EB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Teacher Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xff1F2937),
            ),
          ),
          


          const SizedBox(height: 16),
          _SheetTile(
            icon: Icons.archive_outlined,
            iconColor: const Color(0xff5B5FEF),
            iconBg: const Color(0xffEEEFFF),
            title: 'Archived Teachers',
            subtitle: 'View and restore deleted teachers',
            onTap: () {
              Navigator.pop(ctx);
              context.push('/school-admin/settings/archived-teachers');
            },
          ),
          const SizedBox(height: 8),
         
         
         
         _SheetTile(
  icon: Icons.file_download_outlined,
  iconColor: const Color(0xff0891B2),
  iconBg: const Color(0xffE0F7FA),
  title: 'Export Teachers',
  subtitle: 'Download teacher list as spreadsheet',

onTap: () async {

  Navigator.pop(ctx);

  final school =
      await ref.read(
    currentSchoolProvider.future,
  );

  await TeacherExportService
      .exportTeachers(
    school.id,
  );
},
),

          const SizedBox(height: 8),

_SheetTile(
  icon: Icons.file_upload_outlined,

  iconColor:
      const Color(0xff059669),

  iconBg:
      const Color(0xffD1FAE5),

  title: 'Import Teachers',

  subtitle:
      'Bulk import teachers from Excel',

  onTap: () async {

    Navigator.pop(ctx);

    final school =
        await ref.read(
      currentSchoolProvider.future,
    );

    await TeacherImportService
        .pickAndImportTeachers(

      context: ctx,
      schoolId: school.id,
    );
  },
),

const SizedBox(height: 8),

_SheetTile(
  icon: Icons.photo_library_outlined,

  iconColor:
      const Color(0xff2563EB),

  iconBg:
      const Color(0xffDBEAFE),

  title: 'Upload Teacher Photos',

  subtitle:
      'Bulk upload teacher profile photos',

 onTap: () async {

  Navigator.pop(ctx);

  final school =
      await ref.read(
    currentSchoolProvider.future,
  );

  await uploadTeacherPhotos(
    ctx,
    school.id,
  );
   
  },
),


//------------------------------------
          const SizedBox(height: 8),
          _SheetTile(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xffD97706),
            iconBg: const Color(0xffFEF3C7),
            title: 'Teacher Permissions',
            subtitle: 'Control what teachers can access',
            comingSoon: true,
          ),
          const SizedBox(height: 8),
          _SheetTile(
            icon: Icons.badge_outlined,
            iconColor: const Color(0xffDC2626),
            iconBg: const Color(0xffFEE2E2),
            title: 'Teacher Roles',
            subtitle: 'Assign roles like HOD, Class Teacher',
            comingSoon: true,
          ),
        ],
      ),
    ),
    );
  }
}





class _SheetTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool comingSoon;

  const _SheetTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF9FAFB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: comingSoon ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1F2937),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (comingSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xffF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Soon',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff9CA3AF),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xff9CA3AF),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}