import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/parent/providers/parent_notifications_provider.dart';

class ParentNotificationsScreen extends ConsumerWidget {
  const ParentNotificationsScreen({super.key});

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

  (IconData, Color) _iconFor(String type) {
    switch (type) {
      case 'attendance_alert':
        return (Icons.fact_check_rounded, const Color(0xFFEF4444));
      case 'homework_created':
        return (Icons.menu_book_rounded, const Color(0xFF7C3AED));
      case 'fee_pending':
        return (Icons.currency_rupee_rounded, const Color(0xFFF59E0B));
      case 'exam_marks_updated':
        return (Icons.school_rounded, const Color(0xFF2563EB));
      case 'announcement':
        return (Icons.campaign_rounded, const Color(0xFF0EA5E9));
      default:
        return (Icons.notifications_rounded, const Color(0xFF0EA5E9));
    }
  }

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    return '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _markRead(DocumentReference<Map<String, dynamic>> ref) async {
    await ref.set(
      {'readAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bg = Color(0xFFF8FAFC);
    final feedAsync = ref.watch(parentNotificationsProvider(80));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
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
                final readAt = _readTime(data, 'readAt');
                final isUnread = readAt == null;

                final (icon, tint) = _iconFor(type);
                final timeLabel = _formatTime(created);

                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tint.withAlpha(30),
                      child: Icon(icon, color: tint),
                    ),
                    title: Text(
                      title.isEmpty ? '(Notification)' : title,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (body.isNotEmpty)
                          Text(
                            body,
                            style: TextStyle(
                              color: isUnread ? const Color(0xFF111827) : const Color(0xFF475569),
                            ),
                          ),
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
                    trailing: isUnread
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () async {
                      try {
                        await _markRead(doc.reference);
                        if (!context.mounted) return;
                        await showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(title.isEmpty ? 'Notification' : title),
                            content: Text(body.isEmpty ? '(No details)' : body),
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
                          SnackBar(content: Text('Failed to mark read: $e')),
                        );
                      }
                    },
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
