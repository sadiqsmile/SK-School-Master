import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../providers/super_admin_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArchivedSchoolsScreen extends ConsumerWidget {
  const ArchivedSchoolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedSchoolsProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Archived Schools"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff1E3A8A),
        elevation: 0,
      ),
      body: archivedAsync.when(
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(child: Text("No archived schools"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.docs[index];
              final data = doc.data();

              final name = data['name'] ?? '';
              final logo = data['logo'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: logo.isNotEmpty
                        ? (logo.toLowerCase().endsWith('.svg')
                            ? SvgPicture.network(logo)
                            : Image.network(logo))
                        : const Icon(Icons.school),
                  ),
                  title: Text(name),

                  /// 🔥 UNARCHIVE BUTTON
                  trailing: IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('schools')
                          .doc(doc.id)
                          .update({'archived': false});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("School Restored ✅"),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}