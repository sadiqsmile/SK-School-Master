import 'package:flutter/material.dart';

import 'package:school_app/models/announcement.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  const AnnouncementDetailScreen({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final title = announcement.title.trim().isEmpty
        ? 'Announcement'
        : announcement.title.trim();

    final date = announcement.createdAt;
    final dateLabel = date == null
        ? null
        : '${date.day.toString().padLeft(2, '0')} '
            '${_month(date.month)} '
            '${date.year}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (dateLabel != null)
            Text(
              'Date: $dateLabel',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (dateLabel != null) const SizedBox(height: 12),
          Text(
            announcement.message.trim().isEmpty
                ? '(No message)'
                : announcement.message.trim(),
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}

String _month(int m) {
  const months = <int, String>{
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sep',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
  };
  return months[m] ?? '';
}
