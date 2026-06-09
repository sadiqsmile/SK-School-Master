import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditTeacherProfileScreen extends StatefulWidget {

  final String schoolId;
  final String teacherId;
  final Map<String, dynamic> data;

  const EditTeacherProfileScreen({
    super.key,
    required this.schoolId,
    required this.teacherId,
    required this.data,
  });

  @override
  State<EditTeacherProfileScreen> createState() =>
      _EditTeacherProfileScreenState();
}

class _EditTeacherProfileScreenState
    extends State<EditTeacherProfileScreen> {

  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController qualificationController;
  late final TextEditingController addressController;
  late final TextEditingController dobController;
  late final TextEditingController bloodGroupController;
  late final TextEditingController aadharController;
  late final TextEditingController emergencyController;

  String? gender;
  String? bloodGroup;

  String? classTeacherClass;
  String? classTeacherSection;

  List<String> subjects = [];
  List<String> assignedClasses = [];
  List attendanceClasses = [];
  List attendanceGroups = [];
  List allGroups = [];
  List<Map<String, dynamic>> classDocs = [];

  bool isSaving = false;

List<String> allClasses = [];

  @override
  void initState() {
    super.initState();

    final d = widget.data;

subjects = List<String>.from( d['subjects'] ?? [],);

    nameController =
        TextEditingController(text: d['name'] ?? '');

    phoneController =
        TextEditingController(text: d['phone'] ?? '');

    emailController =
        TextEditingController(text: d['email'] ?? '');

    qualificationController =
        TextEditingController(
            text: d['qualification'] ?? '');

    addressController =
        TextEditingController(text: d['address'] ?? '');

    dobController =
        TextEditingController(text: d['dob'] ?? '');

    bloodGroupController =
        TextEditingController(
            text: d['bloodGroup'] ?? '');

    aadharController =
        TextEditingController(text: d['aadharNo'] ?? '');

    emergencyController =
        TextEditingController(
            text: d['emergencyContact'] ?? '');

    final g = d['gender'] ?? '';
    gender = g.isEmpty ? null : g;

    final bg = d['bloodGroup'] ?? '';
    bloodGroup = bg.isEmpty ? null : bg;

    final classTeacher = d['classTeacherOf'];
    if (classTeacher != null) {
      classTeacherClass = classTeacher['classId'];
      classTeacherSection = classTeacher['sectionId'];
    }

    assignedClasses = List<String>.from(
      d['assignmentKeys'] ?? [],
    );

    attendanceClasses = List.from(
      d['attendanceClasses'] ?? [],
    );

if (classTeacherClass != null &&
    classTeacherSection != null) {

  attendanceClasses.remove(
    '$classTeacherClass $classTeacherSection',
  );
}





    attendanceGroups = List.from(
      d['attendanceGroups'] ?? [],
    );

_loadClasses();


  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    qualificationController.dispose();
    addressController.dispose();
    dobController.dispose();
    bloodGroupController.dispose();
    aadharController.dispose();
    emergencyController.dispose();
    super.dispose();
  }


Future<void> _loadClasses() async {

  final snap = await FirebaseFirestore.instance
      .collection('schools')
      .doc(widget.schoolId)
      .collection('classes')
      .get();

  classDocs = [];

  final groups = <String>{};

  final temp = <String>[];

  for (final doc in snap.docs) {

    final data = doc.data();

    classDocs.add(data);

    final groupName =
        (data['groupName'] ?? '')
            .toString()
            .trim();

    if (groupName.isNotEmpty) {
      groups.add(groupName);
    }

    final className =
        (data['name'] ?? '').toString();

    final sections =
        List<String>.from(
      data['sections'] ?? [],
    );

    for (final section in sections) {
      temp.add('$className $section');
    }
  }

if (mounted) {
  setState(() {

    allClasses = temp;
    allGroups = groups.toList()
      ..sort();

  });
}

}

  Future<void> _save() async {

    setState(() => isSaving = true);

    try {

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(widget.teacherId)
          .update({

        "subjects": subjects,

        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "qualification":
            qualificationController.text.trim(),
        "address": addressController.text.trim(),
        "dob": dobController.text.trim(),
        "bloodGroup": bloodGroup ?? '',
        "aadharNo": aadharController.text.trim(),
        "emergencyContact":
            emergencyController.text.trim(),
        "gender": gender ?? '',
        
      "classTeacherOf":
    classTeacherClass != null &&
            classTeacherSection != null
        ? {
            "classId": classTeacherClass,
            "sectionId": classTeacherSection,
          }
        : null,



        "assignmentKeys": assignedClasses,
        "attendanceClasses": attendanceClasses,
        "attendanceGroups": attendanceGroups,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      final userRef = FirebaseFirestore.instance
    .collection('users')
    .doc(widget.teacherId);

final userSnap = await userRef.get();

if (userSnap.exists) {
  await userRef.update({
    "name": nameController.text.trim(),
    "phone": phoneController.text.trim(),
  });
}
 

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Teacher Profile Updated ✅"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) setState(() => isSaving = false);
  }

  void _showAttendancePermissionDialog() {

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(

          title: const Text(
            'Attendance Permissions',
          ),

          content: StatefulBuilder(
            builder: (context, setDialogState) {

              return SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      const Text(
                        'Attendance Groups',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            allGroups.map(
                          (group) {

                            return FilterChip(

                              label: Text(group),

                              selected:
                                  attendanceGroups
                                      .contains(
                                group,
                              ),

                              onSelected: (value) {

                                setDialogState(() {

                                  if (value) {

                                    attendanceGroups
                                        .add(group);

                                  } else {

                                    attendanceGroups
                                        .remove(group);
                                  }
                                });
                              },
                            );
                          },
                        ).toList(),
                      ),

                      const SizedBox(height: 20),

                      const Divider(),

                      const SizedBox(height: 10),

                      const Text(
                        'Attendance Classes',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: classDocs
                            .where((data) {

                              if (attendanceGroups.isEmpty) {
                                return false;
                              }

                              return attendanceGroups.contains(
                                data['groupName'],
                              );
                            })
                            .expand((data) {

                              final className =
                                  (data['name'] ?? '')
                                      .toString();

                              final sections =
                                  List.from(
                                data['sections'] ?? [],
                              );

                              return sections.map(
                                (s) => '$className $s',
                              );
                            })
                            .map((classSection) {

                              return FilterChip(

                                label: Text(
                                  classSection,
                                ),

                                selected:
                                    attendanceClasses.contains(
                                  classSection,
                                ),

                                onSelected: (value) {

                                  setDialogState(() {

                                    if (value) {

                                      attendanceClasses.add(
                                        classSection,
                                      );

                                    } else {

                                      attendanceClasses.remove(
                                        classSection,
                                      );
                                    }
                                  });
                                },
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {

                setState(() {});

                Navigator.pop(context);
              },
              child: const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String caption, String title) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(
          caption.toUpperCase(),

          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          title,

          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff374151),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  InputDecoration _dropDecor(String label) {

    return InputDecoration(
      labelText: label,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Teacher"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: 700),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // ── BASIC INFORMATION ─────────────
                _sectionTitle(
                  "Teacher",
                  "Basic Information",
                ),

                const SizedBox(height: 20),

                _field(
                  label: "Name",
                  controller: nameController,
                ),

                const SizedBox(height: 16),

                _field(
                  label: "Phone",
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                _field(
                  label: "Email",
                  controller: emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: _dropDecor("Gender"),

                  items: ["Male", "Female", "Other"]
                      .map((e) {

                    return DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    );

                  }).toList(),

                  onChanged: (v) {
                    setState(() => gender = v);
                  },
                ),

                const SizedBox(height: 16),

               TextFormField(
  controller: dobController,
  readOnly: true,

  decoration: InputDecoration(
    labelText: "Date of Birth",
    suffixIcon: const Icon(Icons.calendar_month),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),

  onTap: () async {

    DateTime initialDate = DateTime(1990);

    try {

      if (dobController.text.isNotEmpty) {
        initialDate =
            DateTime.parse(dobController.text);
      }

    } catch (_) {}

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {

      dobController.text =
          "${pickedDate.year}-"
          "${pickedDate.month.toString().padLeft(2, '0')}-"
          "${pickedDate.day.toString().padLeft(2, '0')}";
    }
  },
),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: bloodGroup,
                  decoration: _dropDecor("Blood Group"),

                  items: [
                    "A+",
                    "A-",
                    "B+",
                    "B-",
                    "O+",
                    "O-",
                    "AB+",
                    "AB-",
                  ].map((e) {

                    return DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    );

                  }).toList(),

                  onChanged: (v) {
                    setState(() => bloodGroup = v);
                  },
                ),

                const SizedBox(height: 16),

                _field(
                  label: "Qualification",
                  controller: qualificationController,
                ),

                const SizedBox(height: 16),

                _field(
                  label: "Emergency Contact",
                  controller: emergencyController,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                _field(
                  label: "Aadhar Number",
                  controller: aadharController,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                _field(
                  label: "Address",
                  controller: addressController,
                  maxLines: 2,
                ),

                // ── CLASS TEACHER ─────────────────
                const SizedBox(height: 36),

                _sectionTitle(
                  "Academic",
                  "Class Teacher",
                ),

                const SizedBox(height: 20),

               
                Row(
                  children: [

                    Expanded(
                      child:
                          DropdownButtonFormField<String>(



                        value: classTeacherClass,
                        decoration: _dropDecor("Class"),




                     items: classDocs.map((doc) {
  final className =
              (doc['name'] ?? '').toString();

  return DropdownMenuItem(
    value: className,
    child: Text(className),
  );

}).toList(),





                     onChanged: (v) {

  setState(() {

    classTeacherClass = v;
    classTeacherSection = null;

  });
},
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child:
                          DropdownButtonFormField<String>(
                        value: classTeacherSection,
                        decoration:
                            _dropDecor("Section"),

                       items: (() {

if (classDocs.isEmpty) {
  return <DropdownMenuItem<String>>[];
}

final match = classDocs.where((d) {

  return d['name'] ==
      classTeacherClass;

}).toList();

if (match.isEmpty) {
  return <DropdownMenuItem<String>>[];
}

final selectedClass = match.first;




  final sections =
      List<String>.from(
    selectedClass['sections'] ?? [],
  );

  return sections.map((e) {

    return DropdownMenuItem(
      value: e,
      child: Text(e),
    );

  }).toList();

})(),

                          

onChanged: (v) {

  setState(() {

    classTeacherSection = v;

  });
},




                      ),
                    ),
                  ],
                ),







const SizedBox(height: 12),

OutlinedButton.icon(
  onPressed: () {
    setState(() {
      classTeacherClass = null;
      classTeacherSection = null;
    });
  },
  icon: const Icon(Icons.clear),
  label: const Text(
    'Remove Class Teacher',
  ),
),


                // ── ASSIGNED CLASSES ──────────────
                const SizedBox(height: 36),

                _sectionTitle(
                  "Academic",
                  "Assigned Classes",
                ),

                const SizedBox(height: 20),




     Wrap(
  spacing: 10,
  runSpacing: 10,

  children: allClasses.map((cls) {

    final selected =
        assignedClasses.contains(cls);

    return GestureDetector(
      onTap: () {

        setState(() {
          if (selected) {
            assignedClasses.remove(cls);
          } else {
            assignedClasses.add(cls);
          }
        });
      },

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff5B5FEF)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color: selected
                ? const Color(0xff5B5FEF)
                : Colors.grey.shade300,
          ),
        ),

        child: Text(
          cls.replaceAll("_", " "),

          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

  }).toList(),
),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Attendance Permissions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),



Text(
  'Groups: ${attendanceGroups.length}',
),

Text(
  'Classes: ${attendanceClasses.length}',
),





                      const SizedBox(height: 12),

                      OutlinedButton.icon(
                        onPressed: () {
                          _showAttendancePermissionDialog();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text(
                          'Manage Attendance Access',
                        ),
                      ),
                    ],
                  ),
                ),




const SizedBox(height: 30),

_sectionTitle(
  "Academic",
  "Subjects",
),

const SizedBox(height: 16),

Wrap(
  spacing: 10,
  runSpacing: 10,
  children: subjects.map((subject) {

    return Chip(
      label: Text(subject),

      deleteIcon: const Icon(
        Icons.close,
        size: 18,
      ),

      onDeleted: () {

        setState(() {
          subjects.remove(subject);
        });
      },
    );

  }).toList(),
),



                // ── SAVE BUTTON ───────────────────
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton(
                    onPressed:
                        isSaving ? null : _save,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xff5B5FEF),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),

                    child: isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Save Changes",

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
