import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/current_school_provider.dart';

import '../services/student_import_service.dart';
import '../services/student_template_service.dart';
import '../services/student_service.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() =>
      _StudentsScreenState();
}

class _StudentsScreenState
    extends ConsumerState<StudentsScreen> {
  String search = '';
  String selectedGroup = 'All';
  String selectedClass = 'All';
  String selectedSection = 'All';
  bool importing = false;

  // Custom border for all input fields
  static OutlineInputBorder customInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: Colors.grey.shade300,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final schoolAsync =
        ref.watch(currentSchoolProvider);

    return AdminLayout(
      title: 'Students',
      body: schoolAsync.when(
        data: (school) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(school.id)
                .collection('students')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final docs = snap.data!.docs;

              final classList = docs
                  .map((e) =>
                      ((e.data() as Map<String,
                                  dynamic>)[
                              'className'] ??
                          '')
                          .toString())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

              final students =
                  docs.where((e) {
                final d = e.data()
                    as Map<String, dynamic>;

                final name =
                    (d['name'] ?? '')
                        .toString()
                        .toLowerCase();

                final className =
                    (d['className'] ?? '')
                        .toString();

                final section =
                    (d['section'] ?? '')
                        .toString();

                return _matchGroup(
                          className,
                          selectedGroup,
                        ) &&
                    (selectedClass ==
                            'All' ||
                        className ==
                            selectedClass) &&
                    (selectedSection ==
                            'All' ||
                        section ==
                            selectedSection) &&
                    name.contains(
                      search.toLowerCase(),
                    );
              }).toList();

              students.sort((a, b) {
                final an = ((a.data()
                            as Map<String,
                                dynamic>)['name'] ??
                        '')
                    .toString();

                final bn = ((b.data()
                            as Map<String,
                                dynamic>)['name'] ??
                        '')
                    .toString();

                return an.compareTo(bn);
              });

              final groupCount =
                  docs.where((e) {
                final d = e.data()
                    as Map<String, dynamic>;

                return _matchGroup(
                  (d['className'] ?? '')
                      .toString(),
                  selectedGroup,
                );
              }).length;

              final filteredClassList =
                  _getFilteredClasses(
                selectedGroup,
                classList,
              );

              final filteredSectionList =
                  docs.where((e) {
                final d = e.data()
                    as Map<String, dynamic>;

                return selectedClass !=
                        'All' &&
                    (d['className'] ?? '')
                            .toString() ==
                        selectedClass;
              }).map((e) {
                return ((e.data()
                            as Map<String,
                                dynamic>)['section'] ??
                        '')
                    .toString();
              }).where((e) => e.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  children: [
                    _studentsHeroCard(docs),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _card(
                            'Total',
                            docs.length
                                .toString(),
                            Icons.groups,
                            const Color(
                              0xFF2563EB,
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 8),
                        Expanded(
                          child: _card(
                            'Group',
                            selectedGroup ==
                                    'All'
                                ? '-'
                                : groupCount
                                    .toString(),
                            Icons.school,
                            const Color(
                              0xFF4F46E5,
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 8),
                        Expanded(
                          child: _card(
                            'Filtered',
                            students.length
                                .toString(),
                            Icons.filter_alt,
                            const Color(
                              0xFF059669,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 14),




LayoutBuilder(
  builder: (context, constraints) {
    final mobile = constraints.maxWidth < 700;

    if (mobile) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5B21B6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              onPressed: () => _showExportPopup(
                context,
                students.length,
                students,
              ),
              icon: const Icon(Icons.download),
              label: const Text('Export'),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5B21B6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              onPressed: importing
                  ? null
                  : () => _importStudents(
                        context,
                        school.id,
                      ),
              icon: const Icon(Icons.upload_file),
              label: const Text('Import'),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5B21B6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              onPressed: () {
                context.push('/add-student');
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5B21B6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              onPressed: () => _showExportPopup(
                context,
                students.length,
                students,
              ),
              icon: const Icon(Icons.download),
              label: const Text('Export'),
            ),
          ),
        ),
        const SizedBox(width: 8),

        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5B21B6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              onPressed: importing
                  ? null
                  : () => _importStudents(
                        context,
                        school.id,
                      ),
              icon: const Icon(Icons.upload_file),
              label: const Text('Import'),
            ),
          ),
        ),
        const SizedBox(width: 8),

        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5B21B6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              onPressed: () {
                context.push('/add-student');
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add'),
            ),
          ),
        ),
      ],
    );
  },
),







                    const SizedBox(
                        height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<
                                  String>(
                            value:
                                selectedGroup,
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Group',
                              border: customInputBorder,
                            ),
                            items: const [
                              'All',
                              'Nursery',
                              'Primary School',
                              'Middle School',
                              'High School',
                              'College',
                            ]
                                .map((e) =>
                                    DropdownMenuItem(
                                      value:
                                          e,
                                      child:
                                          Text(
                                        e,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v ==
                                  null) {
                                return;
                              }

                              setState(() {
                                selectedGroup =
                                    v;
                                selectedClass =
                                    'All';
                                selectedSection =
                                    'All';
                              });
                            },
                          ),
                        ),
                        const SizedBox(
                            width: 8),
                        Expanded(
                          child: DropdownButtonFormField<
                                  String>(
                            value:
                                selectedClass,
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Class',
                              border: customInputBorder,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value:
                                    'All',
                                child:
                                    Text(
                                  'All',
                                ),
                              ),
                              ...filteredClassList
                                  .map(
                                (e) =>
                                    DropdownMenuItem(
                                  value:
                                      e,
                                  child:
                                      Text(
                                    e,
                                  ),
                                ),
                              ),
                            ],
                            onChanged:
                                selectedGroup ==
                                        'All'
                                    ? null
                                    : (v) {
                                        if (v ==
                                            null) {
                                          return;
                                        }

                                        setState(
                                            () {
                                          selectedClass =
                                              v;
                                          selectedSection =
                                              'All';
                                        });
                                      },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<
                                  String>(
                            value:
                                selectedSection,
                            decoration:
                                InputDecoration(
                              labelText:
                                  'Section',
                              border: customInputBorder,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value:
                                    'All',
                                child:
                                    Text(
                                  'All',
                                ),
                              ),
                              ...filteredSectionList
                                  .map(
                                (e) =>
                                    DropdownMenuItem(
                                  value:
                                      e,
                                  child:
                                      Text(
                                    e,
                                  ),
                                ),
                              ),
                            ],
                            onChanged:
                                selectedClass ==
                                        'All'
                                    ? null
                                    : (v) {
                                        if (v ==
                                            null) {
                                          return;
                                        }

                                        setState(
                                            () {
                                          selectedSection =
                                              v;
                                        });
                                      },
                          ),
                        ),
                        const SizedBox(
                            width: 8),
                        Expanded(
                          child: TextField(
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Search...',
                              prefixIcon:
                                  Icon(
                                Icons.search,
                              ),
                              border: customInputBorder,
                            ),
                            onChanged: (v) {
                              setState(() {
                                search =
                                    v;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 14),

                    Expanded(
                      child: students
                              .isEmpty
                          ? const Center(
                              child: Text(
                                'No students found',
                              ),
                            )
                          : ListView.builder(
                              itemCount:
                                  students
                                      .length,
                              itemBuilder:
                                  (context,
                                      i) {
                                final doc =
                                    students[
                                        i];

                                final d = doc
                                        .data()
                                    as Map<String,
                                        dynamic>;

                                final name =
                                    (d['name'] ??
                                            '')
                                        .toString();

                                final className =
                                    (d['className'] ??
                                            '')
                                        .toString();

                                final section =
                                    (d['section'] ??
                                            '')
                                        .toString();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFF1F5F9),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(0xFFEDE9FE),
                                      child: Text(
                                        name.isEmpty ? '?' : name[0],
                                        style: const TextStyle(
                                          color: Color(0xFF5B21B6),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(name),
                                    subtitle: Text('$className - $section'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            context.push(
                                              '/edit-student',
                                              extra: {
                                                'studentId': doc.id,
                                                'data': d,
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _deleteStudent(
                                            context,
                                            school.id,
                                            doc.id,
                                            name,
                                          ),
                                        ),
                                      ],
                                    ),
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
        loading: () => const Center(
          child:
              CircularProgressIndicator(),
        ),
        error: (e, _) =>
            Center(child: Text('$e')),
      ),
    );
  }

  List<String> _getFilteredClasses(
    String group,
    List<String> classList,
  ) {
    if (group == 'Primary School') {
      return [
        '1',
        '2',
        '3',
        '4',
        '5',
      ];
    }

    if (group == 'Middle School') {
      return ['6', '7', '8'];
    }

    if (group == 'High School') {
      return ['9', '10'];
    }

    if (group == 'Nursery') {
      return ['LKG', 'UKG'];
    }

    if (group == 'College') {
      return ['1-PU', '2-PU'];
    }

    return classList;
  }

  Future<void> _showExportPopup(
    BuildContext context,
    int count,
    List<QueryDocumentSnapshot>
        students,
  ) async {
    final action =
        await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title:
            const Text('Export Options'),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.table_chart,
              ),
              title: const Text(
                'Export Current Students',
              ),
              onTap: () =>
                  Navigator.pop(
                context,
                'students',
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.description,
              ),
              title: const Text(
                'Blank Import Template',
              ),
              onTap: () =>
                  Navigator.pop(
                context,
                'template',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
                    context),
            child:
                const Text('Cancel'),
          ),
        ],
      ),
    );

    if (action == 'template') {
      await StudentTemplateService
          .exportBlankTemplate();
    }

    if (action == 'students') {
      final rows =
          students.map((doc) {
        return doc.data()
            as Map<String, dynamic>;
      }).toList();

      await StudentTemplateService
          .exportStudentsExcel(
        studentsData: rows,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Exported $count students',
            ),
          ),
        );
      }
    }
  }

  Future<void> _importStudents(
    BuildContext context,
    String schoolId,
  ) async {
    final rows =
        await StudentImportService
            .pickAndReadExcel();

    if (rows.isEmpty) return;

    setState(() => importing = true);

    final progress =
        ValueNotifier<double>(0);
    final status =
        ValueNotifier<String>(
      'Preparing...',
    );

    int added = 0;
    int updated = 0;
    int skipped = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _ImportDialog(
        progress: progress,
        status: status,
      ),
    );

    final service =
        StudentService();

    for (int i = 0;
        i < rows.length;
        i++) {
      final row = rows[i];

      status.value =
          'Processing ${i + 1} of ${rows.length}';

      try {
        final id =
            (row['admissionNo'] ??
                    '')
                .toString()
                .trim()
                .toUpperCase();

        final existing =
            await FirebaseFirestore
                .instance
                .collection(
                    'schools')
                .doc(schoolId)
                .collection(
                    'students')
                .doc(id)
                .get();

        await service
            .upsertStudent(
          schoolId: schoolId,
          data: row,
        );

        if (existing.exists) {
          updated++;
        } else {
          added++;
        }
      } catch (_) {
        skipped++;
      }

      progress.value =
          (i + 1) /
              rows.length;
    }

    if (mounted) {
      Navigator.pop(context);
    }

    setState(() => importing = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius
                    .circular(
              20,
            ),
          ),
          title: const Text(
            '✅ Import Successful',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              _sum(
                'Added',
                added,
              ),
              _sum(
                'Updated',
                updated,
              ),
              _sum(
                'Skipped',
                skipped,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
              ),
              child:
                  const Text(
                'Done',
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _sum(
    String t,
    int v,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(t),
          Text(
            v.toString(),
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(
    BuildContext context,
    String schoolId,
    String studentId,
    String name,
  ) async {
    final ok =
        await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete Student',
        ),
        content: Text(
          'Delete $name ?',
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
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child:
                const Text(
              'Delete',
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseFirestore
          .instance
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .delete();
    }
  }

  bool _matchGroup(
    String className,
    String group,
  ) {
    if (group == 'All') {
      return true;
    }

    final c = className
        .trim()
        .toUpperCase();

    if (group == 'Nursery') {
      return c == 'LKG' ||
          c == 'UKG';
    }

    if (group ==
        'Primary School') {
      return [
        '1',
        '2',
        '3',
        '4',
        '5'
      ].contains(c);
    }

    if (group ==
        'Middle School') {
      return [
        '6',
        '7',
        '8'
      ].contains(c);
    }

    if (group ==
        'High School') {
      return [
        '9',
        '10'
      ].contains(c);
    }

    if (group == 'College') {
      return c.contains('PU');
    }

    return false;
  }

  Widget _card(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(.82),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMiniCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

Widget _studentsHeroCard(List docs) {
  final total = docs.length;

  final hostel = docs.where((e) {
    final d = e.data() as Map<String, dynamic>;
    final v = (d['type'] ?? d['residence'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return v == 'hostel' || v == 'h';
  }).length;

  final dayScholar = docs.where((e) {
    final d = e.data() as Map<String, dynamic>;
    final v = (d['type'] ?? d['residence'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return v == 'day' ||
        v == 'd' ||
        v == 'day scholar' ||
        v == 'dayscholar';
  }).length;

  final girls = docs.where((e) {
    final d = e.data() as Map<String, dynamic>;
    final g = (d['gender'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return g == 'female' || g == 'f';
  }).length;

  final boys = docs.where((e) {
    final d = e.data() as Map<String, dynamic>;
    final g = (d['gender'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return g == 'male' || g == 'm';
  }).length;

  final messYes = docs.where((e) {
    final d = e.data() as Map<String, dynamic>;
    final v = (d['mess'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return v == 'yes' ||
        v == 'y' ||
        v == '1' ||
        v == 'true';
  }).length;

  final transportYes = docs.where((e) {
    final d = e.data() as Map<String, dynamic>;
    final v = (d['transport'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return v == 'yes' ||
        v == 'y' ||
        v == '1' ||
        v == 'true';
  }).length;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF5B5CEB),
          Color(0xFF4F7CF7),
        ],
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(.14),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, c) {
        final mobile = c.maxWidth < 900;

        final cards = [
          _heroMiniCard('Hostel', '$hostel', Icons.apartment),
          _heroMiniCard('Day', '$dayScholar', Icons.home),
          _heroMiniCard('Girls', '$girls', Icons.girl),
          _heroMiniCard('Boys', '$boys', Icons.boy),
          _heroMiniCard('Mess', '$messYes', Icons.restaurant),
          _heroMiniCard('Bus', '$transportYes', Icons.directions_bus),
        ];

        if (mobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Students Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Premium analytics & quick stats',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (_, i) => cards[i],
              ),
            ],
          );
        }






      return SizedBox(
  width: double.infinity,
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 250,
        alignment: Alignment.centerLeft,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Students Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Premium analytics & quick stats',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(width: 8),

       Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: cards,
          ),
        ),
      ),
    ],
  ),
);
      },
    ),
  );
}
    }  

class _ImportDialog extends StatelessWidget {
  const _ImportDialog({
    required this.progress,
    required this.status,
  });

  final ValueNotifier<double>
      progress;
  final ValueNotifier<String>
      status;

  @override
  Widget build(
      BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child:
            ValueListenableBuilder<
                double>(
          valueListenable:
              progress,
          builder: (_, v, __) {
            return Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                SizedBox(
                  width: 95,
                  height: 95,
                  child: Stack(
                    alignment:
                        Alignment
                            .center,
                    children: [
                      CircularProgressIndicator(
                        value: v,
                        strokeWidth:
                            8,
                        color: Colors
                            .green,
                        backgroundColor:
                            Colors.green.shade100,
                      ),
                      Text(
                        '${(v * 100).toInt()}%',
                        style:
                            const TextStyle(
                          fontSize:
                              22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                const Text(
                  'Importing Students',
                  style:
                      TextStyle(
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                ValueListenableBuilder<
                    String>(
                  valueListenable:
                      status,
                  builder:
                      (_, s, __) {
                    return Text(
                      s,
                      style:
                          const TextStyle(
                        color: Colors
                            .grey,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}