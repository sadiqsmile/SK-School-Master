// features/super_admin/screens/super_admin_dashboard.dart
// features/super_admin/screens/super_admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/super_admin_provider.dart';
import 'add_school_screen.dart';
import 'school_details_screen.dart'; // ✅ IMPORTANT

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    final totalSchools = ref.watch(totalSchoolsProvider);
    final totalStudentsAsync = ref.watch(totalStudentsProvider);
    final schoolsAsync = ref.watch(schoolsProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
           
            CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
            SizedBox(width: 10),
            Text(
              "Super Admin",
              style: TextStyle(
                color: Color(0xff1E3A8A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        
        actions: const [
          Icon(Icons.notifications_none, color: Color(0xff1E3A8A)),
          SizedBox(width: 10),
          Icon(Icons.settings, color: Color(0xff1E3A8A)),
          SizedBox(width: 10),
          Icon(Icons.logout, color: Color(0xff1E3A8A)),
          SizedBox(width: 10),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔥 STATS
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Total Schools",
                    value: totalSchools.toString(),
                    icon: Icons.school,
                    colors: const [Color(0xff16A34A), Color(0xff4ADE80)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "Total Students",
                    value: totalStudentsAsync.when(
                      data: (snap) => snap.docs.length.toString(),
                      loading: () => "0",
                      error: (_, __) => "0",
                    ),
                    icon: Icons.groups,
                    colors: const [Color(0xff1E3A8A), Color(0xff3B82F6)],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🚀 PREMIUM ADD SCHOOL BUTTON
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff7F1D1D), // deep red
                      Color(0xffDC2626), // bright red
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddSchoolScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.school, color: Colors.white),
                  label: const Text(
                    "Add School",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔍 SEARCH
            TextField(
              decoration: InputDecoration(
                hintText: "Search school...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 20),

            /// 🏫 SCHOOL LIST
            Expanded(
              child: schoolsAsync.when(
                data: (snapshot) {
                  final schools = snapshot.docs;

                  final filtered = schools.where((doc) {
                    final name = (doc.data()['name'] ?? '').toLowerCase();
                    return name.contains(search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("No schools found"));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data = filtered[index].data();
                      final name = data['name'] ?? '';
                      final logo = data['logo'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          /// ✅ OPEN DETAILS SCREEN (FIXED)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SchoolDetailsScreen(
                                schoolId: filtered[index].id,
                                data: data,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                             
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: logo.isNotEmpty
                                      ? Image.network(
                                          logo,
                                          key: ValueKey(logo),
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit
                                              .contain, // 🔥 FIXED (no crop)
                                          filterQuality: FilterQuality.high,

                                          // 🔥 WEB FIX
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                print("IMAGE ERROR: $error");
                                                return const Icon(
                                                  Icons.school,
                                                  size: 30,
                                                );
                                              },
                                        )
                                      : const Icon(Icons.school, size: 30),
                                ),
                              ),

                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff1E3A8A),
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎨 STAT CARD (IMPROVED)
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(icon, size: 42, color: Colors.white.withOpacity(0.25)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
