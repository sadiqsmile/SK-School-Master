import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../homework/services/homework_submission_service.dart';

class HomeworkSubmissionScreen extends StatefulWidget {
  final String schoolId;
  final String homeworkId;
  final String studentId;
  final String studentName;

  const HomeworkSubmissionScreen({
    super.key,
    required this.schoolId,
    required this.homeworkId,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<HomeworkSubmissionScreen> createState() =>
      _HomeworkSubmissionScreenState();
}

class _HomeworkSubmissionScreenState extends State<HomeworkSubmissionScreen> {
  final HomeworkSubmissionService _service = HomeworkSubmissionService();

  final noteController = TextEditingController();

  File? selectedFile;

  bool loading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null) return;

    setState(() {
      selectedFile = File(result.files.single.path!);
    });
  }

  Future<void> _submitHomework() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a file")),
      );
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final fileName =
          "${widget.studentId}_${DateTime.now().millisecondsSinceEpoch}";

      final fileUrl = await _service.uploadFile(
        file: selectedFile!,
        fileName: fileName,
      );

      await _service.submitHomework(
        schoolId: widget.schoolId,
        data: {
          "homeworkId": widget.homeworkId,
          "studentId": widget.studentId,
          "studentName": widget.studentName,
          "fileUrl": fileUrl,
          "note": noteController.text.trim(),
          "status": "Submitted",
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Homework submitted successfully")),
      );

      Navigator.pop(context);
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

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Submit Homework"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xffF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.upload_file,
                              size: 48,
                              color: Color(0xff5B5FEF),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              selectedFile == null
                                  ? "Tap to Upload File"
                                  : selectedFile!.path.split('/').last,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Add Note (Optional)",
                      filled: true,
                      fillColor: const Color(0xffF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
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
                      onPressed: loading ? null : _submitHomework,
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Submit Homework",
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
          ],
        ),
      ),
    );
  }
}
