import 'package:flutter/material.dart';

import 'classes_setup_screen.dart';
import 'subjects_screen.dart';

class AcademicSetupDashboard
    extends StatelessWidget {

  final String schoolId;

  const AcademicSetupDashboard({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {

    final items = [

      {
        "title": "Subjects",
        "subtitle":
            "Manage centralized subjects",
        "icon": Icons.menu_book_rounded,
      },

      {
        "title": "Classes & Sections",
        "subtitle":
            "Configure classes and sections",
        "icon": Icons.school_rounded,
      },

      {
        "title": "Periods",
        "subtitle":
            "Manage academic periods",
        "icon": Icons.access_time_rounded,
      },

      {
        "title": "Timings",
        "subtitle":
            "Configure group timings",
        "icon": Icons.schedule_rounded,
      },

      {
        "title": "Examinations",
        "subtitle":
            "Configure exam structure",
        "icon": Icons.fact_check_rounded,
      },

      {
        "title": "Imports & Exports",
        "subtitle":
            "Bulk upload and templates",
        "icon": Icons.cloud_upload_rounded,
      },
    ];

    return Scaffold(

      backgroundColor:
          const Color(0xffF8FAFC),

      appBar: AppBar(

        title: const Text(
          "Academic Setup",
        ),

        backgroundColor: Colors.white,

        elevation: 0,
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: GridView.builder(

          itemCount: items.length,

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(

            crossAxisCount: 2,

            crossAxisSpacing: 14,
            mainAxisSpacing: 14,

            childAspectRatio: 1.8,
          ),

          itemBuilder: (context, index) {

            final item = items[index];

            return InkWell(

              borderRadius:
                  BorderRadius.circular(24),

              onTap: () {

                switch (item['title']) {

                  case "Subjects":

                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (_) =>
                            SubjectsScreen(
                          schoolId: schoolId,
                        ),
                      ),
                    );

                    break;

                  case "Classes & Sections":

                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (_) =>
                            ClassesSetupScreen(
                          schoolId: schoolId,
                        ),
                      ),
                    );

                    break;
                }
              },

              child: Container(

                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(24),

                  border: Border.all(
                    color: Colors.grey.shade100,
                  ),

                  boxShadow: [

                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.02),

                      blurRadius: 12,

                      offset: const Offset(
                        0,
                        5,
                      ),
                    ),
                  ],
                ),

                child: Row(

                  crossAxisAlignment:
                      CrossAxisAlignment.center,

                  children: [

                    Container(

                      height: 44,
                      width: 44,

                      decoration:
                          BoxDecoration(

                        color:
                            const Color(
                          0xffEEF2FF,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),

                      child: Icon(

                        item['icon']
                            as IconData,

                        color:
                            const Color(
                          0xff5B5FEF,
                        ),

                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [

                          Text(

                            item['title']
                                .toString(),

                            style:
                                const TextStyle(

                              fontSize: 14,

                              fontWeight:
                                  FontWeight.w600,

                              color:
                                  Color(0xff111827),
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(

                            item['subtitle']
                                .toString(),

                            style: TextStyle(

                              fontSize: 12,

                              height: 1.4,

                              color:
                                  Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
