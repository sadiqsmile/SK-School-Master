// features/super_admin/screens/schools_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/providers/super_admin_provider.dart';

class SchoolsScreen extends ConsumerWidget {
  const SchoolsScreen({super.key, this.searchQuery = ''});

  final String searchQuery;

  String _resolveSchoolName(Map<String, dynamic> data, String fallbackId) {
    final schoolName = (data['schoolName'] ?? '').toString().trim();
    final name = (data['name'] ?? '').toString().trim();
    final displayName = (data['displayName'] ?? '').toString().trim();

    if (schoolName.isNotEmpty) return schoolName;
    if (name.isNotEmpty) return name;
    if (displayName.isNotEmpty) return displayName;

    return fallbackId;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsData = ref.watch(schoolsProvider);

    return schoolsData.when(
      data: (snapshot) {

        final allDocs = snapshot.docs;

        /// FILTER + SEARCH
        final docs = allDocs.where((doc) {
          final data = doc.data();

          /// hide archived schools
          if (data['archived'] == true) {
            return false;
          }

          if (searchQuery.isEmpty) return true;

          final name = _resolveSchoolName(data, doc.id).toLowerCase();
          final schoolId =
              (data['schoolId'] ?? doc.id).toString().toLowerCase();
          final query = searchQuery.toLowerCase();

          return name.contains(query) || schoolId.contains(query);
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text("No schools found"),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final name = _resolveSchoolName(data, doc.id);
            final schoolId = (data['schoolId'] ?? doc.id).toString();

            return Dismissible(
              key: Key(doc.id),

              /// SWIPE RIGHT → RESTORE
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.green,
                child: const Icon(Icons.unarchive, color: Colors.white),
              ),

              /// SWIPE LEFT → ARCHIVE
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.red,
                child: const Icon(Icons.archive, color: Colors.white),
              ),

              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  await FirebaseFirestore.instance
                      .collection('schools')
                      .doc(doc.id)
                      .update({'archived': true});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("School archived")),
                  );
                } else {
                  await FirebaseFirestore.instance
                      .collection('schools')
                      .doc(doc.id)
                      .update({'archived': false});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("School restored")),
                  );
                }

                return false;
              },

              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),

                child: ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -1),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                  leading: const Icon(
                    Icons.school,
                    color: Colors.blue,
                  ),

                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  subtitle: Text(
                    'School ID: $schoolId',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            );
          },
        );
      },

      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),

      error: (e, _) => Center(
        child: Text("Error: $e"),
      ),
    );
  }
}