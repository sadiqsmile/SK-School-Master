import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
 
Future<void> _deleteClass(
  String classId,
) async {

  final schoolId =
      ref.read(
        currentSchoolProvider,
      ).value!.id;

  final classDoc =
      await FirebaseFirestore
          .instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .get();

  final data =
      classDoc.data() ?? {};

  final studentCount =
      data['studentCount'] ?? 0;

  if (studentCount > 0) {

    if (mounted) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            'Cannot delete class with students',
          ),
        ),
      );
    }

    return;
  }

  await FirebaseFirestore.instance
      .collection('schools')
      .doc(schoolId)
      .collection('classes')
      .doc(classId)
      .delete();
}




Future<void> _showEditClassDialog(
  String classId,
  Map<String, dynamic> data,
) async {

  final nameController =
      TextEditingController(
    text: data['name'] ?? '',
  );

  List<String> sections =
      List<String>.from(
    data['sections'] ?? [],
  );

  final sectionController =
      TextEditingController();

  String selectedGroupId =
      data['groupId'] ?? '';

  String selectedGroupName =
      data['groupName'] ?? '';

  final schoolId =
      ref.read(
        currentSchoolProvider,
      ).value!.id;

  await showDialog(

    context: context,

    builder: (dialogContext) {

      return StatefulBuilder(

        builder: (
          context,
          setDialogState,
        ) {

          return AlertDialog(

            title: const Text(
              'Edit Class',
            ),

            content:
                SingleChildScrollView(

              child: SizedBox(

                width: 450,

                child: Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    StreamBuilder<
                        QuerySnapshot>(

                      stream:
                          FirebaseFirestore
                              .instance
                              .collection(
                                'schools',
                              )
                              .doc(
                                schoolId,
                              )
                              .collection(
                                'groups',
                              )
                              .orderBy(
                                'order',
                              )
                              .snapshots(),

                      builder: (
                        context,
                        snapshot,
                      ) {

                        if (!snapshot
                            .hasData) {

                          return const SizedBox();
                        }

                        final groups =
                            snapshot
                                .data!
                                .docs;

                        return DropdownButtonFormField<
                            String>(

                          value:
                              selectedGroupId,

                          decoration:
                              const InputDecoration(
                            labelText:
                                'Group',
                          ),

                          items:
                              groups.map(
                            (doc) {

                              final g =
                                  doc.data()
                                      as Map<String, dynamic>;

                              return DropdownMenuItem<
                                  String>(

                                value:
                                    doc.id,

                                child:
                                    Text(
                                  g['name'] ??
                                      '',
                                ),
                              );
                            },
                          ).toList(),

                          onChanged:
                              (value) {

                            final group =
                                groups.firstWhere(
                              (
                                e,
                              ) =>
                                  e.id ==
                                  value,
                            );

                            final g =
                                group.data()
                                    as Map<String, dynamic>;

                            setDialogState(
                              () {

                                selectedGroupId =
                                    value!;

                                selectedGroupName =
                                    g['name'];
                              },
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(

                      controller:
                          nameController,

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Class Name',
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Wrap(

                      spacing: 8,

                      runSpacing: 8,

                      children:
                          sections.map(
                        (
                          section,
                        ) {

                          return Chip(

                            label:
                                Text(
                              section,
                            ),

                            onDeleted:
                                () {

                              setDialogState(
                                () {

                                  sections.remove(
                                    section,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Row(

                      children: [

                        Expanded(

                          child:
                              TextField(

                            controller:
                                sectionController,

                            decoration:
                                const InputDecoration(
                              labelText:
                                  'Section',
                            ),
                          ),
                        ),

                        IconButton(

                          onPressed:
                              () {

                            final section =
                                sectionController
                                    .text
                                    .trim()
                                    .toUpperCase();

                            if (section
                                .isEmpty) {
                              return;
                            }

                            if (sections
                                .contains(
                              section,
                            )) {
                              return;
                            }

                            setDialogState(
                              () {

                                sections.add(
                                  section,
                                );

                                sectionController
                                    .clear();
                              },
                            );
                          },

                          icon:
                              const Icon(
                            Icons.add,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            actions: [

              TextButton(

                onPressed: () {

                  Navigator.pop(
                    dialogContext,
                  );
                },

                child: const Text(
                  'Cancel',
                ),
              ),

              ElevatedButton(

                onPressed: () async {

                  await FirebaseFirestore
                      .instance
                      .collection(
                        'schools',
                      )
                      .doc(
                        schoolId,
                      )
                      .collection(
                        'classes',
                      )
                      .doc(
                        classId,
                      )
                      .update({

                    'name':
                        nameController
                            .text
                            .trim(),

                    'searchName':
                        nameController
                            .text
                            .trim()
                            .toLowerCase(),

                    'groupId':
                        selectedGroupId,

                    'groupName':
                        selectedGroupName,

                    'sections':
                        sections,
                  });

                  if (mounted) {

                    Navigator.pop(
                      dialogContext,
                    );
                  }
                },

                child: const Text(
                  'Save',
                ),
              ),
            ],
          );
        },
      );
    },
  );
}




Future<void> _showManageGroupsDialog() async {

  final schoolId =
      ref.read(
        currentSchoolProvider,
      ).value!.id;

  await showDialog(

    context: context,

    builder: (_) {

      return AlertDialog(

        title: const Text(
          'Manage Groups',
        ),

        content: SizedBox(

          width: 500,

          child: StreamBuilder<
              QuerySnapshot>(

            stream:
                FirebaseFirestore
                    .instance
                    .collection(
                      'schools',
                    )
                    .doc(
                      schoolId,
                    )
                    .collection(
                      'groups',
                    )
                    .orderBy(
                      'order',
                    )
                    .snapshots(),

            builder: (
              context,
              snapshot,
            ) {

              if (!snapshot
                  .hasData) {

                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final docs =
                  snapshot
                      .data!
                      .docs;

              return ListView.builder(

                shrinkWrap: true,

                itemCount:
                    docs.length,

                itemBuilder:
                    (
                  context,
                  index,
                ) {

                  final data =
                      docs[index]
                          .data()
                          as Map<String,
                              dynamic>;

                  return ListTile(

                    title: Text(
                      data['name'] ??
                          '',
                    ),

                    trailing:
                        PopupMenuButton<
                            String>(

                      onSelected:
                          (
                        value,
                      ) async {

                        final docId =
                            docs[index]
                                .id;

                        if (value ==
                            'delete') {

                          await FirebaseFirestore
                              .instance
                              .collection(
                                'schools',
                              )
                              .doc(
                                schoolId,
                              )
                              .collection(
                                'groups',
                              )
                              .doc(
                                docId,
                              )
                              .delete();
                        }

                        if (value ==
                            'edit') {

                          final controller =
                              TextEditingController(
                            text:
                                data['name'],
                          );

                          final result =
                              await showDialog<
                                  String>(

                            context:
                                context,

                            builder:
                                (_) {

                              return AlertDialog(

                                title:
                                    const Text(
                                  'Edit Group',
                                ),

                                content:
                                    TextField(
                                  controller:
                                      controller,
                                ),

                                actions: [

                                  TextButton(

                                    onPressed:
                                        () {

                                      Navigator.pop(
                                        context,
                                      );
                                    },

                                    child:
                                        const Text(
                                      'Cancel',
                                    ),
                                  ),

                                  ElevatedButton(

                                    onPressed:
                                        () {

                                      Navigator.pop(
                                        context,
                                        controller
                                            .text
                                            .trim(),
                                      );
                                    },

                                    child:
                                        const Text(
                                      'Save',
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (result !=
                                  null &&
                              result
                                  .isNotEmpty) {

                            await FirebaseFirestore
                                .instance
                                .collection(
                                  'schools',
                                )
                                .doc(
                                  schoolId,
                                )
                                .collection(
                                  'groups',
                                )
                                .doc(
                                  docId,
                                )
                                .update({

                              'name':
                                  result,

                              'searchName':
                                  result
                                      .toLowerCase(),
                            });
                          }
                        }
                      },

                      itemBuilder:
                          (_) => [

                        const PopupMenuItem(
                          value:
                              'edit',
                          child:
                              Text(
                            'Edit',
                          ),
                        ),

                        const PopupMenuItem(
                          value:
                              'delete',
                          child:
                              Text(
                            'Delete',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        actions: [

          ElevatedButton.icon(

            onPressed: () async {

              final controller =
                  TextEditingController();

              final result =
                  await showDialog<
                      String>(

                context: context,

                builder: (_) {

                  return AlertDialog(

                    title:
                        const Text(
                      'Add Group',
                    ),

                    content:
                        TextField(
                      controller:
                          controller,
                    ),

                    actions: [

                      TextButton(

                        onPressed:
                            () {

                          Navigator.pop(
                            context,
                          );
                        },

                        child:
                            const Text(
                          'Cancel',
                        ),
                      ),

                      ElevatedButton(

                        onPressed:
                            () {

                          Navigator.pop(
                            context,
                            controller
                                .text
                                .trim(),
                          );
                        },

                        child:
                            const Text(
                          'Save',
                        ),
                      ),
                    ],
                  );
                },
              );

              if (result != null &&
                  result.isNotEmpty) {

                await FirebaseFirestore
                    .instance
                    .collection(
                      'schools',
                    )
                    .doc(
                      schoolId,
                    )
                    .collection(
                      'groups',
                    )
                    .add({

                  'name': result,

                  'searchName':
                      result
                          .toLowerCase(),

                  'order':
                      DateTime.now()
                          .millisecondsSinceEpoch,

                  'isActive':
                      true,
                });
              }
            },

            icon: const Icon(
              Icons.add,
            ),

            label: const Text(
              'Add Group',
            ),
          ),

          TextButton(

            onPressed: () {

              Navigator.pop(
                context,
              );
            },

            child: const Text(
              'Close',
            ),
          ),
        ],
      );
    },
  );
}


  Future<void> _showDeleteDialog(String classId) async {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xffFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xffDC2626),
                ),
              ),
              const SizedBox(width: 14),
              const Text("Delete Class"),
            ],
          ),


       content: const Text(
  "Delete this class?\n\n"
  "Classes containing students "
  "cannot be deleted.",
),


          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteClass(classId);
              },
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return AdminLayout(
  title: 'Classes',



 

      body: schoolAsync.when(
        data: (school) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(school.id)
                .collection('classes')
                .orderBy('order')
                .snapshots(),
            
            
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;



           if (docs.isEmpty) {

  return Center(
    child: Column(

      mainAxisAlignment:
          MainAxisAlignment.center,

      children: [

        ElevatedButton.icon(

          onPressed: () {
            _showManageGroupsDialog();
          },

          icon: const Icon(
            Icons.settings,
          ),

          label: const Text(
            'Manage Groups',
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        ElevatedButton.icon(

          onPressed: () {
            context.push(
              '/add-class',
            );
          },

          icon: const Icon(
            Icons.add,
          ),

          label: const Text(
            'Add Class',
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        const Text(
          "No classes added",
        ),
      ],
    ),
  );
}







             return Column(
  children: [

    Padding(
      padding: const EdgeInsets.all(16),
      child: Row(

        mainAxisAlignment:
            MainAxisAlignment.end,

        children: [

          ElevatedButton.icon(

            onPressed: () {
              _showManageGroupsDialog();
            },

            icon: const Icon(
              Icons.settings,
            ),

            label: const Text(
              'Manage Groups',
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          ElevatedButton.icon(

            onPressed: () {
              context.push(
                '/add-class',
              );
            },

            icon: const Icon(
              Icons.add,
            ),

            label: const Text(
              'Add Class',
            ),
          ),
        ],
      ),
    ),

    Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final name = data['name'] ?? '';
                  final group =
    data['groupName'] ?? '';
                  final sections =
                      List<String>.from(data['sections'] ?? []);

                  return GestureDetector(
                    onTap: () {
                      context.push('/class-students', extra: {
                        'className': name,
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xffEEF2FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Color(0xff5B5FEF),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Unknown Class',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff111827),
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  group,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: sections.map((section) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffF3F4F6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        section,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Delete button
                          
                    PopupMenuButton<String>(

  onSelected: (value) {

    if (value == 'delete') {

      _showDeleteDialog(doc.id);
    }

    if (value == 'edit') {

      _showEditClassDialog(
        doc.id,
        data,
      );
    }
  },

  itemBuilder: (_) => [

    const PopupMenuItem(
      value: 'edit',
      child: Text(
        'Edit',
      ),
    ),

    const PopupMenuItem(
      value: 'delete',
      child: Text(
        'Delete',
      ),
    ),
  ],
),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },

                      

          );
        },

        loading: () =>
            const Center(
              child: CircularProgressIndicator(),
            ),

        error: (e, _) =>
            Center(
              child: Text(
                "Error: $e",
              ),
            ),
      ),


      /// ➕ ADD BUTTON
   floatingActionButton: FloatingActionButton.extended(
  onPressed: () => context.push('/add-class'),
  icon: const Icon(Icons.add),
  label: const Text("Add Class"),
),
    );
  }
}