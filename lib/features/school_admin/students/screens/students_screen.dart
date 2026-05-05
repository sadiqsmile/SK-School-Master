import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app/main.dart' show messengerKey, navigatorKey;
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/services/image_upload_service.dart';
import '../services/student_import_service.dart';
import '../services/student_template_service.dart';
import '../services/student_service.dart';
import 'package:school_app/features/tools/rename_photos_screen.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'package:school_app/core/utils/text_formatters.dart';
import '../services/template_export_stub.dart'
    if (dart.library.io) '../services/template_export_io.dart'
    if (dart.library.html) '../services/template_export_web.dart';



const _titleStyle = TextStyle(
  fontSize: 15.5,
  fontWeight: FontWeight.w500,
  color: Color(0xFF111827),
);

const _subtitleStyle = TextStyle(
  fontSize: 12.5,
  color: Color(0xFF6B7280),
);

class _CompressedImage {
  final String admissionNo;
  final Uint8List bytes;

  _CompressedImage({required this.admissionNo, required this.bytes});
}

// ── Responsive helpers ──────────────────────────────────────────────────────
class ScreenType {
  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;
}

double _fs(BuildContext context, double size) {
  final w = MediaQuery.of(context).size.width;
  if (w < 360) return size - 2;
  if (w < 600) return size;
  return size + 2;
}

