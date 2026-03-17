// features/super_admin/screens/school_details_screen.dart
// features/super_admin/screens/school_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  /// 🔥 ADMIN EMAIL FETCH
  Widget _adminEmailWidget() {
    final adminUid = widget.data['adminUid'];

    if (adminUid == null) {
      return const Text("No Admin Assigned");
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(adminUid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text("Loading...");
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null) {
          return const Text("No Email Found");
        }

        return Text(userData['email'] ?? "No Email");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] ?? '';
    final logo = widget.data['logo'] ?? '';
    final themePrimary = widget.data['themeColorPrimary'] ?? "#6366F1";
    final themeSecondary = widget.data['themeColorSecondary'] ?? "#4F46E5";

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        /// 🔥 CUSTOM BACK BUTTON (OPTION 3)
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xffF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left, color: Color(0xff1E3A8A)),
            ),
          ),
        ),

        title: const Text(
          "School Details",
          style: TextStyle(
            color: Color(0xff1E3A8A),
            fontWeight: FontWeight.w600,
          ),
        ),

        iconTheme: const IconThemeData(color: Color(0xff1E3A8A)),

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🏫 HEADER
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
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: logo.isNotEmpty
                        ? NetworkImage(logo)
                        : null,
                    child: logo.isEmpty
                        ? const Icon(Icons.school, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 📋 DETAILS
            _tile("School ID", widget.schoolId, Icons.tag),

            _tile(
              "Admin Email",
              widget.data['email'] ?? "No Email",
              Icons.email,
            ),

            const SizedBox(height: 20),

            /// ⚙️ ACTIONS
            _actionTile(
              context,
              "Change School Name",
              Icons.edit,
              () => _changeName(context),
            ),

            _actionTile(
              context,
              "Change Logo",
              Icons.image,
              () => _changeLogo(context),
            ),

            /// 🎨 NEW COLOR OPTIONS
            _actionTile(
              context,
              "Change Primary Color",
              Icons.color_lens,
              () => _comingSoon(context),
            ),

            _actionTile(
              context,
              "Change Secondary Color",
              Icons.gradient,
              () => _comingSoon(context),
            ),

            _actionTile(
              context,
              "Reset Admin Password",
              Icons.lock_reset,
              () => _resetPassword(context),
            ),

            _actionTile(
              context,
              "Archive School",
              Icons.archive,
              () => _archiveSchool(context),
            ),

            _actionTile(
              context,
              "Delete School",
              Icons.delete,
              () => _deleteSchool(context),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 INFO TILE
  Widget _tile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff1E3A8A)),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  /// 🔹 ACTION TILE
  Widget _actionTile(
    BuildContext context,
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

  /// 🔥 CHANGE NAME
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

  /// 🔥 PLACEHOLDER
  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Coming in next step 🚀")));
  }

  /// 🔥 CHANGE LOGO (placeholder)
  void _changeLogo(BuildContext context) {
    _comingSoon(context);
  }

  /// 🔥 RESET PASSWORD (placeholder)
  void _resetPassword(BuildContext context) {
    _comingSoon(context);
  }

  /// 🔥 ARCHIVE
  Future<void> _archiveSchool(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .update({'archived': true});

    Navigator.pop(context);
  }

  /// 🔥 DELETE
  Future<void> _deleteSchool(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .update({'archived': true, 'status': 'deleted'});

    Navigator.pop(context);
  }

  /// 🎨 HEX → COLOR
  Color _hexToColor(String hex) {
    final clean = hex.replaceAll("#", "");
    return Color(int.parse("FF$clean", radix: 16));
  }
}
