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

  List<String> assignedClasses = [];

  bool isSaving = false;

  final List<String> allClasses = [
    for (int i = 1; i <= 12; i++)
      for (String s in ["A", "B", "C", "D"])
        "${i}_$s",
  ];

  @override
  void initState() {
    super.initState();

    final d = widget.data;

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

  Future<void> _save() async {

    setState(() => isSaving = true);

    try {

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(widget.teacherId)
          .update({

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

                        items: List.generate(12, (i) {

                          final c = (i + 1).toString();

                          return DropdownMenuItem(
                            value: c,
                            child: Text("Class $c"),
                          );

                        }),

                        onChanged: (v) {
                          setState(
                            () => classTeacherClass = v,
                          );
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

                        items: ["A", "B", "C", "D"]
                            .map((e) {

                          return DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          );

                        }).toList(),

                        onChanged: (v) {
                          setState(
                            () =>
                                classTeacherSection = v,
                          );
                        },
                      ),
                    ),
                  ],
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
