// features/super_admin/screens/school_details_screen.dart
// features/super_admin/screens/school_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/super_admin_provider.dart';

class SchoolDetailsScreen extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic> data;

  const SchoolDetailsScreen({
    super.key,
    required this.schoolId,
    required this.data,
  });

  @override
  State<SchoolDetailsScreen> createState() => _SchoolDetailsScreenState();
}

class _SchoolDetailsScreenState extends State<SchoolDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? '';
        final logo = (data['logo'] ?? '').toString();
        final email = data['email'] ?? widget.data['email'] ?? "No Email";

        final themePrimary = data['themeColorPrimary'] ?? "#6366F1";
        final themeSecondary = data['themeColorSecondary'] ?? "#4F46E5";

        return Scaffold(
          backgroundColor: const Color(0xffF5F7FB),

          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: _backButton(context),
            title: const Text(
              "School Details",
              style: TextStyle(
                color: Color(0xff1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// HEADER (FIXED)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _hexToColor(themePrimary),
                          _hexToColor(themeSecondary),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
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
                                    key: ValueKey(logo), // 🔥 forces rebuild
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.contain,
                                  )
                                : const Icon(Icons.school, size: 30),
                          ),
                        ),

                        const SizedBox(width: 16),

                        /// SCHOOL NAME + EMAIL
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _tile("School ID", widget.schoolId, Icons.tag),
                  _tile("Admin Email", email, Icons.email),

                  const SizedBox(height: 20),

                  _actionTile(
                    "Change School Name",
                    Icons.edit,
                    () => _changeName(context),
                  ),

                  _actionTile(
                    "Change Logo",
                    Icons.image,
                    () => _changeLogo(context),
                  ),

                  _actionTile(
                    "Change Primary Color",
                    Icons.color_lens,
                    () => _pickColor(true),
                  ),

                  _actionTile(
                    "Change Secondary Color",
                    Icons.gradient,
                    () => _pickColor(false),
                  ),

                  _actionTile(
                    "Reset Admin Password",
                    Icons.lock_reset,
                    () => _resetPassword(context),
                  ),

                  _actionTile(
                    "Archive School",
                    Icons.archive,
                    () => _archiveSchool(context),
                  ),

                  _actionTile(
                    "Delete School",
                    Icons.delete,
                    () => _deleteSchool(context),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// BACK BUTTON
  Widget _backButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xffF1F5F9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_left, color: Color(0xff1E3A8A)),
        ),
      ),
    );
  }

  Widget _tile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff1E3A8A)),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  Widget _actionTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color color = const Color(0xff1E3A8A),
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  /// CHANGE NAME
  Future<void> _changeName(BuildContext context) async {
    String newName = "";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New School Name"),
        content: TextField(onChanged: (val) => newName = val),
        actions: [
          TextButton(
            onPressed: () async {
              if (newName.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .update({'name': newName.toUpperCase()});

              ProviderScope.containerOf(context).invalidate(schoolsProvider);

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// LOGO FIX (CACHE FIX ADDED)
  Future<void> _changeLogo(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // 🔥 compress + fix corruption
      );

      if (picked == null) return;

      final ref = FirebaseStorage.instance.ref().child(
        "school_logos/${widget.schoolId}.jpg",
      ); // 🔥 use jpg

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();

        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'), // 🔥 IMPORTANT
        );
      } else {
        final file = File(picked.path);

        await ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'), // 🔥 IMPORTANT
        );
      }

      final url = await ref.getDownloadURL();

      final updatedUrl = "$url?time=${DateTime.now().millisecondsSinceEpoch}";

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .set({'logo': updatedUrl}, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Logo updated ✅")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logo error: $e")));
    }
  }

  /// RESET PASSWORD
  Future<void> _resetPassword(BuildContext context) async {
    try {
      final adminUid = widget.data['adminUid'];
      final email = widget.data['email'] ?? "";

      if (adminUid == null || email.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Missing admin data ❌")));
        return;
      }

      final defaultPassword = email.substring(0, 6);

      final callable = FirebaseFunctions.instance.httpsCallable(
        'resetUserPassword',
      );

      await callable.call({'uid': adminUid, 'newPassword': defaultPassword});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset: $defaultPassword")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  /// DELETE
  Future<void> _deleteSchool(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete School"),
        content: const Text("This will delete ALL data permanently!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'deleteSchoolCompletely',
      );

      await callable.call({'schoolId': widget.schoolId});

      ProviderScope.containerOf(context).invalidate(schoolsProvider);

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("School deleted ✅")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete error: $e")));
    }
  }

  /// ARCHIVE
  Future<void> _archiveSchool(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .update({'archived': true});

    Navigator.pop(context);
  }

  /// COLOR
  Future<void> _pickColor(bool isPrimary) async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pick Color"),
        content: Wrap(
          children: Colors.primaries.map((c) {
            return GestureDetector(
              onTap: () => Navigator.pop(context, c),
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 30,
                height: 30,
                color: c,
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (selected == null) return;

    final hex = "#${selected.value.toRadixString(16).substring(2)}";

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .update({
          if (isPrimary) 'themeColorPrimary': hex,
          if (!isPrimary) 'themeColorSecondary': hex,
        });
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll("#", "");
    return Color(int.parse("FF$clean", radix: 16));
  }
}
