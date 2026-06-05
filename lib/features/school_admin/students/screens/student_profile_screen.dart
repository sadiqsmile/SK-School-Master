// features/school_admin/students/screens/student_profile_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../attendance/services/student_attendance_service.dart';
import 'package:school_app/core/services/image_service.dart';
import 'package:school_app/core/widgets/app_cached_image.dart';

// ── FORMATTER ─────────────────────────────────────────────────────────────────

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ── MAIN SCREEN ───────────────────────────────────────────────────────────────

class StudentProfileScreen extends StatefulWidget {
  final String studentId;
  final String schoolId;

  const StudentProfileScreen({
    super.key,
    required this.studentId,
    required this.schoolId,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _overviewKey = GlobalKey<_OverviewTabState>();
  bool _uploadingPhoto = false;
  bool _isEditing = false;
  bool _controllersInitialized = false;

  final _nameController = TextEditingController();
  final _admissionNoController = TextEditingController();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _genderController = TextEditingController();
  final _dobController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _admissionNoController.dispose();
    _classNameController.dispose();
    _sectionController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _bloodGroupController.dispose();
    _academicYearController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initControllers(Map<String, dynamic> data) {
    _nameController.text = (data['name'] ?? '').toString();
    _admissionNoController.text = (data['admissionNo'] ?? '').toString();
    _classNameController.text = (data['className'] ?? '').toString();
    _sectionController.text = (data['section'] ?? '').toString();
    _genderController.text = (data['gender'] ?? '').toString();
    _dobController.text = (data['dob'] ?? '').toString();
    _bloodGroupController.text = (data['bloodGroup'] ?? '').toString();
    _academicYearController.text = (data['academicYear'] ?? '').toString();
    _parentNameController.text = (data['parentName'] ?? '').toString();
    _parentPhoneController.text = (data['parentPhone'] ?? '').toString();
    _addressController.text = (data['address'] ?? '').toString();
    _controllersInitialized = true;
  }

  Future<bool> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return false;

    final name = _nameController.text.trim();

    final className = _classNameController.text.trim();

    final classId = className.replaceAll('Class ', '').trim();

    final section = _sectionController.text.trim().toUpperCase();

    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .doc(widget.studentId)
          .update({
        'name': name,
        'nameLower': name.toLowerCase(),
        'admissionNo': _admissionNoController.text.trim(),
        'className': className,
        'classId': classId,
        'section': section,
        'classKey': 'Class $classId $section',
        'gender': _genderController.text.trim(),
        'dob': _dobController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim(),
        'academicYear': _academicYearController.text.trim(),
        'parentName': _parentNameController.text.trim(),
        'parentPhone': _parentPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        'hostel': _overviewKey.currentState?._isHostel ?? false,
        'dayScholar': _overviewKey.currentState?._isDayScholar ?? false,
        'mess': _overviewKey.currentState?._isMess ?? false,
        'bus': _overviewKey.currentState?._isBus ?? false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated')),
        );
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _softDeleteStudent() async {
    final firestore = FirebaseFirestore.instance;
    final snap = await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .doc(widget.studentId)
        .get();
    if (!snap.exists) return;
    final payload = Map<String, dynamic>.from(snap.data()!)
      ..['deletedAt'] = FieldValue.serverTimestamp();
    await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('deleted_students')
        .doc(widget.studentId)
        .set(payload);
    await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .doc(widget.studentId)
        .delete();
  }

  Future<void> _updatePhoto(
    Map<String, dynamic> data,
  ) async {
    setState(() {
      _uploadingPhoto = true;
    });

    try {
      final bytes = await ImageService.pickCropCompressImage();

      if (bytes == null) return;

      final admissionNo = (data['admissionNo'] ?? widget.studentId).toString();

      final url = await ImageService.uploadImage(
        schoolId: widget.schoolId,
        module: 'students',
        type: 'profile',
        fileName: admissionNo,
        bytes: bytes,
      );

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .doc(widget.studentId)
          .update({
        'photoUrl': url,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Photo update failed: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .doc(widget.studentId)
          .snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> data =
            (snapshot.hasData && snapshot.data!.data() != null)
                ? snapshot.data!.data() as Map<String, dynamic>
                : {};
        final name = (data['name'] ?? '').toString();

        if (!_controllersInitialized && data.isNotEmpty) {
          _initControllers(data);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => context.pop(),
            ),
            title: Text(
              name.isNotEmpty ? name : 'Student Profile',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Student',
                onPressed: data.isEmpty
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Student'),
                            content: const Text(
                                'Move this student to the recycle bin?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await _softDeleteStudent();
                          if (mounted) context.pop();
                        }
                      },
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCard(
                        data: data,
                        uploadingPhoto: _uploadingPhoto,
                        onUpdatePhoto: _updatePhoto,
                        isEditing: _isEditing,
                        onEdit: data.isEmpty
                            ? null
                            : () async {
                                if (_isEditing) {
                                  final ok = await _updateStudent();
                                  if (!ok)
                                    return; // keep edit mode open on validation failure
                                }
                                setState(() => _isEditing = !_isEditing);
                              },
                      ),
                      const SizedBox(height: 16),
                      DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            TabBar(
                              indicator: const UnderlineTabIndicator(
                                borderSide: BorderSide(
                                  width: 3,
                                  color: Color(0xFF6366F1),
                                ),
                                insets: EdgeInsets.symmetric(horizontal: 20),
                              ),
                              indicatorSize: TabBarIndicatorSize.label,
                              labelColor: const Color(0xFF6366F1),
                              unselectedLabelColor: Colors.grey,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              tabs: const [
                                Tab(icon: Icon(Icons.person), text: 'Overview'),
                                Tab(
                                    icon: Icon(Icons.calendar_today),
                                    text: 'Attendance'),
                                Tab(icon: Icon(Icons.bar_chart), text: 'Marks'),
                              ],
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.65,
                              child: TabBarView(
                                children: [
                                  _OverviewTab(
                                    key: _overviewKey,
                                    data: data,
                                    isEditing: _isEditing,
                                    controllers: {
                                      'name': _nameController,
                                      'admissionNo': _admissionNoController,
                                      'className': _classNameController,
                                      'section': _sectionController,
                                      'gender': _genderController,
                                      'dob': _dobController,
                                      'bloodGroup': _bloodGroupController,
                                      'academicYear': _academicYearController,
                                      'parentName': _parentNameController,
                                      'parentPhone': _parentPhoneController,
                                      'address': _addressController,
                                    },
                                    schoolId: widget.schoolId,
                                  ),
                                  _AttendanceTab(
                                    studentId: (data['admissionNo'] ??
                                            widget.studentId)
                                        .toString(),
                                    schoolId: widget.schoolId,
                                    className: (data['class'] ??
                                            data['className'] ??
                                            '')
                                        .toString(),
                                    section: (data['section'] ?? '').toString(),
                                  ),
                                  _MarksTab(
                                    studentId: widget.studentId,
                                    schoolId: widget.schoolId,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ── HERO CARD ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool uploadingPhoto;
  final Future<void> Function(Map<String, dynamic>) onUpdatePhoto;
  final VoidCallback? onEdit;
  final bool isEditing;

  const _HeroCard({
    required this.data,
    required this.uploadingPhoto,
    required this.onUpdatePhoto,
    required this.isEditing,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? '').toString();
    final className = (data['className'] ?? '').toString();
    final section = (data['section'] ?? '').toString();
    final admissionNo = (data['admissionNo'] ?? '').toString();
    final photoUrl = (data['photoUrl'] ?? '').toString();
    final classLabel = section.isNotEmpty ? '$className $section' : className;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x4D4F46E5),
                  blurRadius: 20,
                  offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: photoUrl.isNotEmpty
                        ? AppCachedImage(
                            imageUrl: photoUrl,
                            width: 68,
                            height: 68,
                            radius: 100,
                          )
                        : _avatarFallback(name),
                  ),
                  if (uploadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => onUpdatePhoto(data),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Color(0xFF4F46E5)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (classLabel.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.school,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(classLabel,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ]),
                    if (admissionNo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.tag, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('Adm: $admissionNo',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: IconButton(
            icon: Icon(
              isEditing ? Icons.check_circle : Icons.edit,
              color: Colors.white,
              size: 20,
            ),
            tooltip: isEditing ? 'Save' : 'Edit',
            onPressed: onEdit,
            splashRadius: 22,
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: const Color(0xFFEDE9FE),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
    );
  }
}

// ── OVERVIEW TAB ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isEditing;
  final Map<String, TextEditingController> controllers;
  final String schoolId;

  const _OverviewTab({
    super.key,
    required this.data,
    required this.isEditing,
    required this.controllers,
    required this.schoolId,
  });

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  List<String> _classList = [];

  Future<void> _loadClasses() async {
    final schoolId = widget.schoolId;

    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .get();

    _classList.clear();
    _sectionsMap.clear();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final name = (data['name'] ?? '').toString();

      final sections = List<String>.from(
        data['sections'] ?? [],
      );

      _classList.add(name);

      _sectionsMap[name] = sections;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Map<String, List<String>> _sectionsMap = {};

  static const List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  static const List<String> _genders = ['BOY', 'GIRL'];

  DateTime? _selectedDob;
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedAcademicYear;

  // Facility state
  bool _isHostel = false;
  bool _isDayScholar = false;
  bool _isMess = false;
  bool _isBus = false;

  @override
  void initState() {
    super.initState();

    _loadClasses();

    _initLocalState();
  }

  @override
  void didUpdateWidget(_OverviewTab old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data || (!old.isEditing && widget.isEditing)) {
      _initLocalState();
    }
  }

  void _initLocalState() {
    // DOB
    final dobRaw = widget.data['dob'];
    DateTime? parsedDob;
    if (dobRaw is Timestamp) {
      parsedDob = dobRaw.toDate();
    } else {
      parsedDob = DateTime.tryParse((dobRaw ?? '').toString());
    }
    _selectedDob = parsedDob;
    if (parsedDob != null) {
      widget.controllers['dob']?.text = _ddmmyyyy(parsedDob);
    }

    // Class
    final rawClass =
        (widget.controllers['className']?.text ?? '').trim().toUpperCase();
    _selectedClass = _classList.contains(rawClass) ? rawClass : null;

    // Section
    final rawSection =
        (widget.controllers['section']?.text ?? '').trim().toUpperCase();
    final secs = _getSections(_selectedClass);
    _selectedSection = secs.contains(rawSection) ? rawSection : null;

    // Gender
    final rawGender =
        (widget.controllers['gender']?.text ?? '').trim().toUpperCase();
    if (rawGender == 'M' || rawGender == 'MALE' || rawGender == 'BOY') {
      _selectedGender = 'BOY';
    } else if (rawGender == 'F' ||
        rawGender == 'FEMALE' ||
        rawGender == 'GIRL') {
      _selectedGender = 'GIRL';
    } else {
      _selectedGender = null;
    }

    // Blood Group
    final rawBG =
        (widget.controllers['bloodGroup']?.text ?? '').trim().toUpperCase();
    _selectedBloodGroup = _bloodGroups.contains(rawBG) ? rawBG : null;

    // Academic Year
    final rawAY = (widget.controllers['academicYear']?.text ?? '').trim();
    final years = _getAcademicYears();
    _selectedAcademicYear = years.contains(rawAY) ? rawAY : null;

    // Facilities — primary: boolean keys; fallback: old string format
    final data = widget.data;
    final hostelRaw = data['hostel'];
    if (hostelRaw is bool) {
      _isHostel = hostelRaw;
    } else {
      _isHostel =
          (data['type'] ?? '').toString().trim().toLowerCase() == 'hostel';
    }
    final dayScholarRaw = data['dayScholar'];
    _isDayScholar = dayScholarRaw is bool ? dayScholarRaw : !_isHostel;
    final messRaw = data['mess'];
    if (messRaw is bool) {
      _isMess = messRaw;
    } else {
      final messStr = (messRaw ?? '').toString().trim().toLowerCase();
      _isMess = _isHostel ? true : (messStr == 'yes' || messStr == 'y');
    }
    final busRaw = data['bus'];
    if (busRaw is bool) {
      _isBus = busRaw;
    } else {
      final transStr =
          (data['transport'] ?? busRaw ?? '').toString().trim().toLowerCase();
      _isBus = transStr == 'yes' || transStr == 'y';
    }
  }

  List<String> _getSections(
    String? className,
  ) {
    if (className == null) {
      return [];
    }

    return _sectionsMap[className] ?? [];
  }

  List<String> _getAcademicYears() {
    final year = DateTime.now().year;
    return List.generate(4, (i) {
      final start = year - i;
      return '$start-${start + 1}';
    });
  }

  String _ddmmyyyy(DateTime d) => '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.year}';

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildBasicInfo()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildParentInfo()),
                  ],
                )
              else ...[
                _buildBasicInfo(),
                const SizedBox(height: 16),
                _buildParentInfo(),
              ],
              const SizedBox(height: 16),
              _buildFacilities(),
            ],
          );
        },
      ),
    );
  }

  // ── BASIC INFO ─────────────────────────────────────────────────────────────

  Widget _buildBasicInfo() {
    final data = widget.data;
    final className = (data['className'] ?? '').toString();
    final section = (data['section'] ?? '').toString();
    final classLabel = section.isNotEmpty ? '$className $section' : className;

    return _sectionCard(
      icon: Icons.person_outline,
      title: 'Basic Info',
      children: [
        _fieldRow('Student Name', (data['name'] ?? '').toString(),
            controller: widget.controllers['name'],
            formatters: [UpperCaseTextFormatter()]),
        _fieldRow('Admission No', (data['admissionNo'] ?? '').toString(),
            controller: widget.controllers['admissionNo'],
            formatters: [UpperCaseTextFormatter()]),
        if (widget.isEditing) ...[
          _dropdownRow('Class', _classList, _selectedClass, (val) {
            setState(() {
              _selectedClass = val;
              _selectedSection = null;
              widget.controllers['className']?.text = val ?? '';
              widget.controllers['section']?.text = '';
            });
          }),
          _dropdownRow(
              'Section', _getSections(_selectedClass), _selectedSection, (val) {
            setState(() {
              _selectedSection = val;
              widget.controllers['section']?.text = val ?? '';
            });
          }),
        ] else
          _fieldRow('Class', classLabel),
        if (widget.isEditing)
          _dropdownRow('Gender', _genders, _selectedGender, (val) {
            setState(() {
              _selectedGender = val;
              widget.controllers['gender']?.text = val ?? '';
            });
          })
        else
          _fieldRow('Gender', _expandGender((data['gender'] ?? '').toString())),
        if (widget.isEditing)
          _dobRow()
        else
          _fieldRow('Date of Birth', _formatDate(data['dob'])),
        if (widget.isEditing)
          _dropdownRow('Blood Group', _bloodGroups, _selectedBloodGroup, (val) {
            setState(() {
              _selectedBloodGroup = val;
              widget.controllers['bloodGroup']?.text = val ?? '';
            });
          })
        else
          _fieldRow('Blood Group', (data['bloodGroup'] ?? '').toString()),
        if (widget.isEditing)
          _dropdownRow(
              'Academic Year', _getAcademicYears(), _selectedAcademicYear,
              (val) {
            setState(() {
              _selectedAcademicYear = val;
              widget.controllers['academicYear']?.text = val ?? '';
            });
          })
        else
          _fieldRow('Academic Year', (data['academicYear'] ?? '').toString()),
      ],
    );
  }

  // ── PARENT INFO ────────────────────────────────────────────────────────────

  Widget _buildParentInfo() {
    final data = widget.data;
    return _sectionCard(
      icon: Icons.family_restroom_outlined,
      title: 'Parent / Guardian',
      children: [
        _fieldRow('Parent Name', (data['parentName'] ?? '').toString(),
            controller: widget.controllers['parentName'],
            formatters: [UpperCaseTextFormatter()]),
        _phoneRow(),
        _fieldRow('Address', (data['address'] ?? '').toString(),
            controller: widget.controllers['address'],
            formatters: [UpperCaseTextFormatter()]),
      ],
    );
  }

  // ── FACILITIES ─────────────────────────────────────────────────────────────

  // ── FACILITY LOGIC ─────────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _handleDayScholar(bool val) {
    setState(() {
      if (val) {
        _isDayScholar = true;
        _isHostel = false;
      } else {
        if (!_isHostel) {
          _showError('Select either Day Scholar or Hostel');
          return;
        }
        _isDayScholar = false;
      }
    });
  }

  void _handleHostel(bool val) {
    setState(() {
      if (val) {
        _isHostel = true;
        _isDayScholar = false;
        _isMess = true;
      } else {
        if (!_isDayScholar) {
          _showError('Select either Hostel or Day Scholar');
          return;
        }
        _isHostel = false;
      }
    });
  }

  Widget _buildFacilities() {
    final data = widget.data;
    final route = (data['route'] ?? '').toString();
    final stop = (data['stop'] ?? '').toString();
    final vehicleNo = (data['vehicleNo'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          icon: Icons.apartment_outlined,
          title: 'Facilities',
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _facilityItem(
                      icon: Icons.home_outlined,
                      label: 'Day Scholar',
                      value: _isDayScholar,
                      isEditing: widget.isEditing,
                      onChanged: _handleDayScholar,
                      color: Colors.blue,
                    ),
                    _facilityItem(
                      icon: Icons.bed,
                      label: 'Hostel',
                      value: _isHostel,
                      isEditing: widget.isEditing,
                      onChanged: _handleHostel,
                      color: Colors.purple,
                    ),
                    _facilityItem(
                      icon: Icons.restaurant,
                      label: 'Mess',
                      value: _isMess,
                      isEditing: widget.isEditing,
                      onChanged: (val) {
                        if (!widget.isEditing) return;
                        if (_isHostel && !val) {
                          _showError('Mess is required for Hostel');
                          return;
                        }
                        setState(() => _isMess = val);
                      },
                      color: Colors.green,
                    ),
                    _facilityItem(
                      icon: Icons.directions_bus,
                      label: 'Transport',
                      value: _isBus,
                      isEditing: widget.isEditing,
                      onChanged: (val) {
                        if (!widget.isEditing) return;
                        setState(() => _isBus = val);
                      },
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_isBus &&
            (route.isNotEmpty || stop.isNotEmpty || vehicleNo.isNotEmpty)) ...[
          const SizedBox(height: 16),
          _sectionCard(
            icon: Icons.directions_bus_outlined,
            title: 'Transport Details',
            children: [
              _fieldRow('Route', route),
              _fieldRow('Stop', stop),
              _fieldRow('Vehicle No', vehicleNo),
            ],
          ),
        ],
      ],
    );
  }

  // ── EDIT WIDGETS ───────────────────────────────────────────────────────────

  Widget _dobRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Date of Birth',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          TextFormField(
            controller: widget.controllers['dob'],
            readOnly: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              suffixIcon: const Icon(Icons.calendar_today, size: 16),
            ),
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            onTap: () async {
              final initial = _selectedDob ?? DateTime(2010);
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(1995),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _selectedDob = picked;
                  widget.controllers['dob']?.text = _ddmmyyyy(picked);
                });
              }
            },
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _phoneRow() {
    final value = (widget.data['parentPhone'] ?? '').toString();
    if (!widget.isEditing && value.trim().isEmpty)
      return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phone',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          if (widget.isEditing)
            TextFormField(
              controller: widget.controllers['parentPhone'],
              keyboardType: TextInputType.number,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                counterText: '',
              ),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (v.length != 10) return 'Enter 10-digit number';
                return null;
              },
            )
          else
            Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _dropdownRow(String label, List<String> items, String? value,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            items: items
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: onChanged,
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  Widget _facilityItem({
    required IconData icon,
    required String label,
    required bool value,
    required bool isEditing,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: value ? color : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: value ? color : Colors.grey[700],
              ),
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              activeColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: isEditing ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final visible =
        children.where((w) => w is! SizedBox || w.key != null).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 8),
          ...visible,
        ],
      ),
    );
  }

  Widget _fieldRow(
    String label,
    String value, {
    TextEditingController? controller,
    List<TextInputFormatter>? formatters,
  }) {
    if (!widget.isEditing && value.trim().isEmpty)
      return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          if (widget.isEditing && controller != null)
            TextFormField(
              controller: controller,
              inputFormatters: formatters,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            )
          else
            Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    if (raw is Timestamp) return _ddmmyyyy(raw.toDate());
    final str = raw.toString().trim();
    if (str.isEmpty) return '';
    final d = DateTime.tryParse(str);
    if (d != null) return _ddmmyyyy(d);
    return str;
  }

  String _expandGender(String g) {
    switch (g.trim().toLowerCase()) {
      case 'm':
      case 'male':
        return 'Male';
      case 'f':
      case 'female':
        return 'Female';
      case 'boy':
        return 'Boy';
      case 'girl':
        return 'Girl';
      default:
        return g;
    }
  }
}

