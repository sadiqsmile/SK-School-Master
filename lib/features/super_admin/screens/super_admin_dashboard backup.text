// features/super_admin/screens/super_admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_school_screen.dart';
import 'schools_screen.dart';
import 'package:school_app/providers/super_admin_provider.dart';

/// REAL STUDENT COUNT FROM FIREBASE
final studentsProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collectionGroup('students')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final schoolsSnapshot = ref.watch(schoolsProvider);
    final studentCount = ref.watch(studentsProvider).value ?? 0;

    final schoolStats = schoolsSnapshot.when(
      data: (snapshot) {
        int totalSchools = snapshot.docs.length;
        int activeSchools = 0;
        int archivedSchools = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data();

          if (data['archived'] == true) {
            archivedSchools++;
          } else {
            activeSchools++;
          }
        }

        return {
          "totalSchools": totalSchools,
          "activeSchools": activeSchools,
          "archivedSchools": archivedSchools,
        };
      },
      loading: () => {
        "totalSchools": 0,
        "activeSchools": 0,
        "archivedSchools": 0,
      },
      error: (_, _) => {
        "totalSchools": 0,
        "activeSchools": 0,
        "archivedSchools": 0,
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      /// APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            /// USER ICON
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.blue,
                size: 20,
              ),
            ),

            const SizedBox(width: 10),

            const Text(
              "Super Admin",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      /// BODY
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// STATS ROW 1
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    "Total Schools",
                    schoolStats["totalSchools"].toString(),
                    Icons.school,
                    Colors.purple,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _statCard(
                    "Active Schools",
                    schoolStats["activeSchools"].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// STATS ROW 2
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    "Archived Schools",
                    schoolStats["archivedSchools"].toString(),
                    Icons.archive,
                    Colors.orange,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _statCard(
                    "Total Students",
                    studentCount.toString(),
                    Icons.groups,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add School"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const CreateSchoolScreen(),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.build),
                    label: const Text("Maintenance"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      context.push('/super-admin/maintenance');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// SCHOOL LIST
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 248, 250, 252),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Schools",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// SEARCH
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search school...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    Expanded(child: SchoolsScreen(searchQuery: _searchQuery)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// STAT CARD
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.25), color.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
