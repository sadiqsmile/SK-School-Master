import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';

class BulkDeleteStudentsScreen extends StatefulWidget {
  final String schoolId;

  const BulkDeleteStudentsScreen({super.key, required this.schoolId});

  @override
  State<BulkDeleteStudentsScreen> createState() =>
      _BulkDeleteStudentsScreenState();
}

class _BulkDeleteStudentsScreenState extends State<BulkDeleteStudentsScreen> {
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;
  String _searchQuery = '';

  Future<void> _softDeleteStudent(
      String studentId, Map<String, dynamic> data) async {
    final firestore = FirebaseFirestore.instance;
    final payload = Map<String, dynamic>.from(data)
      ..['deletedAt'] = FieldValue.serverTimestamp();
    await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('deleted_students')
        .doc(studentId)
        .set(payload);
    await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .doc(studentId)
        .delete();
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bulk Delete'),
        content: Text(
            'Move ${_selectedIds.length} student(s) to the recycle bin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      final ids = Set<String>.from(_selectedIds);
      for (final id in ids) {
        final doc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .doc(id)
            .get();
        if (doc.exists) {
          await _softDeleteStudent(id, doc.data()!);
        }
      }
      if (mounted) {
        setState(() => _selectedIds.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ids.length} student(s) moved to recycle bin')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Bulk Delete Students',
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or admission no…',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),

          // Action bar
          if (_selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.withOpacity(0.06),
              child: Row(
                children: [
                  Text(
                    '${_selectedIds.length} selected',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.red),
                  ),
                  const Spacer(),
                  if (_isDeleting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.delete, size: 18,
                          color: Colors.white),
                      label: const Text('Delete Selected',
                          style: TextStyle(color: Colors.white)),
                      onPressed: _deleteSelected,
                    ),
                ],
              ),
            ),

          // Student list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('students')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;
                final docs = _searchQuery.isEmpty
                    ? allDocs
                    : allDocs.where((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final name =
                            (d['name'] ?? '').toString().toLowerCase();
                        final admNo =
                            (d['admissionNo'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery) ||
                            admNo.contains(_searchQuery);
                      }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No students found'));
                }

                return Column(
                  children: [
                    // Select all
                    CheckboxListTile(
                      value: docs.isNotEmpty &&
                          docs.every((d) => _selectedIds.contains(d.id)),
                      tristate: true,
                      title: Text(
                        'Select All (${docs.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.addAll(docs.map((d) => d.id));
                          } else {
                            _selectedIds
                                .removeAll(docs.map((d) => d.id));
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.red,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final d =
                              doc.data() as Map<String, dynamic>;
                          final name =
                              (d['name'] ?? '').toString();
                          final admNo =
                              (d['admissionNo'] ?? '').toString();
                          final className =
                              (d['className'] ?? '').toString();
                          final section =
                              (d['section'] ?? '').toString();
                          final isSelected =
                              _selectedIds.contains(doc.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(doc.id);
                                } else {
                                  _selectedIds.remove(doc.id);
                                }
                              });
                            },
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            activeColor: Colors.red,
                            title: Text(
                              name.isEmpty ? 'Student' : name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              [
                                if (className.isNotEmpty)
                                  'Class $className${section.isNotEmpty ? ' $section' : ''}',
                                if (admNo.isNotEmpty) 'Adm: $admNo',
                              ].join(' • '),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
