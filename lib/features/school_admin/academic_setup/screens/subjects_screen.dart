import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/subject_service.dart';

class SubjectsScreen extends StatefulWidget {

  final String schoolId;

  const SubjectsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<SubjectsScreen> createState() =>
      _SubjectsScreenState();
}

class _SubjectsScreenState
    extends State<SubjectsScreen> {

  final SubjectService _service =
      SubjectService();

  final TextEditingController
      searchController =
          TextEditingController();

  String search = "";

  final List<String> groups = [
    "Nursery",
    "Primary",
    "Middle School",
    "High School",
    "College",
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title: const Text(
          "Subjects",
        ),

        elevation: 0,

        backgroundColor: Colors.white,
      ),

      floatingActionButton:
          FloatingActionButton.extended(

        backgroundColor:
            const Color(0xff5B5FEF),

        onPressed: () {
          _showAddSubjectSheet();
        },

        icon: const Icon(Icons.add),

        label: const Text(
          "Add Subject",
        ),
      ),

      body: Column(
        children: [

          Container(
            color: Colors.white,

            padding:
                const EdgeInsets.all(16),

            child: TextField(

              controller: searchController,

              onChanged: (v) {
                setState(() => search = v);
              },

              decoration: InputDecoration(

                hintText:
                    "Search subjects...",

                prefixIcon:
                    const Icon(Icons.search),

                filled: true,

                fillColor:
                    const Color(0xffF8FAFC),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),

                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child:
                StreamBuilder<QuerySnapshot>(

              stream:
                  _service.getSubjects(
                widget.schoolId,
              ),

              builder:
                  (context, snapshot) {

                if (!snapshot.hasData) {

                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final docs =
                    snapshot.data!.docs;

                final filtered =
                    docs.where((doc) {

                  final data =
                      doc.data()
                          as Map<String, dynamic>;

                  if (data['archived'] ==
                      true) {
                    return false;
                  }

                  final name =
                      (data['name'] ?? '')
                          .toString()
                          .toLowerCase();

                  return name.contains(
                    search.toLowerCase(),
                  );

                }).toList();

                if (filtered.isEmpty) {

                  return _emptyState();
                }

                return ListView.builder(

                  padding:
                      const EdgeInsets.all(16),

                  itemCount:
                      filtered.length,

                  itemBuilder:
                      (context, index) {

                    final doc =
                        filtered[index];

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    final subjectGroups =
                        List<String>.from(
                      data['groups'] ?? [],
                    );

                    return Container(

                      margin:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),

                      padding:
                          const EdgeInsets.all(
                        18,
                      ),

                      decoration: BoxDecoration(

                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                        border: Border.all(
                          color:
                              Colors.grey.shade100,
                        ),

                        boxShadow: [

                          BoxShadow(
                            color: Colors.black
                                .withOpacity(
                              0.02,
                            ),

                            blurRadius: 10,

                            offset:
                                const Offset(
                              0,
                              4,
                            ),
                          ),
                        ],
                      ),

                      child: Row(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Container(

                            height: 54,
                            width: 54,

                            decoration:
                                BoxDecoration(

                              color:
                                  const Color(
                                0xffEEF2FF,
                              ),

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),

                            child: Center(

                              child: Text(

                                data['shortName']
                                        ?.toString()
                                        .isEmpty ??
                                    true
                                    ? "SB"
                                    : data[
                                            'shortName']
                                        .toString()
                                        .substring(
                                          0,
                                          1,
                                        ),

                                style:
                                    const TextStyle(

                                  fontSize: 18,

                                  fontWeight:
                                      FontWeight
                                          .w700,

                                  color: Color(
                                    0xff5B5FEF,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 16,
                          ),

                          Expanded(
                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                Text(
                                  data['name'] ??
                                      '',

                                  style:
                                      const TextStyle(

                                    fontSize: 16,

                                    fontWeight:
                                        FontWeight
                                            .w600,

                                    color: Color(
                                      0xff111827,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(

                                  "${data['shortName']} • ${data['code']}",

                                  style:
                                      TextStyle(

                                    fontSize: 13,

                                    color:
                                        Colors.grey
                                            .shade600,
                                  ),
                                ),

                                const SizedBox(
                                  height: 14,
                                ),

                                Wrap(

                                  spacing: 8,
                                  runSpacing: 8,

                                  children:
                                      subjectGroups
                                          .map((g) {

                                    return Container(

                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal:
                                            10,
                                        vertical: 6,
                                      ),

                                      decoration:
                                          BoxDecoration(

                                        color:
                                            const Color(
                                          0xffF5F3FF,
                                        ),

                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          10,
                                        ),
                                      ),

                                      child: Text(

                                        g,

                                        style:
                                            const TextStyle(

                                          fontSize:
                                              12,

                                          fontWeight:
                                              FontWeight
                                                  .w500,

                                          color:
                                              Color(
                                            0xff5B5FEF,
                                          ),
                                        ),
                                      ),
                                    );

                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          PopupMenuButton(

                            itemBuilder:
                                (context) => [

                              PopupMenuItem(

                                onTap: () {

                                  Future.delayed(
                                    Duration.zero,

                                    () {

                                      _showAddSubjectSheet(
                                        editData:
                                            data,

                                        subjectId:
                                            doc.id,
                                      );
                                    },
                                  );
                                },

                                child: const Text(
                                  "Edit",
                                ),
                              ),

                              PopupMenuItem(

                                onTap: () {

                                  _service
                                      .archiveSubject(

                                    schoolId:
                                        widget
                                            .schoolId,

                                    subjectId:
                                        doc.id,
                                  );
                                },

                                child: const Text(
                                  "Archive",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {

    return Center(
      child: Column(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Container(

            height: 90,
            width: 90,

            decoration: const BoxDecoration(
              color: Color(
                0xffEEF2FF,
              ),

              shape: BoxShape.circle,
            ),

            child: const Icon(

              Icons.menu_book_rounded,

              size: 42,

              color: Color(0xff5B5FEF),
            ),
          ),

          const SizedBox(height: 20),

          const Text(

            "No Subjects Added",

            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),

          const SizedBox(height: 8),

          Text(

            "Add subjects to manage timetable,\nexams and teacher assignments.",

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

  void _showAddSubjectSheet({

    Map<String, dynamic>? editData,
    String? subjectId,

  }) {

    final bool isEdit =
        editData != null;

    final nameController =
        TextEditingController(
      text: editData?['name'] ?? '',
    );

    final shortNameController =
        TextEditingController(
      text: editData?['shortName'] ?? '',
    );

    final codeController =
        TextEditingController(
      text: editData?['code'] ?? '',
    );

    List<String> selectedGroups =
        List<String>.from(
      editData?['groups'] ?? [],
    );

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

                bottom:
                    MediaQuery.of(context)
                            .viewInsets
                            .bottom +
                        24,
              ),

              decoration: const BoxDecoration(

                color: Colors.white,

                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),

              child: SingleChildScrollView(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    Center(

                      child: Container(

                        height: 5,
                        width: 60,

                        decoration: BoxDecoration(

                          color: Colors.grey.shade300,

                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(

                      isEdit
                          ? "Edit Subject"
                          : "Add Subject",

                      style: const TextStyle(

                        fontSize: 22,

                        fontWeight:
                            FontWeight.w700,

                        color: Color(
                          0xff111827,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(

                      "Centralized academic subject configuration",

                      style: TextStyle(

                        fontSize: 13,

                        color:
                            Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 28),

                    _inputField(

                      controller:
                          nameController,

                      label: "Subject Name",

                      hint:
                          "Mathematics",

                      capitalization:
                          TextCapitalization
                              .characters,
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [

                        Expanded(
                          child: _inputField(

                            controller:
                                shortNameController,

                            label: "Short Name",

                            hint: "MATH",

                            capitalization:
                                TextCapitalization
                                    .characters,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: _inputField(

                            controller:
                                codeController,

                            label: "Code",

                            hint: "MAT101",

                            capitalization:
                                TextCapitalization
                                    .characters,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    const Text(

                      "Applicable Groups",

                      style: TextStyle(

                        fontSize: 15,

                        fontWeight:
                            FontWeight.w600,

                        color: Color(
                          0xff374151,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Wrap(

                      spacing: 10,
                      runSpacing: 10,

                      children:
                          groups.map((group) {

                        final selected =
                            selectedGroups
                                .contains(group);

                        return GestureDetector(

                          onTap: () {

                            setSheetState(() {

                              if (selected) {

                                selectedGroups
                                    .remove(group);

                              } else {

                                selectedGroups
                                    .add(group);
                              }
                            });
                          },

                          child: Container(

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),

                            decoration:
                                BoxDecoration(

                              color: selected
                                  ? const Color(
                                      0xff5B5FEF,
                                    )
                                  : Colors.white,

                              borderRadius:
                                  BorderRadius
                                      .circular(14),

                              border: Border.all(

                                color: selected
                                    ? const Color(
                                        0xff5B5FEF,
                                      )
                                    : Colors.grey
                                        .shade300,
                              ),
                            ),

                            child: Text(

                              group,

                              style: TextStyle(

                                fontWeight:
                                    FontWeight.w600,

                                color: selected
                                    ? Colors.white
                                    : Colors.black87,
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

                        style:
                            ElevatedButton
                                .styleFrom(

                          backgroundColor:
                              const Color(
                            0xff5B5FEF,
                          ),

                          shape:
                              RoundedRectangleBorder(

                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                        ),

                        onPressed: () async {

                          final name =
                              nameController.text
                                  .trim();

                          final shortName =
                              shortNameController
                                  .text
                                  .trim();

                          final code =
                              codeController.text
                                  .trim();

                          if (name.isEmpty ||
                              shortName.isEmpty ||
                              code.isEmpty ||
                              selectedGroups
                                  .isEmpty) {

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(

                              const SnackBar(
                                content: Text(
                                  "Fill all fields",
                                ),
                              ),
                            );

                            return;
                          }

                          if (isEdit) {

                            await _service
                                .updateSubject(

                              schoolId:
                                  widget.schoolId,

                              subjectId:
                                  subjectId!,

                              name: name,

                              shortName:
                                  shortName,

                              code: code,

                              groups:
                                  selectedGroups,
                            );

                          } else {

                            await _service
                                .addSubject(

                              schoolId:
                                  widget.schoolId,

                              name: name,

                              shortName:
                                  shortName,

                              code: code,

                              groups:
                                  selectedGroups,
                            );
                          }

                          if (!mounted) return;

                          Navigator.pop(context);
                        },

                        child: Text(

                          isEdit
                              ? "Update Subject"
                              : "Save Subject",

                          style: const TextStyle(

                            fontSize: 15,

                            fontWeight:
                                FontWeight.w600,

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

  Widget _inputField({

    required TextEditingController controller,

    required String label,
    required String hint,

    TextCapitalization capitalization =
        TextCapitalization.none,

  }) {

    return TextField(

      controller: controller,

      textCapitalization:
          capitalization,

      decoration: InputDecoration(

        labelText: label,

        hintText: hint,

        filled: true,

        fillColor:
            const Color(0xffF8FAFC),

        border: OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(16),

          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(16),

          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        focusedBorder:
            const OutlineInputBorder(

          borderRadius:
              BorderRadius.all(
            Radius.circular(16),
          ),

          borderSide: BorderSide(
            color: Color(0xff5B5FEF),
          ),
        ),
      ),
    );
  }
}
