import 'package:flutter/material.dart';

enum GlobalSearchResultType {
  student,
  teacher,
  classItem,
}

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    this.icon,
  });

  final GlobalSearchResultType type;
  final String id;
  final String title;
  final String subtitle;

  /// GoRouter route to navigate to.
  final String route;

  final IconData? icon;

  String get typeLabel {
    switch (type) {
      case GlobalSearchResultType.student:
        return 'Student';
      case GlobalSearchResultType.teacher:
        return 'Teacher';
      case GlobalSearchResultType.classItem:
        return 'Class';
    }
  }
}