double _gap(BuildContext context) {
  return MediaQuery.of(context).size.width < 360 ? 6 : 10;
}

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
  final TextEditingController _searchController = TextEditingController();
  String search = '';
  String selectedGroup = 'All';
  String selectedClass = 'All';
  String selectedSection = 'All';
  String facilityFilter = 'All';
  bool importing = false;

  // ── Undo-delete state ─────────────────────────────────────────────────────
  Map<String, dynamic>? _recentlyDeleted;
  String? _recentlyDeletedId;
  String? _recentlyDeletedSchoolId;
  bool _showUndo = false;

  // ── Cached StreamBuilder data (assigned each rebuild, read by view helpers) ──
  List<QueryDocumentSnapshot> _cDocs = [];
  List<QueryDocumentSnapshot> _cStudents = [];
  String _cSchoolId = '';
  List<String> _cFilteredClasses = [];
  List<String> _cFilteredSections = [];
  String _cGroupLabel = 'Group';
  String _cFilteredLabel = 'Filtered';
  int _cGroupCount = 0;

  final customInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.grey.shade400),
  );

  @override
  void dispose() {
    _searchController.dispose();
    _openStudentId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);
    return AdminLayout(
      title: 'Students',
      onSettingsPressed: () => _openSettings(context),
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

              final docs = snap.data?.docs ?? [];
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
                if (!_matchGroup(className, selectedGroup)) return false;
                if (selectedClass != 'All' && className != selectedClass) return false;
                if (selectedSection != 'All' && section != selectedSection) return false;
                if (!name.contains(search.toLowerCase())) return false;
                if (facilityFilter != 'All') {
                  final hostelV = (d['type'] ?? d['residence'] ?? '').toString().trim().toLowerCase();
                  final isHostel = hostelV == 'hostel' || hostelV == 'h';
                  final messV = (d['mess'] ?? '').toString().trim().toLowerCase();
                  final isMess = isHostel ? true : (messV == 'yes' || messV == 'y' || messV == '1' || messV == 'true');
                  final transV = (d['transport'] ?? '').toString().trim().toLowerCase();
                  final isBus = isHostel ? false : (transV == 'yes' || transV == 'y' || transV == '1' || transV == 'true');
                  switch (facilityFilter) {
                    case 'Hostel': if (!isHostel) return false;
                    case 'Day': if (isHostel) return false;
                    case 'Mess': if (!isMess) return false;
                    case 'Bus': if (!isBus) return false;
                  }
                }
                return true;
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

              final mobile = MediaQuery.of(context).size.width < 800;

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

              // ── cache for helper methods ──────────────────────────────
              _cDocs = docs;
              _cStudents = students;
              _cSchoolId = school.id;
              _cFilteredClasses = filteredClassList;
              _cFilteredSections = filteredSectionList;
              _cGroupLabel = groupLabel;
              _cFilteredLabel = filteredLabel;
              _cGroupCount = groupCount;

              final _mqSize = MediaQuery.of(context).size;
              final _orientation = MediaQuery.of(context).orientation;
              final isPhone = _mqSize.shortestSide < 600;
              final isLandscape = _orientation == Orientation.landscape;
              final isMobilePortrait = isPhone && !isLandscape;
              final isMobileLandscape = isPhone && isLandscape;
              debugPrint('shortestSide=${_mqSize.shortestSide} isPhone=$isPhone isLandscape=$isLandscape');
              if (isMobilePortrait) return _buildMobileView();
              if (isMobileLandscape) return _buildMobileLandscapeView();
              return _buildDesktopView();
            },
          );
        },
        loading: () => ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  // ── DESKTOP VIEW ────────────────────────────────────────────────────────────
  Widget _buildDesktopView() {
    final docs = _cDocs;
    final students = _cStudents;
    final groupLabel = _cGroupLabel;
    final filteredLabel = _cFilteredLabel;
    final groupCount = _cGroupCount;
    final filteredClassList = _cFilteredClasses;
    final filteredSectionList = _cFilteredSections;
    final schoolId = _cSchoolId;

    return Container(
      color: const Color(0xFFF5F7FB),
      child: Column(
        children: [
          _buildUndoBar(),
          _studentsHeroCard(students),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _dataCard(icon: Icons.group, label: 'Total', value: students.length.toString(), color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _dataCard(icon: Icons.school, label: groupLabel, value: selectedGroup == 'All' ? '-' : groupCount.toString(), color: Colors.purple)),
              const SizedBox(width: 16),
              Expanded(child: _dataCard(icon: Icons.filter_alt, label: filteredLabel, value: students.length.toString(), color: Colors.green, highlight: true)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _searchController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [UpperCaseTextFormatter()],
                  onChanged: (value) => setState(() => search = value),
                  style: const TextStyle(fontSize: 14, letterSpacing: 0.5),
                  decoration: InputDecoration(
                    hintText: 'SEARCH...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _actionBtn(Icons.download, 'Export', Colors.red, () => _showExportPopup(context, students.length, students)),
                        _actionBtn(Icons.upload_file, 'Import', Colors.blue, importing ? null : () => _importStudents(context, schoolId)),
                        _actionBtn(Icons.add, 'Add', Colors.green, () => context.push('/add-student')),
                        _actionBtn(Icons.photo_library, 'Upload', Colors.green, () => _uploadBulkPhotos(context, schoolId)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StudentsFiltersRow(
            selectedGroup: selectedGroup,
            selectedClass: selectedClass,
            selectedSection: selectedSection,
            facilityFilter: facilityFilter,
            classItems: ['All', ...filteredClassList],
            sectionItems: ['All', ...filteredSectionList],
            classEnabled: selectedGroup != 'All',
            sectionEnabled: selectedClass != 'All',
            onGroupChanged: (v) {
              if (v == null) return;
              setState(() {
                selectedGroup = v;
                selectedClass = 'All';
                selectedSection = 'All';
              });
            },
            onClassChanged: (v) {
              if (v == null) return;
              setState(() {
                selectedClass = v;
                selectedSection = 'All';
              });
            },
            onSectionChanged: (v) {
              if (v == null) return;
              setState(() => selectedSection = v);
            },
            onFacilityFilterChanged: (v) {
              if (v == null) return;
              setState(() => facilityFilter = v);
            },
            onClearFilters: () {
              setState(() {
                selectedGroup = 'All';
                selectedClass = 'All';
                selectedSection = 'All';
                facilityFilter = 'All';
                search = '';
                _searchController.clear();
              });
            },
          ),
          const SizedBox(height: 20),
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
                        final messVal = (d['mess'] ?? '').toString().trim().toLowerCase();
                        final hostelVal = (d['type'] ?? d['residence'] ?? '').toString().trim().toLowerCase();
                        final isHostel = hostelVal == 'hostel' || hostelVal == 'h';
                        final transVal = (d['transport'] ?? '').toString().trim().toLowerCase();
                        final isMess = isHostel ? true : (messVal == 'yes' || messVal == 'y' || messVal == '1' || messVal == 'true');
                        final isBus = isHostel ? false : (transVal == 'yes' || transVal == 'y' || transVal == '1' || transVal == 'true');

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
                                          SizedBox(
                                            width: 30,
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: (d['photoUrl'] != null && d['photoUrl'] != '')
                                                ? CachedNetworkImage(
                                                    imageUrl: d['photoUrl'],
                                                    cacheKey: d['photoUrl'],
                                                    imageBuilder: (context, imageProvider) => Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                                      ),
                                                    ),
                                                    placeholder: (context, url) => Container(
                                                      decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                                                      child: const Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))),
                                                    ),
                                                    errorWidget: (context, url, error) => Container(
                                                      decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                                                      child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w500))),
                                                    ),
                                                  )
                                                : Container(
                                                    decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                                                    child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w500))),
                                                  ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name, style: isOpen ? _titleStyle.copyWith(fontWeight: FontWeight.w600) : _titleStyle),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(6)),
                                                      child: Text(
                                                        section.isNotEmpty ? '$className $section' : className,
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.w500),
                                                      ),
                                                    ),
                                                    if (isMess) ...[const SizedBox(width: 4), _miniIcon(Icons.restaurant)],
                                                    if (isHostel) ...[const SizedBox(width: 4), _miniIcon(Icons.bed)],
                                                    if (isBus) ...[const SizedBox(width: 4), _miniIcon(Icons.directions_bus)],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(isOpen ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (isOpen)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 40, bottom: 6),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.person_outline, size: 18, color: Color(0xFF4F46E5)),
                                          tooltip: 'View Profile',
                                          onPressed: () {
                                            context.push('/student-profile', extra: {'studentId': doc.id, 'schoolId': schoolId});
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                          onPressed: () {
                                            context.push('/edit-student', extra: {'studentId': doc.id, 'data': d});
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          onPressed: () async => await _deleteStudent(context, schoolId, doc.id, name),
                                        ),
                                      ],
                                    ),
                                  ),
                                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                              ],
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MOBILE LANDSCAPE VIEW ───────────────────────────────────────────────────
  Widget _buildMobileLandscapeView() {
    final students = _cStudents;
    final schoolId = _cSchoolId;
    final filteredClassList = _cFilteredClasses;
    final filteredSectionList = _cFilteredSections;

    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFF5F7FB),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (mini cards in 6-col grid via internal landscape logic) ──
              _buildUndoBar(),
              _mobileHeader(),
              const SizedBox(height: 10),

              // ── Stat cards in a single row ─────────────────────────────────────
              _mobileStats(),
              const SizedBox(height: 10),

              // ── Search + action buttons ────────────────────────────────────────
              _mobileSearch(),
              const SizedBox(height: 10),

              // ── Filters (4 in a row via internal landscape logic) ──────────────
              _mobileFilters(),
              const SizedBox(height: 12),

              // ── Student list (shrinkWrap inside scroll) ────────────────────────
              if (students.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No students found',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, i) => _mobileStudentTile(i, students[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TABLET VIEW ─────────────────────────────────────────────────────────────
  Widget _buildTabletView() {
    final docs = _cDocs;
    final students = _cStudents;
    final groupLabel = _cGroupLabel;
    final filteredLabel = _cFilteredLabel;
    final groupCount = _cGroupCount;
    final filteredClassList = _cFilteredClasses;
    final filteredSectionList = _cFilteredSections;
    final schoolId = _cSchoolId;

    return Container(
      color: const Color(0xFFF5F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ──────────────────────────────────────────────────
            _buildUndoBar(),
            _studentsHeroCard(students),
            const SizedBox(height: 16),

            // ── Stat cards ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _dataCard(icon: Icons.group, label: 'Total', value: students.length.toString(), color: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _dataCard(icon: Icons.school, label: groupLabel, value: selectedGroup == 'All' ? '-' : groupCount.toString(), color: Colors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _dataCard(icon: Icons.filter_alt, label: filteredLabel, value: students.length.toString(), color: Colors.green, highlight: true)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Search + action buttons ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      final upper = value.toUpperCase();
                      if (value != upper) {
                        _searchController.value = TextEditingValue(
                          text: upper,
                          selection: TextSelection.collapsed(offset: upper.length),
                        );
                      }
                      setState(() => search = upper);
                    },
                    style: const TextStyle(fontSize: 14, letterSpacing: 0.5),
                    decoration: InputDecoration(
                      hintText: 'SEARCH...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _actionBtn(Icons.download, 'Export', Colors.red, () => _showExportPopup(context, students.length, students)),
                      _actionBtn(Icons.upload_file, 'Import', Colors.blue, importing ? null : () => _importStudents(context, schoolId)),
                      _actionBtn(Icons.add, 'Add', Colors.green, () => context.push('/add-student')),
                      _actionBtn(Icons.photo_library, 'Upload', Colors.green, () => _uploadBulkPhotos(context, schoolId)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Filters ───────────────────────────────────────────────────
            _StudentsFiltersRow(
              selectedGroup: selectedGroup,
              selectedClass: selectedClass,
              selectedSection: selectedSection,
              facilityFilter: facilityFilter,
              classItems: ['All', ...filteredClassList],
              sectionItems: ['All', ...filteredSectionList],
              classEnabled: selectedGroup != 'All',
              sectionEnabled: selectedClass != 'All',
              onGroupChanged: (v) {
                if (v == null) return;
                setState(() {
                  selectedGroup = v;
                  selectedClass = 'All';
                  selectedSection = 'All';
                });
              },
              onClassChanged: (v) {
                if (v == null) return;
                setState(() {
                  selectedClass = v;
                  selectedSection = 'All';
                });
              },
              onSectionChanged: (v) {
                if (v == null) return;
                setState(() => selectedSection = v);
              },
              onFacilityFilterChanged: (v) {
                if (v == null) return;
                setState(() => facilityFilter = v);
              },
              onClearFilters: () {
                setState(() {
                  selectedGroup = 'All';
                  selectedClass = 'All';
                  selectedSection = 'All';
                  facilityFilter = 'All';
                  search = '';
                  _searchController.clear();
                });
              },
            ),
            const SizedBox(height: 16),

            // ── Student list ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: students.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No students found',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: students.length,
                      itemBuilder: (context, i) => _mobileStudentTile(i, students[i]),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── MOBILE VIEW ─────────────────────────────────────────────────────────────
  Widget _buildMobileView() {
    final students = _cStudents;
    return SafeArea(
      top: false,
      child: Container(
      color: const Color(0xFFF5F7FB),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          _buildUndoBar(),
          _mobileHeader(),
          const SizedBox(height: 12),
          _mobileStats(),
          const SizedBox(height: 12),
          _mobileSearch(),
          const SizedBox(height: 12),
          _mobileFilters(),
          const SizedBox(height: 12),
          if (students.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No students found', style: TextStyle(color: Color(0xFF6B7280))),
              ),
            )
          else
            ...List.generate(students.length, (i) => _mobileStudentTile(i, students[i])),
          const SizedBox(height: 24),
        ],
      ),
      ),
    );
  }

  Widget _mobileHeader() {
    final docs = _cStudents;
    final hostel = docs.where((e) {
      final v = ((e.data() as Map<String, dynamic>)['type'] ?? (e.data() as Map<String, dynamic>)['residence'] ?? '').toString().trim().toLowerCase();
      return v == 'hostel' || v == 'h';
    }).length;
    final day = docs.where((e) {
      final v = ((e.data() as Map<String, dynamic>)['type'] ?? (e.data() as Map<String, dynamic>)['residence'] ?? '').toString().trim().toLowerCase();
      return v == 'day' || v == 'd' || v == 'day scholar' || v == 'dayscholar';
    }).length;
    final girls = docs.where((e) {
      final g = ((e.data() as Map<String, dynamic>)['gender'] ?? '').toString().trim().toLowerCase();
      return g == 'female' || g == 'f';
    }).length;
    final boys = docs.where((e) {
      final g = ((e.data() as Map<String, dynamic>)['gender'] ?? '').toString().trim().toLowerCase();
      return g == 'male' || g == 'm';
    }).length;
    final mess = docs.where((e) {
      final d = e.data() as Map<String, dynamic>;
      final hv = (d['type'] ?? d['residence'] ?? '').toString().trim().toLowerCase();
      if (hv == 'hostel' || hv == 'h') return true;
      final v = (d['mess'] ?? '').toString().trim().toLowerCase();
      return v == 'yes' || v == 'y' || v == '1' || v == 'true';
    }).length;
    final bus = docs.where((e) {
      final d = e.data() as Map<String, dynamic>;
      final hv = (d['type'] ?? d['residence'] ?? '').toString().trim().toLowerCase();
      if (hv == 'hostel' || hv == 'h') return false;
      final v = (d['transport'] ?? '').toString().trim().toLowerCase();
      return v == 'yes' || v == 'y' || v == '1' || v == 'true';
    }).length;

    final cards = [
      _topMiniCard(context, Icons.hotel, hostel, Colors.purple),
      _topMiniCard(context, Icons.home, day, Colors.blue),
      _topMiniCard(context, Icons.girl, girls, Colors.pink),
      _topMiniCard(context, Icons.boy, boys, Colors.cyan),
      _topMiniCard(context, Icons.restaurant, mess, Colors.green),
      _topMiniCard(context, Icons.directions_bus, bus, Colors.orange),
    ];

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Students Dashboard',
          style: TextStyle(fontSize: _fs(context, 18), fontWeight: FontWeight.bold),
        ),
        SizedBox(height: _gap(context)),
        isLandscape
            ? GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.6,
                children: cards,
              )
            : ScreenType.isSmall(context)
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: cards),
                  )
                : SizedBox(
                    height: 70,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: cards,
                    ),
                  ),
      ],
    );
  }

  Widget _topMiniCard(BuildContext context, IconData icon, int value, Color color) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: _fs(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileStats() {
    return SizedBox(
      height: 88,
      child: Row(
        children: [
          Expanded(child: _statCard(icon: Icons.people_outline, title: 'Total', value: _cStudents.length.toString(), color: Colors.blue.shade50)),
          const SizedBox(width: 12),
          Expanded(child: _statCard(icon: Icons.category_outlined, title: shortGroup(_cGroupLabel, true), value: selectedGroup == 'All' ? '0' : _cGroupCount.toString(), color: Colors.purple.shade50)),
          const SizedBox(width: 12),
          Expanded(child: _statCard(icon: Icons.filter_list, title: 'Filter', value: _cStudents.length.toString(), color: Colors.green.shade100)),
        ],
      ),
    );
  }

  Widget _statCard({required IconData icon, required String title, required String value, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value == '-' ? '0' : value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileSearch() {
    final searchBar = SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: const [UpperCaseTextFormatter()],
        onChanged: (v) => setState(() => search = v),
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
    final buttons = [
      _mobileActionBtn(Icons.download, 'Export', Colors.red, onTap: () => _showExportPopup(context, _cStudents.length, _cStudents)),
      _mobileActionBtn(Icons.upload_file, 'Import', Colors.blue, onTap: importing ? null : () => _importStudents(context, _cSchoolId)),
      _mobileActionBtn(Icons.add, 'Add', Colors.green, onTap: () => context.push('/add-student')),
      _mobileActionBtn(Icons.photo_library, 'Upload', Colors.teal, onTap: () => _uploadBulkPhotos(context, _cSchoolId)),
      _mobileActionBtn(Icons.clear, 'Clear', Colors.orange, onTap: () => setState(() {
        selectedGroup = 'All';
        selectedClass = 'All';
        selectedSection = 'All';
        facilityFilter = 'All';
        search = '';
        _searchController.clear();
      })),
    ];

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      return Row(
        children: [
          Expanded(flex: 2, child: searchBar),
          const SizedBox(width: 8),
          ...buttons.map((b) => Expanded(child: b)).toList(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        searchBar,
        const SizedBox(height: 8),
        Row(
          children: buttons.map((b) => Expanded(child: b)).toList(),
        ),
      ],
    );
  }

  Widget _mobileActionBtn(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: enabled ? color.withOpacity(0.12) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: enabled ? color.withOpacity(0.4) : Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: enabled ? color : Colors.grey.shade400),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: enabled ? color : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? Colors.grey.shade400 : (color ?? Colors.black54),
        ),
      ),
    );
  }

  Widget _mobileFilters() {
    Widget dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, {bool enabled = true}) {
      return SizedBox(
        height: 40,
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: _fs(context, 11)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: _fs(context, 11)), overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      );
    }

    final dropdowns = [
      dropdown('Group', selectedGroup, const ['All', 'Nursery', 'Primary School', 'Middle School', 'High School', 'College'], (v) {
        if (v == null) return;
        setState(() { selectedGroup = v; selectedClass = 'All'; selectedSection = 'All'; });
      }),
      dropdown('Class', selectedClass, ['All', ..._cFilteredClasses], (v) {
        if (v == null) return;
        setState(() { selectedClass = v; selectedSection = 'All'; });
      }, enabled: selectedGroup != 'All'),
      dropdown('Section', selectedSection, ['All', ..._cFilteredSections], (v) {
        if (v == null) return;
        setState(() => selectedSection = v);
      }, enabled: selectedClass != 'All'),
      dropdown('Facility', facilityFilter, const ['All', 'Hostel', 'Day', 'Mess', 'Bus'], (v) {
        if (v == null) return;
        setState(() => facilityFilter = v);
      }),
    ];

    final w = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return Row(
        children: [
          Expanded(child: dropdowns[0]),
          const SizedBox(width: 6),
          Expanded(child: dropdowns[1]),
          const SizedBox(width: 6),
          Expanded(child: dropdowns[2]),
          const SizedBox(width: 6),
          Expanded(child: dropdowns[3]),
        ],
      );
    }

    if (w < 360) {
      // Small: vertical stack
      return Column(
        children: [
          for (int i = 0; i < dropdowns.length; i++) ...
            [dropdowns[i], if (i < dropdowns.length - 1) const SizedBox(height: 6)],
        ],
      );
    } else if (w < 600) {
      // Mobile: 2×2 grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: dropdowns[0]),
              const SizedBox(width: 6),
              Expanded(child: dropdowns[1]),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: dropdowns[2]),
              const SizedBox(width: 6),
              Expanded(child: dropdowns[3]),
            ],
          ),
        ],
      );
    } else {
      // Tablet: 4 in a row
      return Row(
        children: [
          Expanded(child: dropdowns[0]),
          const SizedBox(width: 6),
          Expanded(child: dropdowns[1]),
          const SizedBox(width: 6),
          Expanded(child: dropdowns[2]),
          const SizedBox(width: 6),
          Expanded(child: dropdowns[3]),
        ],
      );
    }
  }

  Widget _mobileStudentTile(int i, QueryDocumentSnapshot doc) {
    final schoolId = _cSchoolId;
    final d = doc.data() as Map<String, dynamic>;
    final name = (d['name'] ?? '').toString();
    final className = (d['className'] ?? '').toString();
    final section = (d['section'] ?? '').toString();
    final hostelVal = (d['type'] ?? d['residence'] ?? '').toString().trim().toLowerCase();
    final isHostel = hostelVal == 'hostel' || hostelVal == 'h';
    final messVal = (d['mess'] ?? '').toString().trim().toLowerCase();
    final transVal = (d['transport'] ?? '').toString().trim().toLowerCase();
    final isMess = isHostel ? true : (messVal == 'yes' || messVal == 'y' || messVal == '1' || messVal == 'true');
    final isBus = isHostel ? false : (transVal == 'yes' || transVal == 'y' || transVal == '1' || transVal == 'true');
    final photoUrl = (d['photoUrl'] ?? '').toString();

    return Dismissible(
      key: ValueKey(doc.id),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      movementDuration: const Duration(milliseconds: 250),
      resizeDuration: const Duration(milliseconds: 200),
      background: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Opacity(
              opacity: value,
              child: const Icon(Icons.edit, color: Colors.white, size: 22),
            ),
          );
        },
      ),
      secondaryBackground: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Opacity(
              opacity: value,
              child: const Icon(Icons.delete, color: Colors.white, size: 22),
            ),
          );
        },
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        if (direction == DismissDirection.startToEnd) {
          context.push('/edit-student', extra: {'studentId': doc.id, 'data': d});
          return false;
        }
        // Soft-delete: moves to deleted_students, Dismissible animates the tile out
        await _softDeleteStudent(schoolId, doc.id, d);
        return true;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
              ),
            ],
          ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      cacheKey: photoUrl,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                        ),
                      ),
                      placeholder: (context, url) => Container(
                        decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                        child: const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
                      ),
                      errorWidget: (context, url, error) => _mobileAvatarFallback(name),
                    )
                  : _mobileAvatarFallback(name),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          section.isNotEmpty ? '$className $section' : className,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (isMess) ...[const SizedBox(width: 4), _miniIcon(Icons.restaurant)],
                      if (isHostel) ...[const SizedBox(width: 4), _miniIcon(Icons.bed)],
                      if (isBus) ...[const SizedBox(width: 4), _miniIcon(Icons.directions_bus)],
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/student-profile', extra: {'studentId': doc.id, 'schoolId': schoolId}),
              child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _mobileAvatarFallback(String name) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 16),
        ),
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

  static const _exportFields = [
    'SL NO',
    'Name',
    'Class',
    'Section',
    'Hostel/Day',
    'D.O.B',
    'Blood Group',
    'Mess',
    'Transport',
    'Gender',
    'Parent Name',
    'Parent Phone',
    'Address',
    'Academic Year',
    'Admission No',
  ];

  String _buildExportFileName() {
    // Only group selected — use group name alone
    if (selectedClass == 'All' &&
        selectedSection == 'All' &&
        facilityFilter == 'All') {
      if (selectedGroup != 'All') {
        return selectedGroup.replaceAll(' ', '');
      }
      return 'Students';
    }

    final parts = <String>[];
    if (selectedClass != 'All') parts.add('Class$selectedClass');
    if (selectedSection != 'All') parts.add(selectedSection);
    if (facilityFilter != 'All') parts.add(facilityFilter.replaceAll(' ', ''));
    if (parts.isEmpty) return 'Students';
    return parts.join('_');
  }

  Future<void> _showExportPopup(
    BuildContext context,
    int count,
    List<QueryDocumentSnapshot> students,
  ) async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.download_rounded, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    'Export Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _exportCard(
                icon: Icons.grid_on,
                title: 'Export',
                subtitle: 'All fields — filtered students',
                color: Colors.green,
                onTap: () async {
                  Navigator.pop(context);
                  await _exportDataWithFields(
                      context, students, _exportFields);
                },
              ),
              const SizedBox(height: 12),
              _exportCard(
                icon: Icons.tune,
                title: 'Custom Export',
                subtitle: 'Choose which fields to include',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _showCustomExportDialog(context, students);
                },
              ),
              const SizedBox(height: 12),
              _exportCard(
                icon: Icons.picture_as_pdf,
                title: 'Export PDF',
                subtitle: 'Printable student report',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _exportToPdf(context, students);
                },
              ),
              const SizedBox(height: 12),
              _exportCard(
                icon: Icons.description,
                title: 'Import Template',
                subtitle: 'Download blank format',
                color: Colors.blueGrey,
                onTap: () async {
                  Navigator.pop(context);
                  await StudentTemplateService.exportBlankTemplate();
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomExportDialog(
    BuildContext context,
    List<QueryDocumentSnapshot> students,
  ) {
    final selected = List<String>.from(_exportFields);
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Custom Export',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 340,
                  child: ListView(
                    children: _exportFields.map((field) {
                      return CheckboxListTile(
                        dense: true,
                        value: selected.contains(field),
                        title: Text(field),
                        onChanged: (v) {
                          setDlgState(() {
                            if (v == true) {
                              selected.add(field);
                            } else {
                              selected.remove(field);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _exportDataWithFields(
                                  context, students, selected);
                            },
                      child: const Text('Export'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportDataWithFields(
    BuildContext context,
    List<QueryDocumentSnapshot> students,
    List<String> fields,
  ) async {
    final rows = <List<dynamic>>[];
    for (int i = 0; i < students.length; i++) {
      final d = students[i].data() as Map<String, dynamic>;
      final hostelV =
          (d['type'] ?? d['residence'] ?? '').toString().trim().toLowerCase();
      final isHostel = hostelV == 'hostel' || hostelV == 'h';
      final messV = (d['mess'] ?? '').toString().trim().toLowerCase();
      final isMess = isHostel
          ? true
          : (messV == 'yes' || messV == 'y' || messV == '1' || messV == 'true');
      final transV = (d['transport'] ?? '').toString().trim().toLowerCase();
      final isBus = isHostel
          ? false
          : (transV == 'yes' ||
              transV == 'y' ||
              transV == '1' ||
              transV == 'true');

      final row = <dynamic>[];
      for (final field in fields) {
        switch (field) {
          case 'SL NO':
            row.add(i + 1);
          case 'Name':
            row.add(d['name'] ?? '');
          case 'Class':
            row.add(d['className'] ?? '');
          case 'Section':
            row.add(d['section'] ?? '');
          case 'Hostel/Day':
            row.add(isHostel ? 'Hostel' : 'Day');
          case 'D.O.B':
            final dob = d['dob'];
            if (dob == null) {
              row.add('');
            } else {
              try {
                final parsed = DateTime.parse(dob.toString());
                row.add('${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}');
              } catch (_) {
                row.add(dob.toString());
              }
            }
          case 'Blood Group':
            row.add(d['bloodGroup'] ?? '');
          case 'Mess':
            row.add(isMess ? 'Yes' : 'No');
          case 'Transport':
            row.add(isBus ? 'Yes' : 'No');
          case 'Gender':
            row.add(d['gender'] ?? '');
          case 'Parent Name':
            row.add(d['parentName'] ?? '');
          case 'Parent Phone':
            row.add(d['parentPhone'] ?? '');
          case 'Address':
            row.add(d['address'] ?? '');
          case 'Academic Year':
            row.add(d['academicYear'] ?? d['year'] ?? '');
          case 'Admission No':
            row.add(d['admissionNo'] ?? '');
          default:
            row.add('');
        }
      }
      rows.add(row);
    }

    // Build title for the Excel header row
    final String excelAcYear = students.isNotEmpty
        ? ((students.first.data()
                    as Map<String, dynamic>)['academicYear'] ??
                (students.first.data()
                    as Map<String, dynamic>)['year'] ??
                '')
            .toString()
        : '';
    final String excelTitle = _buildHeaderTitle(excelAcYear);

    await StudentTemplateService.exportCustomExcel(
      headers: fields,
      rows: rows,
      fileName: _buildExportFileName(),
      title: excelTitle,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Exported ${students.length} students')),
      );
    }
  }

  String _buildHeaderTitle(String acYear) {
    String base;
    if (selectedClass != 'All') {
      base = selectedSection != 'All'
          ? 'Class $selectedClass $selectedSection'
          : 'Class $selectedClass';
    } else if (selectedGroup != 'All') {
      base = selectedGroup;
    } else {
      base = '';
    }
    final parts = [
      if (base.isNotEmpty) base,
      if (acYear.isNotEmpty) acYear,
      if (facilityFilter != 'All') facilityFilter,
    ];
    return parts.join('  |  ');
  }

  Widget _exportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPdf(
    BuildContext context,
    List<QueryDocumentSnapshot> students,
  ) async {
    final fileName = _buildExportFileName();
    final fields = List<String>.from(_exportFields);

    // Build data rows (same logic as Excel export)
    final dataRows = <List<String>>[];
    for (int i = 0; i < students.length; i++) {
      final d = students[i].data() as Map<String, dynamic>;
      final hostelV =
          (d['type'] ?? d['residence'] ?? '').toString().trim().toLowerCase();
      final isHostel = hostelV == 'hostel' || hostelV == 'h';
      final messV = (d['mess'] ?? '').toString().trim().toLowerCase();
      final isMess = isHostel
          ? true
          : (messV == 'yes' || messV == 'y' || messV == '1' || messV == 'true');
      final transV = (d['transport'] ?? '').toString().trim().toLowerCase();
      final isBus = isHostel
          ? false
          : (transV == 'yes' ||
              transV == 'y' ||
              transV == '1' ||
              transV == 'true');

      final row = <String>[];
      for (final field in fields) {
        switch (field) {
          case 'SL NO':
            row.add('${i + 1}');
          case 'Name':
            row.add((d['name'] ?? '').toString());
          case 'Class':
            row.add((d['className'] ?? '').toString());
          case 'Section':
            row.add((d['section'] ?? '').toString());
          case 'Hostel/Day':
            row.add(isHostel ? 'Hostel' : 'Day');
          case 'D.O.B':
            final dob = d['dob'];
            if (dob == null) {
              row.add('');
            } else {
              try {
                final parsed = DateTime.parse(dob.toString());
                row.add('${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}');
              } catch (_) {
                row.add(dob.toString());
              }
            }
          case 'Blood Group':
            row.add((d['bloodGroup'] ?? '').toString());
          case 'Mess':
            row.add(isMess ? 'Yes' : 'No');
          case 'Transport':
            row.add(isBus ? 'Yes' : 'No');
          case 'Gender':
            row.add((d['gender'] ?? '').toString());
          case 'Parent Name':
            row.add((d['parentName'] ?? '').toString());
          case 'Parent Phone':
            row.add((d['parentPhone'] ?? '').toString());
          case 'Address':
            row.add((d['address'] ?? '').toString());
          case 'Academic Year':
            row.add((d['academicYear'] ?? d['year'] ?? '').toString());
          case 'Admission No':
            row.add((d['admissionNo'] ?? '').toString());
          default:
            row.add('');
        }
      }
      dataRows.add(row);
    }

    // Derive header title and academic year
    final String pdfAcYear = students.isNotEmpty
        ? ((students.first.data() as Map<String, dynamic>)['academicYear'] ??
                (students.first.data()
                    as Map<String, dynamic>)['year'] ??
                '')
            .toString()
        : '';
    final String pdfHeaderLine = _buildHeaderTitle(pdfAcYear);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (pdfHeaderLine.isNotEmpty)
              pw.Text(
                pdfHeaderLine,
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 2),
          ],
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headers: fields,
            data: dataRows,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: pw.TextStyle(fontSize: 8),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4, vertical: 3),
            columnWidths: {
              0: const pw.FixedColumnWidth(25),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FixedColumnWidth(30),
              3: const pw.FixedColumnWidth(35),
              4: const pw.FixedColumnWidth(50),
              5: const pw.FixedColumnWidth(55),
              6: const pw.FixedColumnWidth(55),
              7: const pw.FixedColumnWidth(35),
              8: const pw.FixedColumnWidth(50),
              9: const pw.FixedColumnWidth(35),
              10: const pw.FlexColumnWidth(2),
              11: const pw.FixedColumnWidth(65),
              12: const pw.FlexColumnWidth(2),
              13: const pw.FixedColumnWidth(50),
              14: const pw.FixedColumnWidth(65),
            },
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await savePdfFile(bytes, '$fileName.pdf');
  }

  Future<void> _uploadBulkPhotos(BuildContext context, String schoolId) async {
    final files = await StudentImportService.pickMultipleImages();
    if (files.isEmpty) return;
    if (!mounted) return;

    // Compress all files up-front so we know exact byte sizes
    final List<_CompressedImage> compressed = [];
    for (final f in files) {
      final admissionNo = f.name.replaceAll(RegExp(r'\.[^/.]+$'), '');
      final bytes = f.bytes;
      if (bytes == null) continue;
      final c = await ImageUploadService.compress(bytes);
      compressed.add(_CompressedImage(admissionNo: admissionNo, bytes: c));
    }

    final int totalBytes =
        compressed.fold(0, (sum, e) => sum + e.bytes.length);

    // Per-file bytesTransferred — correct global progress without double-counting
    final Map<String, int> fileProgress = {
      for (final e in compressed) e.admissionNo: 0
    };

    int completed = 0;
    final int total = compressed.length;
    StateSetter dialogSetState = (_) {};

    double overallProgress() {
      if (totalBytes == 0) return 0;
      final uploaded = fileProgress.values.fold(0, (a, b) => a + b);
      return uploaded / totalBytes;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          dialogSetState = setDialogState;
          final progress = overallProgress();
          final allDone = completed == total;
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Uploading Photos',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 300),
                    builder: (_, value, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                          ),
                        ),
                        Text(
                          '${(value * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('$completed / $total done'),
                  const SizedBox(height: 10),
                  Text(
                    allDone ? 'Completed' : 'Uploading...',
                    style: TextStyle(
                      color: allDone ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    int doneCount = 0;
    int failedCount = 0;

    await Future.wait(compressed.map((entry) async {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .where('admissionNo', isEqualTo: entry.admissionNo)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          // Not matched — count its bytes as done so the bar stays accurate
          fileProgress[entry.admissionNo] = entry.bytes.length;
          failedCount++;
          completed++;
          if (mounted) dialogSetState(() {});
          return;
        }

        final docRef = snapshot.docs.first.reference;
        final oldUrl = (snapshot.docs.first.data())['photoUrl'] as String?;
        if (oldUrl != null && oldUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(oldUrl).delete();
          } catch (_) {}
        }

        final url = await ImageUploadService.upload(
          bytes: entry.bytes,
          storagePath: 'schools/$schoolId/photos/${entry.admissionNo}.jpg',
          onProgress: (p) {
            fileProgress[entry.admissionNo] =
                (p * entry.bytes.length).toInt();
            if (mounted) dialogSetState(() {});
          },
        );
        // Pin to full size in case the last event hasn't fired yet
        fileProgress[entry.admissionNo] = entry.bytes.length;

        await docRef.update({'photoUrl': url});
        doneCount++;
      } catch (e) {
        debugPrint('Bulk photo upload error [${entry.admissionNo}]: $e');
        fileProgress[entry.admissionNo] = entry.bytes.length;
        failedCount++;
      }
      completed++;
      if (mounted) dialogSetState(() {});
    }));

    if (mounted && failedCount == 0) Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Uploaded $doneCount photo${doneCount == 1 ? '' : 's'}'
            '${failedCount > 0 ? ' — $failedCount not matched/failed' : ''}',
          ),
        ),
      );
    }
  }

  Future<void> _uploadStudentPhoto(
    BuildContext context,
    String schoolId,
    String studentId,
    String admissionNo,
    String? oldUrl,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      if (oldUrl != null && oldUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(oldUrl).delete();
        } catch (_) {}
      }

      final fileBytes = file.bytes;
      if (fileBytes == null) return;
      final compressed = await ImageUploadService.compress(fileBytes);
      final url = await ImageUploadService.upload(
        bytes: compressed,
        storagePath: 'schools/$schoolId/photos/$admissionNo.jpg',
      );
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(studentId)
          .update({'photoUrl': url});

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Photo updated')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  // ── Settings dialog ───────────────────────────────────────────────
  void _openSettings(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > 600) {
      // Web / Tablet → Dialog
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 400,
            child: _settingsContent(context),
          ),
        ),
      );
    } else {
      // Mobile → Bottom Sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: _settingsContent(context),
        ),
      );
    }
  }

  Widget _settingsContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _settingsCard(
            icon: Icons.restore,
            title: 'Restore Students',
            subtitle: 'Recover deleted students',
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              context.push('/restore-students',
                  extra: {'schoolId': _cSchoolId});
            },
          ),
          const SizedBox(height: 10),
          _settingsCard(
            icon: Icons.cleaning_services,
            title: 'Fix Data',
            subtitle: 'Auto-correct hostel/mess/bus',
            color: Colors.purple,
            onTap: () async {
              Navigator.pop(context);
              await _fixHostelData(context);
            },
          ),
          const SizedBox(height: 10),
          _settingsCard(
            icon: Icons.photo_library,
            title: 'Rename Photos',
            subtitle: 'Bulk rename student photos',
            color: Colors.teal,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RenamePhotosScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _fixHostelData(BuildContext context) async {
    final school = await ref.read(currentSchoolProvider.future);
    final count = await StudentService().migrateOldStudentData(schoolId: school.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Done! Fixed $count legacy records.')),
    );
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

      // Enforce hostel business rule before saving
      final typeVal = (row['type'] ?? '').toString().trim().toLowerCase();
      if (typeVal == 'hostel' || typeVal == 'h') {
        row['mess'] = 'yes';
        row['transport'] = 'no';
      }

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

  // ── Soft-delete: moves student to deleted_students collection ─────────
  Future<void> _softDeleteStudent(
    String schoolId,
    String studentId,
    Map<String, dynamic> data,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final payload = Map<String, dynamic>.from(data)
      ..['deletedAt'] = FieldValue.serverTimestamp();

    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('deleted_students')
        .doc(studentId)
        .set(payload);

    await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(studentId)
        .delete();
  }

  // ── Undo delete: called after swipe or delete action ────────────────────
  void _handleDeleteWithUndo(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    final studentId = doc.id;
    final schoolId = _cSchoolId;
    final name = (data['name'] ?? 'Student').toString();

    // Show undo bar immediately (optimistic)
    setState(() {
      _recentlyDeleted = data;
      _recentlyDeletedId = studentId;
      _recentlyDeletedSchoolId = schoolId;
      _showUndo = true;
    });

    // Delete photo from Storage first if present
    try {
      final photoUrl = data['photoUrl'] as String?;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(photoUrl).delete();
      }
    } catch (_) {}

    // Delete from Firestore — StreamBuilder removes tile automatically
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(studentId)
        .delete();

    // Auto-clear undo bar after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showUndo = false;
          _recentlyDeleted = null;
          _recentlyDeletedId = null;
          _recentlyDeletedSchoolId = null;
        });
      }
    });
  }

  Future<void> _undoDelete() async {
    if (_recentlyDeleted == null || _recentlyDeletedId == null) return;
    final schoolId = _recentlyDeletedSchoolId ?? _cSchoolId;
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(_recentlyDeletedId)
        .set(_recentlyDeleted!);
    if (mounted) {
      setState(() {
        _showUndo = false;
        _recentlyDeleted = null;
        _recentlyDeletedId = null;
        _recentlyDeletedSchoolId = null;
      });
    }
  }

  Widget _buildUndoBar() {
    if (!_showUndo) return const SizedBox.shrink();
    final name = (_recentlyDeleted?['name'] ?? 'Student').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$name deleted',
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _undoDelete,
            child: const Text('UNDO', style: TextStyle(color: Colors.blue)),
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
    final ref = FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(studentId);

    // Delete photo from Storage if exists
    try {
      final snap = await ref.get();
      final photoUrl = snap.data()?['photoUrl'] as String?;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(photoUrl).delete();
      }
    } catch (_) {}

    await ref.delete();
    return true;
  }

  return false;
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

  Widget _dataCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool highlight = false,
  }) {
    return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: highlight
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.9),
                    color.withValues(alpha: 0.7),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight
                ? color.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: highlight
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: highlight ? Colors.white : color,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: highlight ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: highlight ? Colors.white : const Color(0xFF374151),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const Spacer(),
            if (!highlight && label == 'Total')
              Icon(Icons.show_chart, color: Colors.blue.shade300),
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

  Widget _actionBtn(IconData icon, String label, Color hoverColor, VoidCallback? onTap) {
    bool isHover = false;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: StatefulBuilder(
        builder: (context, setLocalState) {
          return MouseRegion(
            onEnter: (_) => setLocalState(() => isHover = true),
            onExit: (_) => setLocalState(() => isHover = false),
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: onTap == null
                      ? const Color(0xFFE5E7EB)
                      : isHover
                          ? hoverColor.withValues(alpha: 0.12)
                          : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF9CA3AF), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 17,
                      color: onTap == null
                          ? Colors.grey.shade400
                          : isHover
                              ? hoverColor
                              : const Color(0xFF374151),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: onTap == null
                            ? Colors.grey.shade400
                            : isHover
                                ? hoverColor
                                : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _mobileBtnTile(String text, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _miniIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 12,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide(color: Color(0xFF2563EB)),
          ),
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
      width: 130,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF374151)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
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
    final hostelV = (d['type'] ?? d['residence'] ?? '').toString().trim().toLowerCase();
    final isHostel = hostelV == 'hostel' || hostelV == 'h';
    if (isHostel) return true; // hostel students always have mess
    final v = (d['mess'] ?? '').toString().trim().toLowerCase();
    return v == 'yes' || v == 'y' || v == '1' || v == 'true';
  }).length;

  final transportYes = docs.where((e) {
    final d = e.data() as Map<String, dynamic>;
    final hostelV = (d['type'] ?? d['residence'] ?? '').toString().trim().toLowerCase();
    final isHostel = hostelV == 'hostel' || hostelV == 'h';
    if (isHostel) return false; // hostel students never use bus
    final v = (d['transport'] ?? '').toString().trim().toLowerCase();
    return v == 'yes' || v == 'y' || v == '1' || v == 'true';
  }).length;


  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
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
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _topChip(Icons.bed, 'Hostel', hostel, const Color(0xFF4F46E5)),
                _topChip(Icons.home, 'Day', dayScholar, const Color(0xFF2563EB)),
                _topChip(Icons.woman, 'Girls', girls, const Color(0xFFEC4899)),
                _topChip(Icons.man, 'Boys', boys, const Color(0xFF06B6D4)),
                _topChip(Icons.restaurant, 'Mess', messYes, const Color(0xFF059669)),
                _topChip(Icons.directions_bus, 'Bus', transportYes, const Color(0xFFF59E0B)),
              ],
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

