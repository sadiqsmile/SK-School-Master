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

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  // Persistent open state for web row actions (legacy, can be removed)
  final Map<String, bool> _openRows = {};
  int? _hoverIndex;
  // STEP 1: Add ValueNotifier for open student row (web optimized)
  final ValueNotifier<String?> _openStudentId = ValueNotifier(null);
  String search = '';
  String selectedGroup = 'All';
  String selectedClass = 'All';
  String selectedSection = 'All';
  bool importing = false;

  final customInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.grey.shade400),
  );
  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);
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
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;
              final classList = docs
                  .map((e) => ((e.data() as Map<String, dynamic>)['className'] ?? '').toString())
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
              final students = docs.where((e) {
                final d = e.data() as Map<String, dynamic>;
                final name = (d['name'] ?? '').toString().toLowerCase();
                final className = (d['className'] ?? '').toString();
                final section = (d['section'] ?? '').toString();
                return _matchGroup(className, selectedGroup) &&
                    (selectedClass == 'All' || className == selectedClass) &&
                    (selectedSection == 'All' || section == selectedSection) &&
                    name.contains(search.toLowerCase());
              }).toList();
              students.sort((a, b) {
                final an = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString();
                final bn = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString();
                return an.compareTo(bn);
              });
              final groupCount = docs.where((e) {
                final d = e.data() as Map<String, dynamic>;
                return _matchGroup((d['className'] ?? '').toString(), selectedGroup);
              }).length;

              final mobile = MediaQuery.of(context).size.width < 600;

              String groupLabel =
                  selectedGroup == 'All'
                      ? 'Group'
                      : shortGroup(selectedGroup, mobile);

              String filteredLabel = 'Filtered';

              if (selectedGroup != 'All') {
                filteredLabel = shortGroup(selectedGroup, mobile);
              }

              if (selectedClass != 'All') {
                filteredLabel = 'Class $selectedClass';
              }

              if (selectedSection != 'All') {
                filteredLabel = 'Class $selectedClass $selectedSection';
              }

              final filteredClassList = _getFilteredClasses(selectedGroup, classList);
              final filteredSectionList = docs.where((e) {
                final d = e.data() as Map<String, dynamic>;
                return selectedClass != 'All' && (d['className'] ?? '').toString() == selectedClass;
              }).map((e) {
                return ((e.data() as Map<String, dynamic>)['section'] ?? '').toString();
              }).where((e) => e.isNotEmpty).toSet().toList()..sort();

              // Responsive layout: Stack for mobile, Column for web
              if (MediaQuery.of(context).size.width < 600) {
                // 📱 MOBILE (KEEP EXISTING STACK CODE)
                return Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _studentsHeroCard(students),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _card(
                                  'Total',
                                  docs.length.toString(),
                                  Icons.groups,
                                  const Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _card(
                                  groupLabel,
                                  selectedGroup == 'All' ? '-' : groupCount.toString(),
                                  Icons.school,
                                  const Color(0xFF4F46E5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _card(
                                  filteredLabel,
                                  students.length.toString(),
                                  Icons.filter_alt,
                                  const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final mobile = constraints.maxWidth < 700;
                              if (mobile) {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 44,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _showExportPopup(context, students.length, students),
                                              icon: const Icon(Icons.download, size: 18),
                                              label: const Text('Export'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SizedBox(
                                            height: 44,
                                            child: ElevatedButton.icon(
                                              onPressed: importing ? null : () => _importStudents(context, school.id),
                                              icon: const Icon(Icons.upload_file, size: 18),
                                              label: const Text('Import'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SizedBox(
                                            height: 44,
                                            child: ElevatedButton.icon(
                                              onPressed: () => context.push('/add-student'),
                                              icon: const Icon(Icons.person_add, size: 18),
                                              label: const Text('Add'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _groupDropdown()),
                                        const SizedBox(width: 8),
                                        Expanded(child: _classDropdown(filteredClassList)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _sectionDropdown(filteredSectionList)),
                                        const SizedBox(width: 8),
                                        Expanded(child: _searchField()),
                                      ],
                                    ),
                                  ],
                                );
                              }
                              // fallback (should not hit)
                              return const SizedBox();
                            },
                          ),
                          const SizedBox(height: 14),
                          const SizedBox(height: 10),
                          const SizedBox(height: 14),
                          // IMPORTANT: Add bottom space so sheet doesn't overlap
                          const SizedBox(height: 350),
                        ],
                      ),
                    ),
                    // MOBILE: floating draggable sheet with serial and divider
                    Positioned.fill(
                      child: DraggableScrollableSheet(
                        initialChildSize: 0.4,
                        minChildSize: 0.3,
                        maxChildSize: 0.95,
                        builder: (context, scrollController) {
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: students.isEmpty
                                        ? const Center(child: Text('No students found'))
                                        : ListView.builder(
                                            controller: scrollController,
                                            physics: const ClampingScrollPhysics(),
                                            itemCount: students.length,
                                            itemBuilder: (context, i) {
                                              final doc = students[i];
                                              final d = doc.data() as Map<String, dynamic>;
                                              final name = (d['name'] ?? '').toString();
                                              return Dismissible(
                                                key: ValueKey(doc.id),
                                                background: Container(
                                                  alignment: Alignment.centerLeft,
                                                  padding: const EdgeInsets.only(left: 20),
                                                  color: Colors.blue,
                                                  child: const Icon(Icons.edit, color: Colors.white),
                                                ),
                                                secondaryBackground: Container(
                                                  alignment: Alignment.centerRight,
                                                  padding: const EdgeInsets.only(right: 20),
                                                  color: Colors.red,
                                                  child: const Icon(Icons.delete, color: Colors.white),
                                                ),
                                                confirmDismiss: (direction) async {
                                                  if (direction == DismissDirection.startToEnd) {
                                                    context.push('/edit-student', extra: {
                                                      'studentId': doc.id,
                                                      'data': d,
                                                    });
                                                    return false;
                                                  } else {
                                                    return await _deleteStudent(
                                                      context,
                                                      school.id,
                                                      doc.id,
                                                      name,
                                                    );
                                                  }
                                                },
                                                child: Column(
                                                  children: [
                                                    ListTile(
                                                      leading: Text(
                                                        '${i + 1}.',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      title: Text(name),
                                                    ),
                                                    const Divider(
                                                      height: 1,
                                                      thickness: 0.6,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
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
                );
              }
              // 💻 WEB (OPTIMIZED MINIMAL LAYOUT)
              return Column(
                children: [
                  _studentsHeroCard(students),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _card(
                          'Total',
                          docs.length.toString(),
                          Icons.groups,
                          const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _card(
                          groupLabel,
                          selectedGroup == 'All' ? '-' : groupCount.toString(),
                          Icons.school,
                          const Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _card(
                          filteredLabel,
                          students.length.toString(),
                          Icons.filter_alt,
                          const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Filters and controls
                  Row(
                    children: [
                      _smallBtn('Export', Icons.download, () => _showExportPopup(context, students.length, students)),
                      const SizedBox(width: 8),
                      _smallBtn('Import', Icons.upload_file, importing ? null : () => _importStudents(context, school.id)),
                      const SizedBox(width: 8),
                      _smallBtn('Add', Icons.person_add, () => context.push('/add-student')),
                      const SizedBox(width: 16),
                      Expanded(child: _searchField()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _groupDropdown()),
                      const SizedBox(width: 10),
                      Expanded(child: _classDropdown(filteredClassList)),
                      const SizedBox(width: 10),
                      Expanded(child: _sectionDropdown(filteredSectionList)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Web student list (optimized, minimal, per-row expansion, improved UI)
                  Expanded(
                    child: students.isEmpty
                        ? const Center(child: Text('No students found'))
                        : ListView.builder(
                            cacheExtent: 800,
                            itemCount: students.length,
                            itemBuilder: (context, i) {
                              final doc = students[i];
                              final d = doc.data() as Map<String, dynamic>;
                              final name = (d['name'] ?? '').toString();
                              final className = (d['className'] ?? '').toString();
                              final section = (d['section'] ?? '').toString();

                              return ValueListenableBuilder<String?>(
                                valueListenable: _openStudentId,
                                builder: (context, openId, _) {
                                  final isOpen = openId == doc.id;
                                  return Column(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          _openStudentId.value = isOpen ? null : doc.id;
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          // 🎨 BACKGROUND COLOR (LIGHT + FAST)
                                          color: isOpen
                                              ? const Color(0xFFEDE9FE) // selected
                                              : (i % 2 == 0
                                                  ? const Color(0xFFF8FAFC) // zebra
                                                  : Colors.white),
                                          child: Row(
                                            children: [
                                              // 🔢 SERIAL
                                              SizedBox(
                                                width: 30,
                                                child: Text(
                                                  '${i + 1}',
                                                  style: TextStyle(
                                                    fontWeight: isOpen ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              // 📄 NAME + CLASS
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: TextStyle(
                                                        fontWeight: isOpen ? FontWeight.bold : FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      '$className - $section',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // 🔽 ARROW
                                              Icon(
                                                isOpen ? Icons.expand_less : Icons.expand_more,
                                                size: 18,
                                                color: isOpen ? Colors.deepPurple : Colors.grey,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // ⚡ ACTIONS (FAST)
                                      if (isOpen)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 40, bottom: 6),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                onPressed: () {
                                                  context.push('/edit-student', extra: {
                                                    'studentId': doc.id,
                                                    'data': d,
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () async {
                                                  await _deleteStudent(
                                                    context,
                                                    school.id,
                                                    doc.id,
                                                    name,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      const Divider(height: 1),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
// ...existing code...
  // (build method ends here)

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

 
 Future<bool> _deleteStudent(
  BuildContext context,
  String schoolId,
  String studentId,
  String name,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete Student'),
      content: Text('Delete $name ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (ok == true) {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(studentId)
        .delete();

    return true; // ✅ REQUIRED
  }

  return false; // ✅ REQUIRED
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
    final mobile = MediaQuery.of(context).size.width < 600;
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
  mainAxisAlignment: MainAxisAlignment.center,
  children: [

    // 🔹 ICON + LABEL
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: mobile ? 14 : 18,
        ),
        const SizedBox(width: 6),
       
       
       Text(
  title,
  style: TextStyle(
    color: Colors.white.withOpacity(0.95),
    fontSize: mobile ? 12 : 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  ),
),


      ],
    ),

    const SizedBox(height: 6),

    // 🔹 VALUE
    Text(
      value,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: mobile ? 18 : 26,
      ),
    ),
  ],
),
     
    );
  }

  String shortGroup(String group, bool mobile) {
    if (!mobile) return group;
    switch (group) {
      case 'Primary School':
        return 'PS';
      case 'Middle School':
        return 'MS';
      case 'High School':
        return 'HS';
      default:
        return group;
    }
  }

  Widget _smallBtn(String text, IconData icon, VoidCallback? onTap) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF5B21B6),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(text),
      ),
    );
  }

  Widget _searchField() {
    return SizedBox(
      height: 40,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          border: customInputBorder,
        ),
        onChanged: (v) {
          setState(() => search = v);
        },
      ),
    );
  }

  Widget _groupDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGroup,
      decoration: InputDecoration(labelText: 'Group', border: customInputBorder),
      items: const [
        'All',
        'Nursery',
        'Primary School',
        'Middle School',
        'High School',
        'College',
      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          selectedGroup = v;
          selectedClass = 'All';
          selectedSection = 'All';
        });
      },
    );
  }

  Widget _classDropdown(List<String> list) {
    return DropdownButtonFormField<String>(
      value: selectedClass,
      decoration: InputDecoration(labelText: 'Class', border: customInputBorder),
      items: [
        const DropdownMenuItem(value: 'All', child: Text('All')),
        ...list.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      ],
      onChanged: selectedGroup == 'All'
          ? null
          : (v) {
            if (v == null) return;
            setState(() {
              selectedClass = v;
              selectedSection = 'All';
            });
          },
    );
  }

  Widget _sectionDropdown(List<String> list) {
    return DropdownButtonFormField<String>(
      value: selectedSection,
      decoration: InputDecoration(labelText: 'Section', border: customInputBorder),
      items: [
        const DropdownMenuItem(value: 'All', child: Text('All')),
        ...list.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      ],
      onChanged: selectedClass == 'All'
          ? null
          : (v) {
            if (v == null) return;
            setState(() {
              selectedSection = v;
            });
          },
    );
}



//_________________________________________________________________________________________
//mini hero card inside the big hero card__________________________________________________

 Widget _heroMiniCard(
  String title,
  String value,
  IconData icon,
  bool mobile,
   Color color,
) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: 6,
      vertical: mobile ? 4 : 10,
    ),



//   decoration: BoxDecoration(
//   borderRadius: BorderRadius.circular(16),
//   border: Border.all(color: Colors.white.withOpacity(.08)),
//   color: Colors.white.withOpacity(0.05), // 👈 ADD THIS
//   gradient: LinearGradient(
//     colors: [
//       color.withOpacity(0.35),
//       color.withOpacity(0.15),
//     ],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   ),
// ),
    
decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(16),
  color: color, // ✅ solid color
),



    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🔹 ICON + TITLE (same line)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
           
           Text(
  title,
  style: TextStyle(
    color: Colors.white.withOpacity(0.95),
    fontSize: mobile ? 12 : 13, // 🔼 slightly bigger
    fontWeight: FontWeight.w600, // 🔥 bold
    letterSpacing: 0.3, // 👌 clean spacing
  ),
),




          ],
        ),

        const SizedBox(height: 3),

        // 🔹 VALUE
    Text(
  value,
  style: TextStyle(
    color: Colors.white,
    fontSize: mobile ? 18 : 20,
    fontWeight: FontWeight.w800,
  ),
),
      ],
    ),
  );
}

//___________________________________________________________________________________________
//student hero card with quick stats-----------------------------------------------
Widget _studentsHeroCard(List docs) {
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


  final mobile =
      MediaQuery.of(context).size.width < 600;

final cards = [
  _heroMiniCard('Hostel', '$hostel', Icons.apartment, mobile, const Color(0xFF4F46E5)), // Indigo
  _heroMiniCard('Day', '$dayScholar', Icons.home, mobile, const Color(0xFF2563EB)), // Blue
  _heroMiniCard('Girls', '$girls', Icons.girl, mobile, const Color(0xFFEC4899)), // Pink
  _heroMiniCard('Boys', '$boys', Icons.boy, mobile, const Color(0xFF06B6D4)), // Cyan
  _heroMiniCard('Mess', '$messYes', Icons.restaurant, mobile, const Color.fromRGBO(255, 16, 185, 129)), // Amber
  _heroMiniCard('Bus', '$transportYes', Icons.directions_bus, mobile, const Color.fromARGB(245, 238, 204, 10)), // Green
];

  return Container(
    width: double.infinity,
    padding:
        const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
    ),

    // 🔥 FINAL CORRECT STRUCTURE
    child: mobile
        ? Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Students Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
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
              const SizedBox(height: 8),

              GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (_, i) =>
                    cards[i],
              ),
            ],
          )

        // 🔥 WEB FIXED
        : Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Students Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight:
                            FontWeight.w800,
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

              const SizedBox(width: 20),

            Expanded(
  child: Center(
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: cards
          .map((e) => SizedBox(
                width: 140,
                child: e,
              ))
          .toList(),
    ),
  ),
),

            
            ],
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