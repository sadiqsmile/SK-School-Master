import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class StudentIdCardScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final Map<String, dynamic> schoolData;
  final Map<String, dynamic> settings;

  const StudentIdCardScreen({
    super.key,
    required this.studentData,
    required this.schoolData,
    required this.settings,
  });

  @override
  State<StudentIdCardScreen> createState() => _StudentIdCardScreenState();
}

class _StudentIdCardScreenState extends State<StudentIdCardScreen> {
  final GlobalKey cardKey = GlobalKey();
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Student ID Card"),
        actions: [
          IconButton(
            onPressed: saving ? null : _saveCardAsImage,
            icon: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: RepaintBoundary(
            key: cardKey,
            child: Container(
              width: 360,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff5B5FEF),
                    Color(0xff7C3AED),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  if ((widget.schoolData['logoUrl'] ?? '').toString().isNotEmpty)
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(widget.schoolData['logoUrl']),
                    ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          widget.schoolData['schoolName'] ?? 'School Name',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "STUDENT ID CARD",
                          style: TextStyle(
                            letterSpacing: 2,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: const Color(0xffEEF2FF),
                          backgroundImage: (widget.studentData['photoUrl'] ?? '')
                                  .toString()
                                  .isNotEmpty
                              ? NetworkImage(widget.studentData['photoUrl'])
                              : null,
                          child: (widget.studentData['photoUrl'] ?? '')
                                  .toString()
                                  .isEmpty
                              ? Text(
                                  (widget.studentData['name'] ?? 'S')
                                      .toString()
                                      .substring(0, 1),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff5B5FEF),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.studentData['name'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${widget.studentData['className']} • Section ${widget.studentData['section']}",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _infoTile(
                          "Admission No",
                          widget.studentData['admissionNo'] ?? '-',
                          visible: widget.settings['showAdmissionNo'] ?? true,
                        ),
                        _infoTile(
                          "DOB",
                          widget.studentData['dob'] ?? '-',
                          visible: widget.settings['showDob'] ?? true,
                        ),
                        _infoTile(
                          "Blood Group",
                          widget.studentData['bloodGroup'] ?? '-',
                          visible: widget.settings['showBloodGroup'] ?? true,
                        ),
                        _infoTile(
                          "Phone",
                          widget.studentData['phone'] ?? '-',
                          visible: widget.settings['showPhone'] ?? false,
                        ),
                        _infoTile(
                          "Address",
                          widget.studentData['address'] ?? '-',
                          visible: widget.settings['showAddress'] ?? false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCardAsImage() async {
    try {
      setState(() {
        saving = true;
      });

      final boundary =
          cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3);

      final byteData = await image.toByteData(format: ImageByteFormat.png);

      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();

      final file = File('${dir.path}/student_id_card.png');

      await file.writeAsBytes(pngBytes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ID Card saved:\n${file.path}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Widget _infoTile(
    String title,
    String value, {
    required bool visible,
  }) {
    if (!visible) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xff111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
