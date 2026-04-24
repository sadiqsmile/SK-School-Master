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
                padding:
                    const EdgeInsets.all(14),
                child: Column(
                  children: [
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

                    Row(
                      children: [
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed: () =>
                                _showExportPopup(
                              context,
                              students.length,
                              students,
                            ),
                            icon: const Icon(
                              Icons.download,
                            ),
                            label: const Text(
                              'Export',
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 8),
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                importing
                                    ? null
                                    : () =>
                                        _importStudents(
                                          context,
                                          school
                                              .id,
                                        ),
                            icon: const Icon(
                              Icons
                                  .upload_file,
                            ),
                            label: const Text(
                              'Import',
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 8),
                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed: () {
                              context.push(
                                  '/add-student');
                            },
                            icon: const Icon(
                              Icons
                                  .person_add,
                            ),
                            label: const Text(
                              'Add',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 14),

                    Row(
                      children: [
                        Expanded(
                          child:
                              DropdownButtonFormField<
                                  String>(
                            value:
                                selectedGroup,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Group',
                              border:
                                  OutlineInputBorder(),
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
                          child:
                              DropdownButtonFormField<
                                  String>(
                            value:
                                selectedClass,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Class',
                              border:
                                  OutlineInputBorder(),
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
                          child:
                              DropdownButtonFormField<
                                  String>(
                            value:
                                selectedSection,
                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Section',
                              border:
                                  OutlineInputBorder(),
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
                                const InputDecoration(
                              hintText:
                                  'Search...',
                              prefixIcon:
                                  Icon(
                                Icons.search,
                              ),
                              border:
                                  OutlineInputBorder(),
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

                                return Card(
                                  child:
                                      ListTile(
                                    leading:
                                        CircleAvatar(
                                      child:
                                          Text(
                                        name.isEmpty
                                            ? '?'
                                            : name[
                                                0],
                                      ),
                                    ),
                                    title:
                                        Text(
                                      name,
                                    ),
                                    subtitle:
                                        Text(
                                      '$className - $section',
                                    ),
                                    trailing:
                                        Row(
                                      mainAxisSize:
                                          MainAxisSize
                                              .min,
                                      children: [
                                        IconButton(
                                          icon:
                                              const Icon(
                                            Icons.edit,
                                            color:
                                                Colors.blue,
                                          ),
                                          onPressed:
                                              () {
                                            context.push(
                                              '/edit-student',
                                              extra: {
                                                'studentId':
                                                    doc.id,
                                                'data':
                                                    d,
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon:
                                              const Icon(
                                            Icons.delete,
                                            color:
                                                Colors.red,
                                          ),
                                          onPressed:
                                              () =>
                                                  _deleteStudent(
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
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
                Colors.white,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            value,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontWeight:
                  FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            style:
                const TextStyle(
              color:
                  Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportDialog
    extends StatelessWidget {
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