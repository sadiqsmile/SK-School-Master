import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IdCardSettingsScreen extends StatefulWidget {
  final String schoolId;

  const IdCardSettingsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<IdCardSettingsScreen> createState() => _IdCardSettingsScreenState();
}

class _IdCardSettingsScreenState extends State<IdCardSettingsScreen> {
  bool showAdmissionNo = true;
  bool showDob = true;
  bool showBloodGroup = true;
  bool showPhone = false;
  bool showAddress = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('settings')
        .doc('id_card')
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    setState(() {
      showAdmissionNo = data['showAdmissionNo'] ?? true;
      showDob = data['showDob'] ?? true;
      showBloodGroup = data['showBloodGroup'] ?? true;
      showPhone = data['showPhone'] ?? false;
      showAddress = data['showAddress'] ?? false;
    });
  }

  Future<void> _saveSettings() async {
    try {
      setState(() {
        loading = true;
      });

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('settings')
          .doc('id_card')
          .set({
        "showAdmissionNo": showAdmissionNo,
        "showDob": showDob,
        "showBloodGroup": showBloodGroup,
        "showPhone": showPhone,
        "showAddress": showAddress,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Settings saved successfully"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text("ID Card Settings"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Visible Fields",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                _switchTile(
                  title: "Admission Number",
                  value: showAdmissionNo,
                  onChanged: (v) {
                    setState(() {
                      showAdmissionNo = v;
                    });
                  },
                ),
                _switchTile(
                  title: "Date of Birth",
                  value: showDob,
                  onChanged: (v) {
                    setState(() {
                      showDob = v;
                    });
                  },
                ),
                _switchTile(
                  title: "Blood Group",
                  value: showBloodGroup,
                  onChanged: (v) {
                    setState(() {
                      showBloodGroup = v;
                    });
                  },
                ),
                _switchTile(
                  title: "Phone Number",
                  value: showPhone,
                  onChanged: (v) {
                    setState(() {
                      showPhone = v;
                    });
                  },
                ),
                _switchTile(
                  title: "Address",
                  value: showAddress,
                  onChanged: (v) {
                    setState(() {
                      showAddress = v;
                    });
                  },
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff5B5FEF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: loading ? null : _saveSettings,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Save Settings",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xff5B5FEF),
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
