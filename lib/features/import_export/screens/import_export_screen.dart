import 'package:flutter/material.dart';

import '../services/subject_template_service.dart';
import '../services/subject_export_service.dart';
import '../services/subject_import_service.dart';

import '../services/class_import_service.dart';
import '../services/class_export_service.dart';
import '../services/class_template_service.dart';

class ImportExportScreen extends StatelessWidget {

  final String schoolId;

  const ImportExportScreen({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xffF4F7FB),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.white,

        title: const Text(

          'Imports & Exports',

          style: TextStyle(
            fontWeight:
                FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),

      body: ListView(

        padding:
            const EdgeInsets.all(20),

        children: [

          // =========================
          // ACADEMIC
          // =========================

          const _SectionTitle(
            'Academic',
          ),

          const SizedBox(height: 14),

          Wrap(

            spacing: 16,
            runSpacing: 16,

            children: [

              _ModernActionCard(

                title:
                    'Import Subjects',

                subtitle:
                    'Upload subject Excel',

                icon:
                    Icons.upload_rounded,

                color:
                    const Color(
                  0xff6366F1,
                ),

                onTap: () async {

                  await SubjectImportService
                      .pickAndImportSubjects(

                    context: context,
                    schoolId: schoolId,
                  );
                },
              ),

              _ModernActionCard(

                title:
                    'Export Subjects',

                subtitle:
                    'Download subjects Excel',

                icon:
                    Icons.download_rounded,

                color:
                    const Color(
                  0xff10B981,
                ),

                onTap: () async {

                  await SubjectExportService
                      .exportSubjects(
                    schoolId,
                  );

                  if (context.mounted) {

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(

                      const SnackBar(

                        content: Text(
                          'Subjects exported successfully',
                        ),
                      ),
                    );
                  }
                },
              ),

              _ModernActionCard(

                title:
                    'Subject Template',

                subtitle:
                    'Download Excel template',

                icon:
                    Icons.description_rounded,

                color:
                    const Color(
                  0xffF59E0B,
                ),

                onTap: () async {

                  await SubjectTemplateService
                      .downloadTemplate();

                  if (context.mounted) {

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(

                      const SnackBar(

                        content: Text(
                          'Template downloaded successfully',
                        ),
                      ),
                    );
                  }
                },
              ),

              _ModernActionCard(

                title:
                    'Import Classes',

                subtitle:
                    'Upload class Excel',

                icon:
                    Icons.school_rounded,

                color:
                    const Color(
                  0xff8B5CF6,
                ),

                onTap: () async {

                  await ClassImportService
                      .pickAndImportClasses(

                    context: context,
                    schoolId: schoolId,
                  );
                },
              ),

              _ModernActionCard(

                title:
                    'Export Classes',

                subtitle:
                    'Download class Excel',

                icon:
                    Icons.inventory_2_rounded,

                color:
                    const Color(
                  0xff0EA5E9,
                ),

                onTap: () async {

                  await ClassExportService
                      .exportClasses(
                    schoolId,
                  );

                  if (context.mounted) {

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(

                      const SnackBar(

                        content: Text(
                          'Classes exported successfully',
                        ),
                      ),
                    );
                  }
                },
              ),

              _ModernActionCard(

                title:
                    'Class Template',

                subtitle:
                    'Download Excel template',

                icon:
                    Icons.table_chart_rounded,

                color:
                    const Color(
                  0xffEC4899,
                ),

                onTap: () async {

                  await ClassTemplateService
                      .downloadTemplate();

                  if (context.mounted) {

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(

                      const SnackBar(

                        content: Text(
                          'Class template downloaded',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 34),

          // =========================
          // STUDENTS
          // =========================

          const _SectionTitle(
            'Students',
          ),

          const SizedBox(height: 14),

          Wrap(

            spacing: 16,
            runSpacing: 16,

            children: [

              _ModernActionCard(

                title:
                    'Attendance',

                subtitle:
                    'Import & export attendance',

                icon:
                    Icons.fact_check_rounded,

                color:
                    const Color(
                  0xff14B8A6,
                ),

                onTap: () {

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(

                    const SnackBar(

                      content: Text(
                        'Attendance module coming soon',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 34),

          // =========================
          // STAFF
          // =========================

          const _SectionTitle(
            'Staff',
          ),

          const SizedBox(height: 14),

          Wrap(

            spacing: 16,
            runSpacing: 16,

            children: [

              _ModernActionCard(

                title:
                    'Import Teachers',

                subtitle:
                    'Bulk teacher upload',

                icon:
                    Icons.people_alt_rounded,

                color:
                    const Color(
                  0xffEF4444,
                ),

                onTap: () {

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(

                    const SnackBar(

                      content: Text(
                        'Teacher import coming soon',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 34),

          // =========================
          // EXAMINATIONS
          // =========================

          const _SectionTitle(
            'Examinations',
          ),

          const SizedBox(height: 14),

          Wrap(

            spacing: 16,
            runSpacing: 16,

            children: [

              _ModernActionCard(

                title:
                    'Exam Modules',

                subtitle:
                    'Import exams',

                icon:
                    Icons.quiz_rounded,

                color:
                    const Color(
                  0xff7C3AED,
                ),

                onTap: () {

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(

                    const SnackBar(

                      content: Text(
                        'Exam module import coming soon',
                      ),
                    ),
                  );
                },
              ),

              _ModernActionCard(

                title:
                    'Marks',

                subtitle:
                    'Import/export marks',

                icon:
                    Icons.grading_rounded,

                color:
                    const Color(
                  0xffF97316,
                ),

                onTap: () {

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(

                    const SnackBar(

                      content: Text(
                        'Marks import/export coming soon',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {

  final String title;

  const _SectionTitle(
    this.title,
  );

  @override
  Widget build(BuildContext context) {

    return Text(

      title,

      style: const TextStyle(

        fontSize: 25,

        fontWeight:
            FontWeight.w800,

        color:
            Color(0xff111827),
      ),
    );
  }
}

class _ModernActionCard extends StatelessWidget {

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernActionCard({

    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final width =
        MediaQuery.of(context)
            .size
            .width;

    return InkWell(

      borderRadius:
          BorderRadius.circular(
        24,
      ),

      onTap: onTap,

      child: Container(

        width:
            width > 900
                ? (width / 3) - 40
                : double.infinity,

        padding:
            const EdgeInsets.all(
          22,
        ),

        decoration:
            BoxDecoration(

          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            24,
          ),

          border: Border.all(

            color:
                const Color(
              0xffEEF2F7,
            ),
          ),

          boxShadow: [

            BoxShadow(

              color:
                  Colors.black
                      .withOpacity(
                0.04,
              ),

              blurRadius: 18,

              offset:
                  const Offset(
                0,
                8,
              ),
            ),
          ],
        ),

        child: Row(

          children: [

            Container(

              height: 58,
              width: 58,

              decoration:
                  BoxDecoration(

                color:
                    color.withOpacity(
                  0.12,
                ),

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),

              child: Icon(

                icon,

                color: color,

                size: 30,
              ),
            ),

            const SizedBox(
              width: 18,
            ),

            Expanded(

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(

                    title,

                    style:
                        const TextStyle(

                      fontSize: 18,

                      fontWeight:
                          FontWeight.w700,

                      color:
                          Color(
                        0xff111827,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(

                    subtitle,

                    style:
                        const TextStyle(

                      fontSize: 14,

                      color:
                          Color(
                        0xff6B7280,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(

              Icons.arrow_forward_ios_rounded,

              size: 18,

              color:
                  Color(
                0xff9CA3AF,
              ),
            ),
          ],
        ),
      ),
    );
  }
}