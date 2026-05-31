import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateExamDialogV2
    extends ConsumerStatefulWidget {

  const CreateExamDialogV2({
    super.key,
  });

  @override
  ConsumerState<CreateExamDialogV2>
      createState() =>
          _CreateExamDialogV2State();
}

class _CreateExamDialogV2State
    extends ConsumerState<CreateExamDialogV2> {

final selectedGroups =
    <String>{};

final selectedClasses =
    <String>{};


  @override
  Widget build(
    BuildContext context,
  ) {

    return Dialog(

      insetPadding:
          const EdgeInsets.all(24),

      backgroundColor:
          Colors.transparent,

      child: Container(

       width: 1200,

        constraints:
            const BoxConstraints(
        maxWidth: 1200,
          maxHeight: 750,
        ),

        decoration:
            BoxDecoration(

          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            32,
          ),

          boxShadow: const [

            BoxShadow(
              blurRadius: 30,
              spreadRadius: 2,
              offset:
                  Offset(0, 10),
              color:
                  Color(
                0x14000000,
              ),
            ),
          ],
        ),

        child: Column(

          children: [

            _buildHeader(),

            const Divider(
              height: 1,
            ),

            Expanded(

              child: SingleChildScrollView(

                padding:
                    const EdgeInsets.all(
                  24,
                ),

                child: Column(

                  children: [

                    _buildStepIndicator(),

                    const SizedBox(
                      height: 24,
                    ),

                    _buildBasicInfoCard(),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildGroupsCard(),

                    const SizedBox(
                      height: 20,
                    ),






                    _buildClassesCard(),
                  ],
                ),
              ),
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

Widget _groupChip(
  String group,
) {

  final selected =
      selectedGroups.contains(
    group,
  );

  return FilterChip(

    label: Text(
      group,
    ),

    selected: selected,

    selectedColor:
        Colors.blue.shade100,

    backgroundColor:
        Colors.white,

    side: BorderSide(
      color:
          selected
              ? Colors.blue
              : Colors.grey.shade300,
    ),

    shape:
        RoundedRectangleBorder(
      borderRadius:
          BorderRadius.circular(
        30,
      ),
    ),

    onSelected: (value) {

      setState(() {

        if (value) {

          selectedGroups.add(
            group,
          );

        } else {

          selectedGroups.remove(
            group,
          );
        }
      });
    },
  );
}



  Widget _buildHeader() {

    return Padding(

      padding:
          const EdgeInsets.all(24),

      child: Row(

        children: [

          const Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Text(
                  'Create Exam',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  'Create a new examination',
                ),
              ],
            ),
          ),

          IconButton(

            onPressed: () {

              Navigator.pop(
                context,
              );
            },

            icon:
                const Icon(
              Icons.close,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {

    return Container(

      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        color:
            Colors.grey.shade50,
      ),

      child: const Row(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

        CircleAvatar(
  radius: 22,
  backgroundColor:
      const Color(
    0xFF6366F1,
  ),
  child: const Text(
    '1',
    style: TextStyle(
      color: Colors.white,
      fontWeight:
          FontWeight.bold,
    ),
  ),
),

          SizedBox(
            width: 12,
          ),

          Text(
            'Exam Details',
          ),

          SizedBox(
            width: 40,
          ),

         CircleAvatar(
  radius: 22,
  backgroundColor:
      const Color(
    0xFF6366F1,
  ),
  child: const Text(
    '2',
    style: TextStyle(
      color: Colors.white,
      fontWeight:
          FontWeight.bold,
    ),
  ),
),


          SizedBox(
            width: 12,
          ),

          Text(
            'Subjects',
          ),

          SizedBox(
            width: 40,
          ),

          CircleAvatar(
  radius: 22,
  backgroundColor:
      const Color(
    0xFF6366F1,
  ),
  child: const Text(
    '3',
    style: TextStyle(
      color: Colors.white,
      fontWeight:
          FontWeight.bold,
    ),
  ),
),

          SizedBox(
            width: 12,
          ),

          Text(
            'Review',
          ),
        ],
      ),
    );
  }

Widget _buildBasicInfoCard() {

  return Container(

    padding:
        const EdgeInsets.all(24),

    decoration:
        BoxDecoration(

      borderRadius:
          BorderRadius.circular(
        24,
      ),

     color:
    Colors.white,
boxShadow: [

  BoxShadow(
    color: Colors.black
        .withOpacity(0.05),
    blurRadius: 20,
    offset:
        const Offset(0, 8),
  ),
],

    ),

    child: Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        const Text(
          'Exam Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        Row(

          children: [

            Expanded(

              child:
                  TextFormField(

                decoration:
                    InputDecoration(

                  labelText:
                      'Exam Name',

                  prefixIcon:
                      const Icon(
                    Icons.description,
                  ),

                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(

              child:
                  TextFormField(

                keyboardType:
                    TextInputType.number,

                decoration:
                    InputDecoration(

                  labelText:
                      'Max Marks',

                  prefixIcon:
                      const Icon(
                    Icons.star,
                  ),

                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(

              child:
                  DropdownButtonFormField<
                      String>(

                value:
                    'A1 A2 B1 B2 C1 C2 D E',

                decoration:
                    InputDecoration(

                  labelText:
                      'Grade Pattern',

                  prefixIcon:
                      const Icon(
                    Icons.workspace_premium,
                  ),

                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                items: const [

                  DropdownMenuItem(
                    value:
                        'A1 A2 B1 B2 C1 C2 D E',
                    child: Text(
                      'A1 A2 B1 B2 C1 C2 D E',
                    ),
                  ),

                  DropdownMenuItem(
                    value:
                        'A+ A B+ B C+ C D E',
                    child: Text(
                      'A+ A B+ B C+ C D E',
                    ),
                  ),
                ],

                onChanged:
                    (value) {},
              ),
            ),
          ],
        ),
      ],
    ),
  );
}





  Widget _buildGroupsCard() {

  return Container(

    padding:
        const EdgeInsets.all(24),

    decoration:
        BoxDecoration(

      borderRadius:
          BorderRadius.circular(
        24,
      ),

      color:
    Colors.white,

boxShadow: [

  BoxShadow(
    color: Colors.black
        .withOpacity(0.05),
    blurRadius: 20,
    offset:
        const Offset(0, 8),
  ),
],
    ),

    child: Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        const Text(
          'Applicable Groups',
          style: TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        Wrap(

          spacing: 12,
          runSpacing: 12,

          children: [

            _groupChip(
              'Primary',
            ),

            _groupChip(
              'Middle',
            ),

            _groupChip(
              'High School',
            ),

            _groupChip(
              'College',
            ),
          ],
        ),
      ],
    ),
  );
}


Widget _buildClassesCard() {

  final classes = [

    'LKG',
    'UKG',

    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',

    'Class 6',
    'Class 7',
    'Class 8',

    'Class 9',
    'Class 10',

    'I-PU',
    'II-PU',
  ];

  return Container(

    padding:
        const EdgeInsets.all(24),

    decoration:
        BoxDecoration(

      borderRadius:
          BorderRadius.circular(
        24,
      ),

      color:
    Colors.white,

boxShadow: [

  BoxShadow(
    color: Colors.black
        .withOpacity(0.05),
    blurRadius: 20,
    offset:
        const Offset(0, 8),
  ),
],
    ),

    child: Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Row(

          children: [

            const Text(
              'Classes',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const Spacer(),

            FilterChip(

              label: const Text(
                'Select All',
              ),

              selected:
                  selectedClasses
                          .length ==
                      classes.length,

              onSelected:
                  (value) {

                setState(() {

                  if (value) {

                    selectedClasses
                        .clear();

                    selectedClasses
                        .addAll(
                      classes,
                    );

                  } else {

                    selectedClasses
                        .clear();
                  }
                });
              },
            ),
          ],
        ),

        const SizedBox(
          height: 20,
        ),

        Wrap(

          spacing: 12,
          runSpacing: 12,

          children: classes
              .map(
                (className) {

              final selected =
                  selectedClasses
                      .contains(
                className,
              );

              return FilterChip(

                label: Text(
                  className,
                ),

                selected:
                    selected,

                selectedColor:
                    Colors
                        .blue
                        .shade100,

                onSelected:
                    (value) {

                  setState(() {

                    if (value) {

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
            },
          ).toList(),
        ),
      ],
    ),
  );
}



Widget _buildFooter() {

  return Container(

    padding:
        const EdgeInsets.all(24),

    child: Row(

      children: [

        OutlinedButton.icon(

          onPressed: () {

            Navigator.pop(
              context,
            );
          },

          icon: const Icon(
            Icons.arrow_back,
          ),

          label: const Text(
            'Cancel',
          ),
        ),

        const Spacer(),

        ElevatedButton.icon(

          style:
              ElevatedButton.styleFrom(

            backgroundColor:
                const Color(
              0xFF6366F1,
            ),

            foregroundColor:
                Colors.white,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),

            shape:
                RoundedRectangleBorder(

              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
          ),

          onPressed: () {},

          icon: const Icon(
            Icons.arrow_forward,
          ),

          label: const Text(
            'Continue',
          ),
        ),
      ],
    ),
  );
}
    }
    
