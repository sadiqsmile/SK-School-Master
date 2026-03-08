import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:school_app/features/school_admin/classes/providers/classes_provider.dart';
import 'package:school_app/features/school_admin/classes/providers/sections_provider.dart';
import 'package:school_app/features/school_admin/teachers/services/teacher_service.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/services/teacher_account_service.dart';
import 'package:school_app/core/utils/firestore_keys.dart';

class AddTeacherScreen extends ConsumerStatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  ConsumerState<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends ConsumerState<AddTeacherScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();

  final List<String> _subjects = <String>[];
  final List<_TeacherAssignment> _assignments = <_TeacherAssignment>[];

  String? _selectedClassId;
  String? _selectedSectionId;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _addSubject() {
    final raw = _subjectController.text.trim();
    if (raw.isEmpty) return;
    final normalized = raw;
    if (_subjects.contains(normalized)) return;
    setState(() {
      _subjects.add(normalized);
      _subjectController.clear();
    });
  }

  Future<void> _addAssignment() async {
    if (_selectedClassId == null || _selectedSectionId == null) return;

    final classesSnap = await ref.read(classesProvider.future);
    final classDoc = classesSnap.docs.firstWhere(
      (d) => d.id == _selectedClassId,
      orElse: () => throw StateError('Class not found'),
    );
    final className = (classDoc.data()['name'] ?? classDoc.id).toString();
    final classLabel = className;

    final sectionsSnap = await ref.read(sectionsProvider(_selectedClassId!).future);
    final sectionDoc = sectionsSnap.docs.firstWhere(
      (d) => d.id == _selectedSectionId,
      orElse: () => throw StateError('Section not found'),
    );
    final sectionName = (sectionDoc.data()['name'] ?? sectionDoc.id).toString();

    final next = _TeacherAssignment(
      classId: _selectedClassId!,
      className: classLabel,
      sectionId: _selectedSectionId!,
      sectionName: sectionName,
    );

    setState(() {
      final exists = _assignments.any(
        (a) => a.classId == next.classId && a.sectionId == next.sectionId,
      );
      if (!exists) {
        _assignments.add(next);
      }
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter teacher name, email and phone')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final schoolDoc = await ref.read(currentSchoolProvider.future);
      final schoolId = schoolDoc.id;

      // 1) Create teacher login.
      //    This returns the teacherUid which we use as the teacher doc id.
      try {
        final result = await TeacherAccountService().createTeacherLogin(
          schoolId: schoolId,
          teacherName: name,
          email: email,
          phone: phone,
        );

        final teacherUid = (result['uid'] ?? '').toString();
        if (teacherUid.trim().isEmpty) {
          throw StateError('Teacher UID missing from backend response');
        }

        // 2) Save teacher profile at schools/{schoolId}/teachers/{teacherUid}
        await TeacherService().setTeacher(
          schoolId: schoolId,
          teacherId: teacherUid,
          data: {
            'teacherUid': teacherUid,
            'name': name,
            'nameLower': name.trim().toLowerCase(),
            'email': email,
            'emailLower': email.trim().toLowerCase(),
            'phone': phone,
            'subjects': _subjects,
            // New structure: list of {classId, sectionId, className, sectionName}
            'classes': _assignments.map((a) => a.toMap()).toList(),
            // Normalized keys for security rules and fast checks.
            'assignmentKeys': _assignments
                .map((a) => classKeyFrom(a.classId, a.sectionId))
                .toSet()
                .toList(),
            'createdAt': FieldValue.serverTimestamp(),
          },
        );

        final tempPassword = (result['temporaryPassword'] ?? '').toString();

        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Teacher login created'),
                content: SelectableText(
                  'Email: $email\n'
                  'Temporary password: $tempPassword\n\n'
                  'Teacher must change password after login.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to create teacher login/profile: $e')),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Teacher "$name" added')),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to add teacher: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Teacher')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SectionCard(
              title: 'Teacher Details',
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Teacher Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Subjects',
              subtitle: 'Add one or more subjects (e.g., Math, Science).',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                          ),
                          onSubmitted: (_) => _addSubject(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _isSaving ? null : _addSubject,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ChipWrap(
                    values: _subjects,
                    onRemove: _isSaving
                        ? null
                        : (v) => setState(() => _subjects.remove(v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Class & Section Assignment',
              subtitle: 'Assign the teacher to classes and sections.',
              child: Column(
                children: [
                  classesAsync.when(
                    data: (snapshot) {
                      final docs = snapshot.docs;
                      return DropdownButtonFormField<String>(
                        key: ValueKey<String?>(_selectedClassId),
                        initialValue: _selectedClassId,
                        decoration: const InputDecoration(labelText: 'Class'),
                        items: [
                          for (final doc in docs)
                            DropdownMenuItem(
                              value: doc.id,
                              child: Text((doc.data()['name'] ?? doc.id).toString()),
                            ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedClassId = value;
                                  _selectedSectionId = null;
                                });
                              },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Failed to load classes: $e'),
                  ),
                  const SizedBox(height: 10),
                  if (_selectedClassId == null)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Select a class to pick a section'),
                    )
                  else
                    ref.watch(sectionsProvider(_selectedClassId!)).when(
                      data: (snapshot) {
                        final docs = snapshot.docs;
                        return DropdownButtonFormField<String>(
                          key: ValueKey<String?>(_selectedSectionId),
                          initialValue: _selectedSectionId,
                          decoration: const InputDecoration(labelText: 'Section'),
                          items: [
                            for (final doc in docs)
                              DropdownMenuItem(
                                value: doc.id,
                                child: Text((doc.data()['name'] ?? doc.id).toString()),
                              ),
                          ],
                          onChanged: _isSaving
                              ? null
                              : (value) => setState(() => _selectedSectionId = value),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Failed to load sections: $e'),
                    ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isSaving || _selectedClassId == null || _selectedSectionId == null
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await _addAssignment();
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Failed to add assignment: $e')),
                                );
                              }
                            },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Assignment'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AssignmentChips(
                    assignments: _assignments,
                    onRemove: _isSaving
                        ? null
                        : (a) => setState(() => _assignments.remove(a)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Teacher'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.3),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.values,
    required this.onRemove,
  });

  final List<String> values;
  final void Function(String value)? onRemove;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'None yet',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          Chip(
            label: Text(v),
            onDeleted: onRemove == null ? null : () => onRemove!(v),
          ),
      ],
    );
  }
}

class _TeacherAssignment {
  const _TeacherAssignment({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
  });

  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;

  String get label {
    final c = className.trim();
    final s = sectionName.trim();
    if (c.isEmpty && s.isEmpty) return 'Assignment';
    if (c.isEmpty) return s;
    if (s.isEmpty) return 'Class $c';
    return 'Class $c$s';
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'className': className,
      'sectionId': sectionId,
      'sectionName': sectionName,
    };
  }
}

class _AssignmentChips extends StatelessWidget {
  const _AssignmentChips({
    required this.assignments,
    required this.onRemove,
  });

  final List<_TeacherAssignment> assignments;
  final void Function(_TeacherAssignment assignment)? onRemove;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'No class assignments yet',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in assignments)
          Chip(
            label: Text(a.label),
            onDeleted: onRemove == null ? null : () => onRemove!(a),
          ),
      ],
    );
  }
}
