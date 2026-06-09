import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';


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
  bool _isSendingReset = false;
  bool _isReplacingAdmin = false;
  bool isDeletingSchool = false;

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
        final name = (data['name'] ?? '').toString();
        final logo = (data['logo'] ?? '').toString();
        final email =
            (data['email'] ?? widget.data['email'] ?? 'No Email').toString();

        final themePrimary =
            (data['themeColorPrimary'] ?? '#6366F1').toString();
        final themeSecondary =
            (data['themeColorSecondary'] ?? '#4F46E5').toString();

        return Scaffold(
          backgroundColor: const Color(0xffF5F7FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xff1E3A8A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'School Details',
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
                if (isDeletingSchool)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xffEF5350)),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xffC62828),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Deleting school completely...',
                            style: TextStyle(
                              color: Color(0xffB71C1C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      Container(
                        width: 60,
                        height: 60,
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
                                      placeholderBuilder: (context) =>
                                          const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : Image.network(
                                      logo,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image);
                                      },
                                    ))
                              : const Icon(Icons.school),
                        ),
                      ),
                      const SizedBox(width: 16),
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

                _tile('School ID', widget.schoolId, Icons.tag),
                _tile('Admin Email', email, Icons.email),

                const SizedBox(height: 20),

                _actionTile(
                  'Change School Name',
                  Icons.edit,
                  () => _changeName(context),
                ),
                _actionTile(
                  'Change Logo',
                  Icons.image,
                  () => _changeLogo(context),
                ),
                _actionTile(
                  _isReplacingAdmin
                      ? 'Replacing School Admin...'
                      : 'Replace School Admin',
                  Icons.manage_accounts,
                  _isReplacingAdmin ? null : () => _replaceSchoolAdmin(context, email),
                ),
                _actionTile(
                  _isSendingReset
                      ? 'Sending Reset Email...'
                      : 'Send Password Reset Email',
                  Icons.lock_reset,
                  _isSendingReset ? null : () => _resetAdminPassword(context, email),
                  color: const Color(0xff7C3AED),
                  isLoading: _isSendingReset,
                ),
                _actionTile(
                  'Change Primary Color',
                  Icons.color_lens,
                  () => _pickColor(true),
                ),
                _actionTile(
                  'Change Secondary Color',
                  Icons.gradient,
                  () => _pickColor(false),
                ),
                _actionTile(
                  'Archive School',
                  Icons.archive,
                  () => _archiveSchool(context),
                ),
                _actionTile(
                  'Delete School',
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

  Widget _actionTile(
    String title,
    IconData icon,
    VoidCallback? onTap, {
    Color color = const Color(0xff1E3A8A),
    bool isLoading = false,
  }) {
    return ListTile(
      leading: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          : Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _showSuccessDialog(String title, String message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String title, String message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeName(BuildContext context) async {
    String newName = '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New School Name'),
        content: TextField(onChanged: (val) => newName = val),
        actions: [
          TextButton(
            onPressed: () async {
              if (newName.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .update({'name': newName.toUpperCase()});

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLogo(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final isSvg = picked.name.toLowerCase().endsWith('.svg');

      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .get();

      final oldPath = doc.data()?['logoPath'];

      if (oldPath != null && oldPath.toString().isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(oldPath).delete();
        } catch (_) {}
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('school_logos')
          .child('${widget.schoolId}.${isSvg ? 'svg' : 'png'}');

      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: isSvg ? 'image/svg+xml' : 'image/png',
        ),
      );

      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .update({
        'logo': url,
        'logoPath': ref.fullPath,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo updated ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteSchool(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete School'),
        content: const Text(
          'This will permanently delete school, admin account, user records and logo. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isDeletingSchool = true;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('deleteSchoolCompletely');

      await callable.call({
        'schoolId': widget.schoolId,
      });

      if (!mounted) return;

      setState(() {
        isDeletingSchool = false;
      });

      navigator.pop();

      messenger.showSnackBar(
        const SnackBar(content: Text('School deleted completely ✅')),
      );
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() {
          isDeletingSchool = false;
        });
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Delete failed: ${e.message}')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isDeletingSchool = false;
        });
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _archiveSchool(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .update({'archived': true});

    if (!mounted) return;
    Navigator.pop(context);
  }


Future<void> _replaceSchoolAdmin(BuildContext context, String currentEmail) async {
  final controller = TextEditingController(text: currentEmail);

  try {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Replace School Admin'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New Admin Email',
                hintText: 'Enter new admin email',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Replace'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final newEmail = controller.text.trim().toLowerCase();

    if (newEmail.isEmpty || !newEmail.contains('@')) {
      await _showErrorDialog(
        'Invalid Email',
        'Please enter a valid admin email.',
      );
      return;
    }

    if (newEmail == currentEmail.trim().toLowerCase()) {
      await _showErrorDialog(
        'Same Email',
        'The new admin email cannot be the same as the current admin email.',
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isReplacingAdmin = true;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('replaceSchoolAdmin');

      final result = await callable.call({
        'schoolId': widget.schoolId,
        'newEmail': newEmail,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final updatedEmail = (data['email'] ?? newEmail).toString();

      await FirebaseAuth.instance.sendPasswordResetEmail(email: updatedEmail);

      await _showSuccessDialog(
        'School Admin Replaced',
        'School admin was replaced successfully.\n\nNew admin: $updatedEmail\n\nA password reset email has been sent.',
      );
    } on FirebaseFunctionsException catch (e) {
      await _showErrorDialog(
        'Replace Failed',
        e.message ?? 'Failed to replace school admin.',
      );
    } on FirebaseAuthException catch (e) {
      String message =
          'School admin was replaced, but reset email could not be sent.';

      if (e.code == 'invalid-email') {
        message =
            'School admin was replaced, but the email address is invalid.';
      } else if (e.message != null && e.message!.trim().isNotEmpty) {
        message =
            'School admin was replaced, but reset email failed:\n\n${e.message}';
      }

      await _showErrorDialog('Reset Email Failed', message);
    } catch (e) {
      await _showErrorDialog(
        'Replace Failed',
        'Something went wrong while replacing school admin.\n\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReplacingAdmin = false;
        });
      }
    }
  } finally {
    controller.dispose();
  }
}

  Future<void> _resetAdminPassword(BuildContext context, String email) async {
    if (_isSendingReset) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Send Password Reset Email'),
            content: Text(
              'A Firebase password reset email will be sent to:\n\n$email\n\nThe school admin can open the email and set a new password securely.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Send'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isSendingReset = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );

      if (!mounted) return;

      await _showSuccessDialog(
        'Reset Email Sent',
        'A password reset link has been sent to:\n\n$email\n\nThe school admin can now create a new password from the email link.',
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send password reset email.';

      if (e.code == 'user-not-found') {
        message =
            'No Firebase Auth user exists for this email.\n\nMake sure this school admin account is already created in Firebase Authentication.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else if (e.message != null && e.message!.trim().isNotEmpty) {
        message = e.message!;
      }

      if (!mounted) return;
      await _showErrorDialog('Reset Failed', message);
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog(
        'Reset Failed',
        'Something went wrong while sending reset email.\n\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingReset = false;
        });
      }
    }
  }

  Future<void> _pickColor(bool isPrimary) async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick Color'),
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

    final hex = '#${selected.value.toRadixString(16).substring(2)}';

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .update({
      if (isPrimary) 'themeColorPrimary': hex,
      if (!isPrimary) 'themeColorSecondary': hex,
    });
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}