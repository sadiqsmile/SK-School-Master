// features/school_admin/teachers/screens/teachers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/services/teacher_account_service.dart';

class TeachersScreen extends ConsumerWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const lightBg = Color(0xFFF6F5FF);
    const accent = Color(0xFF7C83FD);
    final teachersAsync = ref.watch(teachersProvider);

    return AdminLayout(
      title: 'Teachers',
      body: _TeachersBody(
        lightBg: lightBg,
        accent: accent,
        teachersAsync: teachersAsync,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add-teacher'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Teacher'),
      ),
    );
  }
}

class _TeachersBody extends ConsumerWidget {
  const _TeachersBody({
    required this.lightBg,
    required this.accent,
    required this.teachersAsync,
  });

  final Color lightBg;
  final Color accent;
  final AsyncValue teachersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: lightBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Icon(Icons.school_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Manage teachers, assignments, and logins from one place.',
                      style: TextStyle(height: 1.4, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            teachersAsync.when(
              data: (snapshot) {
                final teachers = snapshot.docs;
                final totalCount = teachers.length;
                final recentTeachers = teachers.take(3).toList();

                final sorted = [...teachers]
                  ..sort((a, b) {
                    final an = (a.data()['name'] ?? '').toString();
                    final bn = (b.data()['name'] ?? '').toString();
                    return an.compareTo(bn);
                  });

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Total Teachers',
                            '$totalCount',
                            Icons.groups_2_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'Active Today',
                            '${(totalCount * 0.8).round()}',
                            Icons.how_to_reg_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Teacher Updates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (recentTeachers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No teachers added yet.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          else
                            ...recentTeachers.map((doc) {
                              final data = doc.data();
                              final name = data['name'] ?? 'Teacher';
                              final email = (data['email'] ?? '').toString();
                              return _listRow(
                                name,
                                email.isEmpty ? 'No email' : email,
                                Icons.person_rounded,
                              );
                            }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'All Teachers',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              Text(
                                '${sorted.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (sorted.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No teachers added yet. Tap “Add Teacher”.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          else
                            ...sorted.map((doc) {
                              final data = doc.data();
                              final teacherId = doc.id;
                              final name = (data['name'] ?? 'Teacher').toString();
                              final email = (data['email'] ?? '').toString();
                              final phone = (data['phone'] ?? '').toString();
                              final subjects = (data['subjects'] as List?)
                                      ?.map((e) => e.toString())
                                      .toList() ??
                                  const <String>[];

                              final assignments = _parseTeacherAssignments(data);

                              return _TeacherRow(
                                accent: accent,
                                teacherId: teacherId,
                                name: name,
                                email: email,
                                phone: phone,
                                subjects: subjects,
                                assignments: assignments,
                                onResetPassword: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Reset teacher password?'),
                                      content: Text(
                                        'This will reset "$name" password to the first 6 characters of their email and force a password change on next login.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Reset'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (ok != true) return;
                                  try {
                                    final schoolId = await ref.read(schoolIdProvider.future);
                                    final result = await TeacherAccountService().resetTeacherPassword(
                                      schoolId: schoolId,
                                      teacherName: name,
                                      email: email,
                                      phone: phone,
                                      teacherId: teacherId,
                                    );

                                    final tempPassword = (result['temporaryPassword'] ?? '').toString();
                                    if (!context.mounted) return;
                                    await showDialog<void>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Password reset'),
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
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Reset failed: $e')),
                                    );
                                  }
                                },
                                onSendPasswordResetEmail: () async {
                                  if (email.trim().isEmpty) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No email found for this teacher.'),
                                      ),
                                    );
                                    return;
                                  }

                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Send password reset email?'),
                                      content: Text(
                                        'This will send a password reset link to:\n\n$email',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Send'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (ok != true) return;

                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(email: email.trim());
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Password reset email sent to $email'),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to send email: $e')),
                                    );
                                  }
                                },
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF7C83FD)),
                ),
              ),
              error: (e, _) =>
                  Center(child: Text('Error loading teachers: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _listRow(String name, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherRow extends StatelessWidget {
  const _TeacherRow({
    required this.accent,
    required this.teacherId,
    required this.name,
    required this.email,
    required this.phone,
    required this.subjects,
    required this.assignments,
    required this.onResetPassword,
    required this.onSendPasswordResetEmail,
  });

  final Color accent;
  final String teacherId;
  final String name;
  final String email;
  final String phone;
  final List<String> subjects;
  final List<String> assignments;
  final VoidCallback onResetPassword;
  final VoidCallback onSendPasswordResetEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF),
                child: Icon(Icons.person_rounded, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Teacher' : name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.isEmpty ? 'No email' : email,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    if (phone.trim().isNotEmpty)
                      Text(
                        phone,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onSendPasswordResetEmail,
                    icon: const Icon(Icons.mark_email_read_rounded, size: 18),
                    label: const Text('Send reset email'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FilledButton.icon(
                    onPressed: onResetPassword,
                    icon: const Icon(Icons.lock_reset_rounded, size: 18),
                    label: const Text('Reset password'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _chips('Subjects', subjects),
          const SizedBox(height: 6),
          _chips('Assigned', assignments),
        ],
      ),
    );
  }

  Widget _chips(String label, List<String> values) {
    if (values.isEmpty) {
      return Text(
        '$label: -',
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        for (final v in values)
          Chip(
            label: Text(v),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

List<String> _parseTeacherAssignments(Map<String, dynamic> data) {
  final raw = data['classes'];

  // New format: classes = [{classId, className, sectionId, sectionName}, ...]
  if (raw is List) {
    final labels = <String>[];
    for (final item in raw) {
      if (item is Map) {
        final className = (item['className'] ?? '').toString().trim();
        final sectionName = (item['sectionName'] ?? '').toString().trim();
        final classId = (item['classId'] ?? '').toString().trim();
        final sectionId = (item['sectionId'] ?? '').toString().trim();

        final c = className.isNotEmpty ? className : classId;
        final s = sectionName.isNotEmpty ? sectionName : sectionId;
        if (c.isEmpty && s.isEmpty) continue;

        if (c.isNotEmpty && s.isNotEmpty) {
          labels.add('Class $c$s');
        } else if (c.isNotEmpty) {
          labels.add('Class $c');
        } else {
          labels.add(s);
        }
      } else if (item != null) {
        // Old fallback: classes stored as List<String>
        final v = item.toString().trim();
        if (v.isNotEmpty) labels.add(v);
      }
    }
    if (labels.isNotEmpty) return labels;
  }

  // Older format: classes + sections stored separately.
  final classes = (data['classes'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
  final sections = (data['sections'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
  if (classes.isEmpty && sections.isEmpty) return const <String>[];

  // If we don't have pairing information, show a reasonable summary.
  if (classes.isNotEmpty && sections.isNotEmpty) {
    final minLen = classes.length < sections.length ? classes.length : sections.length;
    final paired = <String>[];
    for (var i = 0; i < minLen; i++) {
      final c = classes[i].trim();
      final s = sections[i].trim();
      if (c.isEmpty && s.isEmpty) continue;
      paired.add(s.isEmpty ? c : '$c $s');
    }
    if (paired.isNotEmpty) return paired;
  }

  return [...classes.where((e) => e.trim().isNotEmpty)];
}
