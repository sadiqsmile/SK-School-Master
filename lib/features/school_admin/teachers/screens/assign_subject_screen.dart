import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignSubjectScreen extends StatefulWidget {
  final String schoolId;
  final String teacherId;

  const AssignSubjectScreen({
    super.key,
    required this.schoolId,
    required this.teacherId,
  });

  @override
  State<AssignSubjectScreen> createState() => _AssignSubjectScreenState();
}

class _AssignSubjectScreenState extends State<AssignSubjectScreen> {
  List<String> subjects = [];
  List<String> selectedSubjects = [];
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('subjects')
        .get();

    final loaded = snapshot.docs
        .map((e) => (e.data()['name'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();

    setState(() {
      subjects = loaded;
      isLoading = false;
    });
  }

  Future<void> _save() async {
    if (selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one subject')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(widget.teacherId);

      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>;
      final existing = List<String>.from(data['subjects'] ?? []);

      final merged = {...existing, ...selectedSubjects}.toList()..sort();

      await docRef.update({
        'subjects': merged,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subjects assigned successfully ✅'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Assign Subjects',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xff111827)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Subjects',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to select one or more subjects this teacher teaches.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),
                  if (subjects.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'No subjects found.\nAdd subjects in Academic Setup first.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xff6B7280)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: subjects.map((subject) {
                          final isSelected = selectedSubjects.contains(subject);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedSubjects.remove(subject);
                                } else {
                                  selectedSubjects.add(subject);
                                }
                              });
                            },
                            child: AnimatedContainer(

  duration: const Duration(
    milliseconds: 180,
  ),

  padding:
      const EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 12,
  ),

  decoration: BoxDecoration(

    color: isSelected
        ? const Color(0xff5B5FEF)

        : [
            const Color(0xffEEF2FF),
            const Color(0xffECFDF5),
            const Color(0xffFEF3C7),
            const Color(0xffFCE7F3),
            const Color(0xffE0F2FE),
          ][
            subjects.indexOf(subject) % 5
          ],

    borderRadius:
        BorderRadius.circular(14),

    border: Border.all(

      color: isSelected
          ? const Color(0xff5B5FEF)
          : Colors.transparent,
    ),

    boxShadow: isSelected
        ? [

            const BoxShadow(

              color: Color(0x335B5FEF),

              blurRadius: 8,

              offset: Offset(0, 4),
            ),
          ]
        : [],
  ),

  child: Row(

    mainAxisSize:
        MainAxisSize.min,

    children: [

      if (isSelected) ...[

        const Icon(

          Icons.check_circle_rounded,

          size: 16,

          color: Colors.white,
        ),

        const SizedBox(width: 6),
      ],

      Text(

        subject.toUpperCase(),

        style: TextStyle(

          fontWeight:
              FontWeight.w700,

          color: isSelected
              ? Colors.white
              : const Color(
                  0xff374151,
                ),
        ),
      ),
    ],
  ),
),
                          
                          
                          
                          
                          
                          
                          
                          
                          
                          
                          );
                        }).toList(),
                      ),
                    ),
                  if (selectedSubjects.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${selectedSubjects.length} subject${selectedSubjects.length == 1 ? '' : 's'} selected',
                      style: const TextStyle(
                        color: Color(0xff5B5FEF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff5B5FEF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Subjects',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
