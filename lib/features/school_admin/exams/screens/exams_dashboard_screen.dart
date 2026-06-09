import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';

class ExamsDashboardScreen extends StatelessWidget {
  const ExamsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Create Exams',
    
    
    
    
  body: Center(
  child: SizedBox(
    width: 900,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [

    _card(
      context,
      title: 'Exam Types',
      subtitle: 'Manage exam types',
      icon: Icons.quiz_rounded,
      route: '/school-admin/exam-types',
    ),

    const SizedBox(height: 12),



    const SizedBox(height: 12),

    _card(
      context,
      title: 'Create Exams',
      subtitle: 'Create & manage exams',
      icon: Icons.description_rounded,
     route: '/school-admin/exams',
    ),

    const SizedBox(height: 12),

    _card(
      context,
      title: 'Marks Entry',
      subtitle: 'Enter student marks',
      icon: Icons.edit_note_rounded,
      route: '/school-admin/marks-entry',
    ),

    const SizedBox(height: 12),

    _card(
      context,
      title: 'Report Cards',
      subtitle: 'Generate report cards',
      icon: Icons.school_rounded,
      route: '/school-admin/report-cards',
    ),
  ],
),
  
  ),
    ),
    );
      }




 Widget _card(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required String route,
}) {

  Color startColor;
  Color endColor;

  switch (title) {

    case 'Exam Types':
      startColor = const Color(0xFF6366F1);
      endColor = const Color(0xFF8B5CF6);
      break;

    case 'Grade Templates':
      startColor = const Color(0xFF10B981);
      endColor = const Color(0xFF34D399);
      break;

    case 'Create Exams':
      startColor = const Color(0xFFF59E0B);
      endColor = const Color(0xFFFBBF24);
      break;

    case 'Marks Entry':
      startColor = const Color(0xFF0EA5E9);
      endColor = const Color(0xFF38BDF8);
      break;

    default:
      startColor = const Color(0xFFEF4444);
      endColor = const Color(0xFFF87171);
  }

  return InkWell(
    borderRadius: BorderRadius.circular(24),

    onTap: () {
      context.go(route);
    },

    child: Container(

      decoration: BoxDecoration(

        borderRadius:
            BorderRadius.circular(24),

        gradient: LinearGradient(
          colors: [
            startColor,
            endColor,
          ],
        ),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),

      padding: const EdgeInsets.all(20),

      child: Row(

        children: [

          Container(

            width: 56,
            height: 56,

            decoration: BoxDecoration(

              color: Colors.white24,

              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                Text(

                  title,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(

                  subtitle,

                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    ),
  );
}
}
