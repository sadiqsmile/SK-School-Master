// features/super_admin/screens/school_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';

class SchoolDetailsScreen extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic> data;

  const SchoolDetailsScreen({
    super.key,
    required this.schoolId,
    required this.data,
  });

  @override
  State<SchoolDetailsScreen> createState() =>
      _SchoolDetailsScreenState();
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Color(0xff1E3A8A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "School Details",
              style: TextStyle(
                color: Color(0xff1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                /// HEADER
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

                      /// LOGO
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),


child: ClipOval(
  child: logo.isNotEmpty
      ? (logo.toLowerCase().endsWith('.svg')
          ? SvgPicture.network(
              logo,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Image.network(
              logo,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image);
              },
            ))
      : const Icon(Icons.school),
),


                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              email,
                              style: const TextStyle(
                                  color: Colors.white70),
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

                _actionTile("Change School Name", Icons.edit,
                    () => _changeName(context)),

                _actionTile("Change Logo", Icons.image,
                    () => _changeLogo(context)),

                _actionTile("Change Admin Email", Icons.email,
                    () => _changeEmail(context)),

                _actionTile("Change Primary Color", Icons.color_lens,
                    () => _pickColor(true)),

                _actionTile("Change Secondary Color", Icons.gradient,
                    () => _pickColor(false)),

                _actionTile("Archive School", Icons.archive,
                    () => _archiveSchool(context)),

                _actionTile(
                  "Delete School",
                  Icons.delete,
                  () => _deleteSchool(context),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff1E3A8A)),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  Widget _actionTile(String title, IconData icon, VoidCallback onTap,
      {Color color = const Color(0xff1E3A8A)}) {
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

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// ✅ CHANGE LOGO (CLEAN STORAGE FIXED)
  Future<void> _changeLogo(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final isSvg = picked.name.toLowerCase().endsWith('.svg');

      // 🔍 GET OLD DATA
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .get();

      final oldPath = doc.data()?['logoPath'];

      // 🗑️ DELETE OLD IMAGE
      if (oldPath != null) {
        try {
          await FirebaseStorage.instance.ref(oldPath).delete();
        } catch (e) {
          debugPrint("Old image already deleted");
        }
      }

      // 📤 UPLOAD NEW IMAGE (SAME NAME)
      final ref = FirebaseStorage.instance
          .ref()
          .child('school_logos')
          .child('${widget.schoolId}.${isSvg ? 'svg' : 'png'}');

      await ref.putData(
        bytes,
        SettableMetadata(
          contentType:
              isSvg ? 'image/svg+xml' : 'image/png',
        ),
      );

      final url = await ref.getDownloadURL();

      // 💾 SAVE
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .update({
        'logo': url,
        'logoPath': ref.fullPath,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logo updated ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// DELETE SCHOOL + IMAGE
  Future<void> _deleteSchool(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .get();

      final logoPath = doc.data()?['logoPath'];

      if (logoPath != null) {
        try {
          await FirebaseStorage.instance.ref(logoPath).delete();
        } catch (e) {
          debugPrint("Image already deleted");
        }
      }

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .delete();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("School deleted ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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

  /// CHANGE EMAIL
  Future<void> _changeEmail(BuildContext context) async {
    String newEmail = "";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Admin Email"),
        content: TextField(
          onChanged: (val) => newEmail = val,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (newEmail.isEmpty) return;

              final defaultPassword =
                  newEmail.substring(0, 6);

              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .update({
                'email': newEmail,
                'defaultPassword': defaultPassword,
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      "Email updated\nPassword: $defaultPassword"),
                ),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
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

    final hex =
        "#${selected.value.toRadixString(16).substring(2)}";

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