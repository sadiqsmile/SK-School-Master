import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_app/providers/current_school_provider.dart';
import '../providers/exam_names_provider.dart';
import '../providers/classes_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:ui';


class CreateExamDialog
    extends ConsumerStatefulWidget {


  const CreateExamDialog({super.key});

  @override
  ConsumerState<CreateExamDialog> createState() =>
      _CreateExamDialogState();
}

class _CreateExamDialogState
    extends ConsumerState<CreateExamDialog> {

final selectedGroups = <String>{};

final selectedClasses =
    <String>{};



  String? selectedExamName;

  final maxMarksController =
      TextEditingController(
    text: '',
  );

  String gradePattern =
      'A1 A2 B1 B2 C1 C2 D E';

  @override
  Widget build(BuildContext context) {

final schoolAsync =
    ref.watch(
      currentSchoolProvider,
    );



    return AlertDialog(

      title: const Text(
        'Create Exam',
      ),

      content: SizedBox(
        width: 500,

        child: SingleChildScrollView(

          child: Column(

            mainAxisSize:
                MainAxisSize.min,

            children: [





     schoolAsync.when(

  data: (school) {

    final examNamesAsync =
        ref.watch(
      examNamesProvider(
        school.id,
      ),
    );

    return examNamesAsync.when(

      data: (docs) {

        return 
        DropdownButtonFormField<String>(
          value:selectedExamName,
          decoration:
              const InputDecoration(
            labelText:
                'Exam Name',
          ),

          items: docs.map((doc) {

            final data =
                doc.data();

   final examName =
    (data['name'] ?? '')
        .toString();

return DropdownMenuItem<String>(

  
  value: examName,
  child: Text(
    examName,

    
  ),
);


          }).toList(),
   
onChanged: (value) {

  setState(() {

    selectedExamName = value;
  });
}

        );
      },

      loading: () =>
          const CircularProgressIndicator(),

      error: (e, _) =>
          Text(
        e.toString(),
      ),
    );
  },

  loading: () =>
      const CircularProgressIndicator(),

  error: (e, _) =>
      Text(
    e.toString(),
  ),
),

              const SizedBox(
                height: 16,
              ),


           TextFormField(
  controller:
      maxMarksController,

  keyboardType:
      TextInputType.number,

  maxLength: 3,

  inputFormatters: [
    FilteringTextInputFormatter
        .digitsOnly,
  ],

  decoration:
      const InputDecoration(
    labelText: 'Max Marks',
    
    counterText: '',
  ),
),



              const SizedBox(
                height: 16,
              ),




DropdownButtonFormField<String>(
  value: gradePattern,

  decoration: const InputDecoration(
    labelText: 'Grade Pattern',
  ),
  items: const [
    DropdownMenuItem(
      value: 'A1 A2 B1 B2 C1 C2 D E',
      child: Text('A1 A2 B1 B2 C1 C2 D E'),
    ),
    DropdownMenuItem(
      value: 'A+ A B+ B C+ C D E',
      child: Text('A+ A B+ B C+ C D E'),
    ),
    DropdownMenuItem(
      value: 'A B C D E',
      child: Text('A B C D E'),
    ),
    DropdownMenuItem(
      value: 'MANUAL',
      child: Text('Manual Entry'),
    ),
  ],
  onChanged: (value) {
    setState(() {
      gradePattern = value!;
    });
  },
),

const SizedBox(
  height: 16,
),




const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    'Groups',
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
),

CheckboxListTile(
  title: const Text('Primary'),
  value: selectedGroups.contains('Primary'),
  onChanged: (value) {
    setState(() {
      if (value == true) {
        selectedGroups.add('Primary');
      } else {
        selectedGroups.remove('Primary');
      }
    });
  },
),

CheckboxListTile(
  title: const Text('Middle'),
  value: selectedGroups.contains('Middle'),
  onChanged: (value) {
    setState(() {
      if (value == true) {
        selectedGroups.add('Middle');
      } else {
        selectedGroups.remove('Middle');
      }
    });
  },
),

CheckboxListTile(
  title: const Text('High School'),
  value: selectedGroups.contains('High School'),
  onChanged: (value) {
    setState(() {
      if (value == true) {
        selectedGroups.add('High School');
      } else {
        selectedGroups.remove('High School');
      }
    });
  },
),

CheckboxListTile(
  title: const Text('College'),
  value: selectedGroups.contains('College'),
  onChanged: (value) {
    setState(() {
      if (value == true) {
        selectedGroups.add('College');
      } else {
        selectedGroups.remove('College');
      }
    });
  },
),

if (selectedGroups.isNotEmpty)




  if (selectedGroups.isNotEmpty)

  FutureBuilder(

    future: FirebaseFirestore.instance
        .collection('schools')
        .doc(
          schoolAsync.value!.id,
        )
        .collection('classes')
        .get(),

    builder: (
      context,
      snapshot,
    ) {

      if (!snapshot.hasData) {
        return const CircularProgressIndicator();
      }

      final docs =
          snapshot.data!.docs
              .where((doc) {

print(
  'Selected Groups: $selectedGroups',
);

print(doc.data());
        final data =
            doc.data();

print(data);


     final group =
    data['group']
        ?.toString();

        return selectedGroups
            .contains(group);
      }).toList();

docs.sort((a, b) {

  final nameA =
      a['name']
          .toString();

  final nameB =
      b['name']
          .toString();

  int getOrder(
      String name) {

    switch (name) {

      case 'LKG':
        return 1;

      case 'UKG':
        return 2;

      case 'Class 1':
        return 3;

      case 'Class 2':
        return 4;

      case 'Class 3':
        return 5;

      case 'Class 4':
        return 6;

      case 'Class 5':
        return 7;

      case 'Class 6':
        return 8;

      case 'Class 7':
        return 9;

      case 'Class 8':
        return 10;

      case 'Class 9':
        return 11;

      case 'Class 10':
        return 12;

      case 'I-PU':
        return 13;

      case 'II-PU':
        return 14;

      default:
        return 999;
    }
  }

  return getOrder(nameA)
      .compareTo(
    getOrder(nameB),
  );
});
      print(
  'Classes Found: ${docs.length}',
);

      return Column(

        children: [

          const Divider(),

CheckboxListTile(
  title: const Text(
    'Select All Classes',
  ),

  value: docs.isNotEmpty &&
      selectedClasses.length ==
          docs.length,

  onChanged: (value) {

    setState(() {

      if (value == true) {

        selectedClasses.clear();

        for (final doc in docs) {

          selectedClasses.add(
            doc['name']
                .toString(),
          );
        }

      } else {

        selectedClasses.clear();
      }
    });
  },
),


          const Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              'Classes',





              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          ...docs.map((doc) {

            final className =
                doc['name']
                    .toString();

            return CheckboxListTile(

              dense: true,

              title: Text(
                className,
              ),

              value:
                  selectedClasses
                      .contains(
                className,
              ),

              onChanged:
                  (checked) {

                setState(() {

                  if (checked ==
                      true) {

                    selectedClasses
                        .add(
                      className,
                    );

                  } else {

                    selectedClasses
                        .remove(
                      className,
                    );
                  }
                });
              },
            );
          }),
        ],
      );
    },
  ),
            ],
          ),
        ),
      ),

      actions: [

        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
          child: const Text(
            'Cancel',
          ),
        ),

   ElevatedButton(
  onPressed: () {

    if (selectedExamName == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Select Exam Name',
          ),
        ),
      );

      return;
    }

    if (maxMarksController.text
        .trim()
        .isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Enter Max Marks',
          ),
        ),
      );

      return;
    }

    if (selectedGroups.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Select At Least One Group',
          ),
        ),
      );

      return;
    }

    if (selectedClasses.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Select At Least One Class',
          ),
        ),
      );

      return;
    }

    print(
      'VALIDATION PASSED',
    );
  },

  child: const Text(
    'Next',
  ),
),



      ],
    );
  }
}




