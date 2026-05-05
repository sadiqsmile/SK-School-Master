import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_app/services/image_upload_service.dart';

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

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
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
        'className': _classNameController.text.trim(),
        'section': _sectionController.text.trim(),
        'gender': _genderController.text.trim(),
        'dob': _dobController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim(),
        'academicYear': _academicYearController.text.trim(),
        'parentName': _parentNameController.text.trim(),
        'parentPhone': _parentPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        // Facility fields
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  Future<void> _updatePhoto(Map<String, dynamic> data) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final compressed = await ImageUploadService.compress(bytes);
      final admissionNo = (data['admissionNo'] ?? widget.studentId).toString();
      final url = await ImageUploadService.upload(
        bytes: compressed,
        storagePath: 'schools/${widget.schoolId}/photos/$admissionNo.jpg',
      );
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .doc(widget.studentId)
          .update({'photoUrl': url});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
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
                                await _updateStudent();
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
                              Tab(icon: Icon(Icons.calendar_today), text: 'Attendance'),
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
                                ),
                                _AttendanceTab(
                                  studentId: widget.studentId,
                                  schoolId: widget.schoolId,
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
                    child: ClipOval(
                      child: photoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _avatarFallback(name),
                              errorWidget: (_, __, ___) =>
                                  _avatarFallback(name),
                            )
                          : _avatarFallback(name),
                    ),
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
                        const Icon(Icons.school, size: 14, color: Colors.white70),
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

  const _OverviewTab({
    super.key,
    required this.data,
    required this.isEditing,
    required this.controllers,
  });

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  static const List<String> _classList = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'I-PU', 'II-PU',
  ];
  static const List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
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
    if (widget.isEditing) _initLocalState();
  }

  @override
  void didUpdateWidget(_OverviewTab old) {
    super.didUpdateWidget(old);
    if (!old.isEditing && widget.isEditing) _initLocalState();
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

    // Facilities
    final data = widget.data;
    final hostelVal = (data['type'] ?? data['residence'] ?? data['hostel'] ?? '').toString().trim().toLowerCase();
    _isHostel = hostelVal == 'hostel' || hostelVal == 'h' || hostelVal == 'true';
    _isDayScholar = !_isHostel;
    final messVal = (data['mess'] ?? '').toString().trim().toLowerCase();
    _isMess = _isHostel ? true : (messVal == 'yes' || messVal == 'y' || messVal == '1' || messVal == 'true');
    final transVal = (data['transport'] ?? data['bus'] ?? '').toString().trim().toLowerCase();
    _isBus = transVal == 'yes' || transVal == 'y' || transVal == '1' || transVal == 'true';
  }

  List<String> _getSections(String? className) {
    if (className == null) return [];
    if (className == 'I-PU' || className == 'II-PU') {
      return ['A', 'B'];
    }
    return ['A', 'B', 'C', 'D'];
  }

  List<String> _getAcademicYears() {
    final year = DateTime.now().year;
    return List.generate(4, (i) {
      final start = year - i;
      return '$start-${start + 1}';
    });
  }

  String _ddmmyyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
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
          _dropdownRow('Section', _getSections(_selectedClass), _selectedSection,
              (val) {
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
          _fieldRow('Gender',
              _expandGender((data['gender'] ?? '').toString())),
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

  void _onHostelChanged(bool value) {
    setState(() {
      _isHostel = value;
      if (value) {
        _isDayScholar = false;
        _isMess = true; // auto-enable mess when hostel
      }
    });
  }

  void _onDayScholarChanged(bool value) {
    setState(() {
      _isDayScholar = value;
      if (value) _isHostel = false;
    });
  }

  void _onMessChanged(bool value) {
    if (_isHostel && !value) return; // block disabling mess while hostel is on
    setState(() => _isMess = value);
  }

  void _onBusChanged(bool value) {
    setState(() => _isBus = value);
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
            _facilityItem(
              icon: Icons.home_outlined,
              label: 'Day Scholar',
              value: _isDayScholar,
              onChanged: _onDayScholarChanged,
              color: Colors.blue,
            ),
            _facilityItem(
              icon: Icons.hotel,
              label: 'Hostel',
              value: _isHostel,
              onChanged: _onHostelChanged,
              color: Colors.purple,
            ),
            _facilityItem(
              icon: Icons.restaurant_outlined,
              label: 'Mess',
              value: _isMess,
              onChanged: _onMessChanged,
              color: Colors.green,
            ),
            _facilityItem(
              icon: Icons.directions_bus_outlined,
              label: 'Bus',
              value: _isBus,
              onChanged: _onBusChanged,
              color: Colors.orange,
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
            style:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
    if (!widget.isEditing && value.trim().isEmpty) return const SizedBox.shrink();
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
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.08) : Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? color.withOpacity(0.35) : Colors.grey.withOpacity(0.2),
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
              onChanged: onChanged,
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
    if (!widget.isEditing && value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            )
          else
            Text(
              value.isEmpty ? '—' : value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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

class _AttendanceTab extends StatelessWidget {
  final String studentId;
  final String schoolId;

  const _AttendanceTab({
    required this.studentId,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
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
                Icon(Icons.event_busy, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No attendance data',
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
            final isPresent = d['present'] == true;
            return ListTile(
              leading: Icon(
                isPresent ? Icons.check_circle : Icons.cancel,
                color: isPresent ? Colors.green : Colors.red,
              ),
              title: Text((d['date'] ?? '').toString()),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPresent
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPresent ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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