import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/features/school_admin/notifications/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _readString(Map<String, dynamic> data, String key) {
    return (data[key] ?? '').toString();
  }

  DateTime? _readTime(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bg = Color(0xFFF8FAFC);

    final feedAsync = ref.watch(schoolNotificationsProvider(80));

    return AdminLayout(
      title: 'Notifications',
      body: Container(
        color: bg,
        child: feedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load notifications: $e')),
          data: (snap) {
            if (snap.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No notifications yet.'),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: snap.docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final doc = snap.docs[i];
                final data = doc.data();

                final type = _readString(data, 'type');
                final title = _readString(data, 'title');
                final body = _readString(data, 'body');
                final created = _readTime(data, 'createdAt');

                IconData icon;
                Color tint;
                switch (type) {
                  case 'attendance_marked':
                    icon = Icons.fact_check_rounded;
                    tint = const Color(0xFF8B5CF6);
                    break;
                  case 'student_high_risk':
                    icon = Icons.warning_amber_rounded;
                    tint = const Color(0xFFEF4444);
                    break;
                  default:
                    icon = Icons.notifications_rounded;
                    tint = const Color(0xFF0EA5E9);
                }

                final timeLabel = created == null
                    ? ''
                    : '${created.year.toString().padLeft(4, '0')}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} '
                        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tint.withAlpha(30),
                      child: Icon(icon, color: tint),
                    ),
                    title: Text(
                      title.isEmpty ? '(Notification)' : title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (body.isNotEmpty) Text(body),
                        if (timeLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              timeLabel,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
