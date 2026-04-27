import 'package:flutter/material.dart';
import 'package:school_app/core/widgets/app_drawer.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminLayout extends ConsumerWidget {
  final String title;
  final Widget? body;
  final Widget? child;
  final Widget? floatingActionButton;

  const AdminLayout({
    super.key,
    required this.title,
    this.body,
    this.child,
    this.floatingActionButton,
  });

  @override
 Widget build(BuildContext context, WidgetRef ref) {
    final page = body ?? child ?? const SizedBox();
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: floatingActionButton,

      drawer: isMobile
          ? const Drawer(
              width: 285,
              child: SafeArea(child: AppDrawer()),
            )
          : null,

      body: isMobile
          ? Column(
              children: [
                _mobileHeader(context, title),
                Expanded(child: page),
              ],
            )
          : Column(
              children: [
               _webTopHeader(ref),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 255,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFFE6EAF2),
                            ),
                          ),
                        ),
                        child: const AppDrawer(),
                      ),
                     
Expanded(
  child: Container(
    color: const Color(0xFFF5F7FB),
    alignment: Alignment.topLeft,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
    child: page,
  ),
),



                      
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // MOBILE HEADER
  Widget _mobileHeader(BuildContext context, String title) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE6EAF2)),
          ),
        ),
        child: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  // WEB TOP HEADER (UPDATED ONLY)
 
 
Widget _webTopHeader(WidgetRef ref) {
  final schoolAsync = ref.watch(currentSchoolProvider);

  return Container(
    height: 74,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: const Border(
        bottom: BorderSide(color: Color(0xFFE6EAF2)),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        schoolAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (school) {
            final data = school.data() ?? {};
            final name = data['name'] ?? '';
            final email = data['email'] ?? '';
            final logo = data['logoUrl'] ?? data['logo'] ?? '';

            return Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundImage:
                      logo.toString().isNotEmpty ? NetworkImage(logo) : null,
                  child: logo.toString().isEmpty
                      ? const Icon(Icons.school)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),

        const Spacer(),

        _iconBtn(Icons.search_rounded),
        const SizedBox(width: 10),
        _iconBtn(Icons.notifications_none_rounded),
        const SizedBox(width: 10),
        _iconBtn(Icons.person_rounded),
      ],
    ),
  );
}

Widget _iconBtn(IconData icon) {
  return Container(
    height: 42,
    width: 42,
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Icon(icon, size: 20),
  );
}
}