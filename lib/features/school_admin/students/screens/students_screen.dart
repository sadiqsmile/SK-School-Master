import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/current_school_provider.dart';

import '../services/student_import_service.dart';
import '../services/student_template_service.dart';
import '../services/student_service.dart';

const _titleStyle = TextStyle(
  fontSize: 15.5,
  fontWeight: FontWeight.w500,
  color: Color(0xFF111827),
);

const _subtitleStyle = TextStyle(
  fontSize: 12.5,
  color: Color(0xFF6B7280),
);

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
                // 📱 MOBILE
                return Container(
                  color: const Color(0xFFF5F7FB),
                  child: Stack(
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
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _actionBtn(Icons.download, 'Export', () => _showExportPopup(context, students.length, students)),
                                            _actionBtn(Icons.upload_file, 'Import', importing ? null : () => _importStudents(context, school.id)),
                                            _actionBtn(Icons.person_add, 'Add', () => context.push('/add-student')),
                                            _actionBtn(Icons.photo_library, 'Upload', () => _uploadBulkPhotos(context, school.id)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE5E7EB)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _inputBox(
                                              DropdownButton<String>(
                                                value: selectedGroup,
                                                underline: const SizedBox(),
                                                isExpanded: true,
                                                items: const ['All', 'Nursery', 'Primary School', 'Middle School', 'High School', 'College']
                                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                                    .toList(),
                                                onChanged: (v) {
                                                  if (v == null) return;
                                                  setState(() {
                                                    selectedGroup = v;
                                                    selectedClass = 'All';
                                                    selectedSection = 'All';
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _inputBox(
                                              DropdownButton<String>(
                                                value: selectedClass,
                                                underline: const SizedBox(),
                                                isExpanded: true,
                                                items: ['All', ...filteredClassList]
                                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                                    .toList(),
                                                onChanged: selectedGroup == 'All' ? null : (v) {
                                                  if (v == null) return;
                                                  setState(() {
                                                    selectedClass = v;
                                                    selectedSection = 'All';
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _inputBox(
                                              DropdownButton<String>(
                                                value: selectedSection,
                                                underline: const SizedBox(),
                                                isExpanded: true,
                                                items: ['All', ...filteredSectionList]
                                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                                    .toList(),
                                                onChanged: selectedClass == 'All' ? null : (v) {
                                                  if (v == null) return;
                                                  setState(() => selectedSection = v);
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _inputBox(
                                              TextField(
                                                decoration: const InputDecoration(
                                                  hintText: 'Search...',
                                                  border: InputBorder.none,
                                                  icon: Icon(Icons.search, size: 18),
                                                ),
                                                onChanged: (v) => setState(() => search = v),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      title: Text(
                                                        name,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 15.5,
                                                          fontWeight: FontWeight.w400,
                                                          color: const Color(0xFF111827),
                                                        ),
                                                      ),
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
                ),  // end Stack
                );  // end Container
              }
              // 💻 WEB (OPTIMIZED MINIMAL LAYOUT)
              return Container(
                color: const Color(0xFFF5F7FB),
                child: Column(
                children: [
                  _studentsHeroCard(students),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
                  // Filters and controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _searchField()),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          _actionBtn(Icons.download, 'Export', () => _showExportPopup(context, students.length, students)),
                          const SizedBox(width: 8),
                          _actionBtn(Icons.upload_file, 'Import', importing ? null : () => _importStudents(context, school.id)),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/add-student'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _actionBtn(Icons.photo_library, 'Upload', () => _uploadBulkPhotos(context, school.id)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _inputBox(
                            DropdownButton<String>(
                              value: selectedGroup,
                              underline: const SizedBox(),
                              isExpanded: true,
                              items: const ['All', 'Nursery', 'Primary School', 'Middle School', 'High School', 'College']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() {
                                  selectedGroup = v;
                                  selectedClass = 'All';
                                  selectedSection = 'All';
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _inputBox(
                            DropdownButton<String>(
                              value: selectedClass,
                              underline: const SizedBox(),
                              isExpanded: true,
                              items: ['All', ...filteredClassList]
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: selectedGroup == 'All' ? null : (v) {
                                if (v == null) return;
                                setState(() {
                                  selectedClass = v;
                                  selectedSection = 'All';
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _inputBox(
                            DropdownButton<String>(
                              value: selectedSection,
                              underline: const SizedBox(),
                              isExpanded: true,
                              items: ['All', ...filteredSectionList]
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: selectedClass == 'All' ? null : (v) {
                                if (v == null) return;
                                setState(() => selectedSection = v);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _inputBox(
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search...',
                                border: InputBorder.none,
                                icon: Icon(Icons.search, size: 18),
                              ),
                              onChanged: (v) => setState(() => search = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Web student list (optimized, minimal, per-row expansion, improved UI)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: students.isEmpty
                          ? const Center(
                              child: Text(
                                'No students found',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
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
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: InkWell(
                                          onTap: () {
                                            _openStudentId.value = isOpen ? null : doc.id;
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isOpen
                                                  ? const Color(0xFFE8ECF8)
                                                  : (i % 2 == 0 ? Colors.white : const Color(0xFFF9FAFB)),
                                            ),
                                          child: Row(
                                            children: [
                                              // 🔢 SERIAL
                                              SizedBox(
                                                width: 30,
                                                child: Text(
                                                  '${i + 1}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              // 👤 AVATAR
                                              SizedBox(
                                                width: 32,
                                                height: 32,
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(50),
                                                  child: (d['photoUrl'] != null && d['photoUrl'] != '')
                                                      ? CachedNetworkImage(
                                                          imageUrl: d['photoUrl'],
                                                          fit: BoxFit.cover,
                                                          placeholder: (context, url) => Container(
                                                            color: const Color(0xFFEDE9FE),
                                                            child: const Center(
                                                              child: SizedBox(
                                                                width: 12,
                                                                height: 12,
                                                                child: CircularProgressIndicator(strokeWidth: 2),
                                                              ),
                                                            ),
                                                          ),
                                                          errorWidget: (context, url, error) => Container(
                                                            color: const Color(0xFFEDE9FE),
                                                            child: Center(
                                                              child: Text(
                                                                name.isNotEmpty ? name[0] : '?',
                                                                style: const TextStyle(
                                                                  color: Color(0xFF4F46E5),
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          color: const Color(0xFFEDE9FE),
                                                          child: Center(
                                                            child: Text(
                                                              name.isNotEmpty ? name[0] : '?',
                                                              style: const TextStyle(
                                                                color: Color(0xFF4F46E5),
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              // 📄 NAME + CLASS
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: isOpen
                                                          ? _titleStyle.copyWith(fontWeight: FontWeight.w600)
                                                          : _titleStyle,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '$className - $section',
                                                      style: _subtitleStyle,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // 🔽 ARROW
                                              Icon(
                                                isOpen ? Icons.expand_less : Icons.expand_more,
                                                color: Colors.grey,
                                              ),
                                            ],
                                            ),
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
                                                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                                onPressed: () {
                                                  context.push('/edit-student', extra: {
                                                    'studentId': doc.id,
                                                    'data': d,
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
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
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),  // end ListView
                    ),  // end Container
                  ),  // end Expanded
                ],
              ),  // end Column
              );  // end Container
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

  Future<void> _uploadBulkPhotos(BuildContext context, String schoolId) async {
    final files = await StudentImportService.pickMultipleImages();
    if (files.isEmpty) return;

    int uploaded = 0;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    for (final file in files) {
      final name = file.name.replaceAll(RegExp(r'\.[^/.]+$'), '');
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .where('name', isEqualTo: name)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) continue;

        final ref = FirebaseStorage.instance
            .ref('schools/$schoolId/photos/$name.jpg');
        final compressedBytes = await FlutterImageCompress.compressWithList(
          file.bytes!,
          minWidth: 300,
          minHeight: 300,
          quality: 60,
        );
        await ref.putData(compressedBytes);
        final url = await ref.getDownloadURL();

        await snapshot.docs.first.reference.update({'photoUrl': url});
        uploaded++;
      } catch (e) {
        debugPrint('Upload error: $e');
      }
    }

    if (mounted) Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded $uploaded photos')),
      );
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
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

  Widget _actionBtn(IconData icon, String label, VoidCallback? onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  Widget _inputBox(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
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

  Widget _topChip(IconData icon, String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 6),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
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


  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      gradient: const LinearGradient(
        colors: [
          Color(0xFFF8FAFF),
          Color(0xFFEFF3FF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Students Dashboard',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Premium analytics & quick stats',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _topChip(Icons.bed, 'Hostel', hostel, const Color(0xFF4F46E5)),
                  _topChip(Icons.home, 'Day', dayScholar, const Color(0xFF2563EB)),
                  _topChip(Icons.female, 'Girls', girls, const Color(0xFFEC4899)),
                  _topChip(Icons.male, 'Boys', boys, const Color(0xFF06B6D4)),
                  _topChip(Icons.restaurant, 'Mess', messYes, const Color(0xFF059669)),
                  _topChip(Icons.directions_bus, 'Bus', transportYes, const Color(0xFFF59E0B)),
                ],
              ),
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