class _StudentsFiltersRow extends StatelessWidget {
  final String selectedGroup;
  final String selectedClass;
  final String selectedSection;
  final String facilityFilter;
  final List<String> classItems;
  final List<String> sectionItems;
  final bool classEnabled;
  final bool sectionEnabled;
  final ValueChanged<String?> onGroupChanged;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onFacilityFilterChanged;
  final VoidCallback onClearFilters;

  const _StudentsFiltersRow({
    required this.selectedGroup,
    required this.selectedClass,
    required this.selectedSection,
    required this.facilityFilter,
    required this.classItems,
    required this.sectionItems,
    required this.classEnabled,
    required this.sectionEnabled,
    required this.onGroupChanged,
    required this.onClassChanged,
    required this.onSectionChanged,
    required this.onFacilityFilterChanged,
    required this.onClearFilters,
  });

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Expanded(
      child: SizedBox(
        height: 42,
        child: DropdownButtonFormField<String>(
          isDense: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          value: value,
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dropdown(
          label: 'Group',
          value: selectedGroup,
          items: const ['All', 'Nursery', 'Primary School', 'Middle School', 'High School', 'College'],
          onChanged: onGroupChanged,
        ),
        const SizedBox(width: 12),
        _dropdown(
          label: 'Class',
          value: selectedClass,
          items: classItems,
          onChanged: onClassChanged,
          enabled: classEnabled,
        ),
        const SizedBox(width: 12),
        _dropdown(
          label: 'Section',
          value: selectedSection,
          items: sectionItems,
          onChanged: onSectionChanged,
          enabled: sectionEnabled,
        ),
        const SizedBox(width: 12),
        _dropdown(
          label: 'Facility',
          value: facilityFilter,
          items: const ['All', 'Hostel', 'Day', 'Mess', 'Bus'],
          onChanged: onFacilityFilterChanged,
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onClearFilters,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.clear, size: 16, color: Colors.redAccent),
                SizedBox(width: 6),
                Text(
                  'Clear',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}