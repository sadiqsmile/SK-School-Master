import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PromotionScreen extends StatefulWidget {
  final String schoolId;

  const PromotionScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  QueryDocumentSnapshot? selectedCurrentClass;
  QueryDocumentSnapshot? selectedTargetClass;
  String? targetSection;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text("Student Promotion"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('classes')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final classDocs = snapshot.data!.docs;

            return ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Promotion Setup",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<QueryDocumentSnapshot>(
                        value: selectedCurrentClass,
                        decoration: _inputDecoration("Current Class"),
                        items: classDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc,
                            child: Text(data['className']),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedCurrentClass = v;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<QueryDocumentSnapshot>(
                        value: selectedTargetClass,
                        decoration: _inputDecoration("Promote To"),
                        items: classDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc,
                            child: Text(data['className']),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedTargetClass = v;
                            targetSection = null;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      if (selectedTargetClass != null)
                        DropdownButtonFormField<String>(
                          value: targetSection,
                          decoration: _inputDecoration("Target Section"),
                          items: List<String>.from(
                            (selectedTargetClass!.data()
                                    as Map<String, dynamic>)['sections'] ??
                                [],
                          ).map((section) {
                            return DropdownMenuItem(
                              value: section,
                              child: Text(section),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              targetSection = v;
                            });
                          },
                        ),
                      const SizedBox(height: 34),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff5B5FEF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: loading ? null : _promoteStudents,
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Promote Students",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (selectedCurrentClass != null) _studentPreviewCard(),
              ],
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xffF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _studentPreviewCard() {
    final currentClassData =
        selectedCurrentClass!.data() as Map<String, dynamic>;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('classId', isEqualTo: currentClassData['classId'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Students To Promote",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      docs.length.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xff5B5FEF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...docs.take(10).map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xffEEF2FF),
                        child: Text(
                          (data['name'] ?? 'S').toString().substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xff5B5FEF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          data['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promoteStudents() async {
    if (selectedCurrentClass == null ||
        selectedTargetClass == null ||
        targetSection == null) {
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final currentClassData =
          selectedCurrentClass!.data() as Map<String, dynamic>;

      final targetClassData =
          selectedTargetClass!.data() as Map<String, dynamic>;

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('classId', isEqualTo: currentClassData['classId'])
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in studentsSnapshot.docs) {
        final data = doc.data();

        final history = List<Map<String, dynamic>>.from(
          data['academicHistory'] ?? [],
        );

        history.add({
          "year": "2025-26",
          "className": data['className'],
          "section": data['section'],
        });

        batch.update(doc.reference, {
          "classId": targetClassData['classId'],
          "className": targetClassData['className'],
          "section": targetSection,
          "academicHistory": history,
        });
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Students promoted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }
}
