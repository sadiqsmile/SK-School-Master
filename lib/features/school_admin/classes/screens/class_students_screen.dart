// features/school_admin/classes/screens/class_students_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/core/widgets/profile_avatar.dart';

class ClassStudentsScreen extends ConsumerStatefulWidget {
  final String className;

  const ClassStudentsScreen({super.key, required this.className});

  @override
  ConsumerState<ClassStudentsScreen> createState() =>
      _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends ConsumerState<ClassStudentsScreen> {
  String selectedSection = 'All';

  List<String> get _classNameVariants {
    final name = widget.className;
    final stripped =
        name.replaceAll(RegExp(r'^Class\s+', caseSensitive: false), '').trim();
    return stripped == name ? [name] : [name, stripped];
  }

  @override
  Widget build(BuildContext context) {
    print('OPENED CLASS = ${widget.className}');

    final schoolAsync = ref.watch(currentSchoolProvider);

    return schoolAsync.when(
      data: (school) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schools')
              .doc(school.id)
              .collection('students')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: Text(widget.className)),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final allDocs = snapshot.data!.docs;

            final sectionSet = <String>{};

            for (final doc in allDocs) {
              final s = (doc.data() as Map<String, dynamic>)['section']
                      ?.toString()
                      .trim()
                      .toUpperCase() ??
                  '';

              if (s.isNotEmpty) {
                sectionSet.add(s);
              }
            }

            final sections = ['All', ...sectionSet.toList()..sort()];

            final classNumber =
                widget.className.replaceAll('Class ', '').trim();

            final classStudents = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final studentClass = (data['className'] ?? '').toString().trim();

              return studentClass == widget.className ||
                  studentClass ==
                      widget.className.replaceAll('Class ', '').trim();
            }).toList();



classStudents.sort((a, b) {
  final aName =
      ((a.data() as Map<String, dynamic>)['name'] ?? '')
          .toString()
          .toUpperCase();

  final bName =
      ((b.data() as Map<String, dynamic>)['name'] ?? '')
          .toString()
          .toUpperCase();

  return aName.compareTo(bName);
});








            final docs = selectedSection == 'All'
                ? classStudents
                : classStudents.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return data['section'] == selectedSection;
                  }).toList();

            return Scaffold(
              backgroundColor: const Color(0xffF8FAFC),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  selectedSection == 'All'
                      ? widget.className
                      : '${widget.className} — $selectedSection',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xff111827),
                  ),
                ),
              ),
              body: Column(
                children: [
                  if (sections.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: sections.map((section) {
                            final isSelected = selectedSection == section;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(section),
                                selected: isSelected,
                                selectedColor: const Color(0xff5B5FEF),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xff374151),
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) {
                                  setState(() => selectedSection = section);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${docs.length} student${docs.length == 1 ? "" : "s"}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (docs.isEmpty)
                    const Expanded(
                      child: Center(child: Text('No students found')),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final name = (data['name'] ?? '').toString();
                          final section = (data['section'] ?? '').toString();
                          final admissionNo =
                              (data['admissionNo'] ?? '').toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xffF3F4F6),
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ProfileAvatar(
                                  name: name,
                                  imageUrl: data['photoUrl']?.toString(),
                                  radius: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: Color(0xff111827),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Section $section  •  Adm: $admissionNo',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
