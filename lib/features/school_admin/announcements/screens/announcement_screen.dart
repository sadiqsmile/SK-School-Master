import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../announcements/services/announcement_service.dart';

class AnnouncementScreen extends StatefulWidget {
  final String schoolId;

  const AnnouncementScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final AnnouncementService _service = AnnouncementService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text("Announcements"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff5B5FEF),
        onPressed: _showAddAnnouncementSheet,
        icon: const Icon(Icons.add),
        label: const Text("Add Notice"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getAnnouncements(widget.schoolId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final priority = data['priority'];

              Color badgeColor = const Color(0xffDBEAFE);
              if (priority == "High") badgeColor = const Color(0xffFEE2E2);
              if (priority == "Medium") badgeColor = const Color(0xffFEF3C7);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                        Expanded(
                          child: Text(
                            data['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff111827),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _service.deleteAnnouncement(
                              schoolId: widget.schoolId,
                              announcementId: doc.id,
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      data['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            priority ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ...(List<String>.from(
                          data['targetRoles'] ?? [],
                        ).map((role) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffEEF2FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xff5B5FEF),
                              ),
                            ),
                          );
                        }).toList()),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddAnnouncementSheet() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String priority = "Low";
    final List<String> selectedRoles = [];
    final roles = ["parent", "teacher", "student"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Create Announcement",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: titleController,
                      decoration: _inputDecoration("Title"),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: descriptionController,
                      maxLines: 5,
                      decoration: _inputDecoration("Description"),
                    ),
                    const SizedBox(height: 22),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: _inputDecoration("Priority"),
                      items: ["Low", "Medium", "High"].map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setSheetState(() {
                          priority = v;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Target Roles",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: roles.map((role) {
                        final isSelected = selectedRoles.contains(role);
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              if (isSelected) {
                                selectedRoles.remove(role);
                              } else {
                                selectedRoles.add(role);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xff5B5FEF)
                                  : const Color(0xffEEF2FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xff5B5FEF),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff5B5FEF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          await _service.addAnnouncement(
                            schoolId: widget.schoolId,
                            data: {
                              "title": titleController.text.trim(),
                              "description": descriptionController.text.trim(),
                              "priority": priority,
                              "targetRoles": selectedRoles,
                              "createdBy": "Admin",
                            },
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Publish Notice",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 90,
            width: 90,
            decoration: const BoxDecoration(
              color: Color(0xffEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_outlined,
              size: 42,
              color: Color(0xff5B5FEF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Announcements",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Announcements published by school\nwill appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