// ── ATTENDANCE TAB ────────────────────────────────────────────────────────────

class _AttendanceTab extends StatefulWidget {
  final String studentId;
  final String schoolId;
  final String className;
  final String section;

  const _AttendanceTab({
    required this.studentId,
    required this.schoolId,
    required this.className,
    required this.section,
  });

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  final _attendanceService = StudentAttendanceService();
  DateTime _selectedMonth = DateTime.now();

  Future<Map<String, dynamic>> _fetch() =>
      _attendanceService.getStudentMonthlyAttendance(
        schoolId: widget.schoolId,
        studentId: widget.studentId,
        className: widget.className,
        section: widget.section,
        selectedMonth: _selectedMonth,
      );

  Widget _chip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSummary(Map<String, dynamic> attendance) {
    final present = attendance['present'] as int;
    final absent = attendance['absent'] as int;
    final holiday = attendance['holiday'] as int;
    final percent = attendance['percentage'] as int;
    final total = present + absent + holiday;
    final List<DateTime> absentDates =
        List<DateTime>.from(attendance['absentDates'] ?? []);
    final bool showWarning =
        (attendance['showWarning'] ?? false) as bool && percent < 75;
    final bool criticalWarning = percent < 50;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showWarning)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: criticalWarning
                    ? Colors.red.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: criticalWarning
                      ? Colors.red.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    criticalWarning
                        ? Icons.warning_rounded
                        : Icons.info_outline,
                    color: criticalWarning ? Colors.red : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          criticalWarning
                              ? 'Critical Attendance Warning'
                              : 'Low Attendance Warning',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: criticalWarning
                                ? Colors.red.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          criticalWarning
                              ? 'Attendance is below 50%. Immediate attention required.'
                              : 'Attendance is below 75%. Student may not meet attendance requirements.',
                          style: TextStyle(
                            height: 1.4,
                            color: criticalWarning
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _chip('Present', present, Colors.green),
              _chip('Absent', absent, Colors.red),
              _chip('Holiday', holiday, Colors.orange),
              _chip('%', percent, Colors.blue),
            ],
          ),
          const SizedBox(height: 20),
          if (total == 0)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 32),
                  Icon(Icons.event_busy, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No attendance data for this month',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          if (absentDates.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_busy, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Absent Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...absentDates.map((date) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${date.day.toString().padLeft(2, '0')} '
                            '${_monthName(date.month)} '
                            '${date.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 820,
              ),
              child: _buildAttendanceCalendar(),
            ),
          ),
          const SizedBox(height: 24),
          _buildAttendanceAnalytics(),
        ],
      ),
    );
  }

  Widget _buildAttendanceCalendar() {
    return FutureBuilder<Map<int, String>>(
      key: ValueKey(
        '${_selectedMonth.year}-${_selectedMonth.month}-cal',
      ),
      future: _attendanceService.getStudentDailyAttendance(
        schoolId: widget.schoolId,
        studentId: widget.studentId,
        className: widget.className,
        section: widget.section,
        selectedMonth: _selectedMonth,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final attendanceMap = snapshot.data!;

        final daysInMonth = DateUtils.getDaysInMonth(
          _selectedMonth.year,
          _selectedMonth.month,
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attendance Calendar',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final isMobile = MediaQuery.of(context).size.width < 600;
                  final firstDayOfMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month,
                    1,
                  );

                  final startWeekday = firstDayOfMonth.weekday % 7;

                  final totalCells = daysInMonth + startWeekday;

                  const weekDays = [
                    'SUN',
                    'MON',
                    'TUE',
                    'WED',
                    'THU',
                    'FRI',
                    'SAT',
                  ];

                  return Column(
                    children: [
                      // WEEKDAY HEADER
                      Row(
                        children: weekDays.map((day) {
                          return Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: totalCells,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: isMobile ? 4 : 6,
                          mainAxisSpacing: isMobile ? 4 : 6,
                          childAspectRatio: isMobile ? 1.0 : 1.18,
                        ),
                        itemBuilder: (context, index) {
                          // Empty space before month starts
                          if (index < startWeekday) {
                            return const SizedBox();
                          }

                          final day = index - startWeekday + 1;
                          final status = attendanceMap[day];

                          Color bgColor = Colors.grey.shade100;
                          Color textColor = Colors.black87;

                          if (status == 'present') {
                            bgColor = Colors.green.shade100;
                            textColor = Colors.green.shade800;
                          }

                          if (status == 'absent') {
                            bgColor = Colors.red.shade100;
                            textColor = Colors.red.shade800;
                          }

                          if (status == 'holiday') {
                            bgColor = Colors.orange.shade100;
                            textColor = Colors.orange.shade800;
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(
                                isMobile ? 10 : 14,
                              ),
                              border: Border.all(
                                color: bgColor.withOpacity(0.25),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _legend(Colors.green, 'Present'),
                  _legend(Colors.red, 'Absent'),
                  _legend(Colors.orange, 'Holiday'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceAnalytics() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _attendanceService.getAttendanceAnalytics(
        schoolId: widget.schoolId,
        studentId: widget.studentId,
        className: widget.className,
        section: widget.section,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final analytics = snapshot.data!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Analytics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 280,
                child: BarChart(
                  BarChartData(
                    maxY: 100,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.25),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= analytics.length) {
                              return const SizedBox();
                            }
                            final percentage =
                                analytics[index]['percentage'] ?? 0;
                            if (percentage == 0) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: percentage >= 75
                                      ? Colors.green
                                      : percentage >= 50
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 20,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            if (index < 0 || index >= analytics.length) {
                              return const SizedBox();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                analytics[index]['monthName'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(
                      analytics.length,
                      (index) {
                        final item = analytics[index];
                        final percentage = (item['percentage'] ?? 0).toDouble();

                        Color barColor;
                        if (percentage >= 75) {
                          barColor = Colors.green;
                        } else if (percentage >= 50) {
                          barColor = Colors.orange;
                        } else {
                          barColor = Colors.red;
                        }

                        return BarChartGroupData(
                          x: index,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: percentage,
                              width: 32,
                              borderRadius: BorderRadius.circular(8),
                              color: barColor,
                            ),
                          ],
                          showingTooltipIndicators: [],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _selectedMonth =
                      DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                }),
              ),
              Text(
                '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _selectedMonth =
                      DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(widget.schoolId)
                .collection('attendance')
                .snapshots(),
            builder: (context, attendanceSnapshot) {
              if (attendanceSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return FutureBuilder<Map<String, dynamic>>(
                key: ValueKey('${_selectedMonth.year}-${_selectedMonth.month}'),
                future: _fetch(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('No attendance data'));
                  }
                  return _buildSummary(snapshot.data!);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[month];
  }
}

// ── MARKS TAB ─────────────────────────────────────────────────────────────────

class _MarksTab extends StatelessWidget {
  final String studentId;
  final String schoolId;

  const _MarksTab({
    required this.studentId,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('marks')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No marks available',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            final subject = (d['subject'] ?? '').toString();
            final marks = d['marks']?.toString() ?? '-';
            final total = d['total']?.toString();
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEDE9FE),
                child: Icon(Icons.book_outlined,
                    size: 18, color: Color(0xFF4F46E5)),
              ),
              title: Text(subject,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: Text(
                total != null ? '$marks / $total' : marks,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5)),
              ),
            );
          },
        );
      },
    );
  }
}
