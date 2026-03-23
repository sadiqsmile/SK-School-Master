// features/super_admin/screens/super_admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/super_admin_provider.dart';
import 'add_school_screen.dart';
import 'school_details_screen.dart';
import 'settings_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  String search = "";

  /// ✅ LOGOUT (SIMPLIFIED)
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(schoolsProvider);
    final totalSchoolsAsync = ref.watch(totalSchoolsProvider);
    final totalStudentsAsync = ref.watch(totalStudentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              child: SvgPicture.asset(
                'assets/icons/admin.svg',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Super Admin",
              style: TextStyle(
                color: Color(0xff1E3A8A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          const Icon(Icons.notifications_none, color: Color(0xff1E3A8A)),
          const SizedBox(width: 10),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            child: const Icon(Icons.settings, color: Color(0xff1E3A8A)),
          ),

          const SizedBox(width: 10),

          GestureDetector(
            onTap: () => _logout(context),
            child: const Icon(Icons.logout, color: Color(0xff1E3A8A)),
          ),

          const SizedBox(width: 10),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Welcome, Super Admin 👋",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1E3A8A),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔥 STATS
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Total Schools",
                    value: totalSchoolsAsync.when(
                      data: (count) => count.toString(),
                      loading: () => "0",
                      error: (_, _) => "0",
                    ),
                    icon: Icons.school,
                    colors: const [Color(0xff16A34A), Color(0xff4ADE80)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "Total Students",
                    value: totalStudentsAsync.when(
                      data: (count) => count.toString(),
                      loading: () => "0",
                      error: (_, _) => "0",
                    ),
                    icon: Icons.groups,
                    colors: const [Color(0xff1E3A8A), Color(0xff3B82F6)],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

           SizedBox(
  width: double.infinity,
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddSchoolScreen(),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 138, 30, 30), // dark blue
            Color.fromARGB(255, 246, 59, 106), // light blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Add School",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ),
),
            const SizedBox(height: 20),

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

            Expanded(
              child: schoolsAsync.when(
                data: (snapshot) {
                  final filtered = snapshot.docs.where((doc) {
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

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: logo.isNotEmpty
                              ? (logo.toLowerCase().endsWith('.svg')
                                  ? SvgPicture.network(logo)
                                  : Image.network(logo))
                              : const Icon(Icons.school),
                        ),
                        title: Text(name),
                        onTap: () {
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
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// STAT CARD
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
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              icon,
              size: 42,
              color: Colors.white.withOpacity(0.25),
            ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}