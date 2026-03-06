// features/school_admin/layout/topbar.dart
import 'package:flutter/material.dart';

class Topbar extends StatelessWidget implements PreferredSizeWidget {
  const Topbar({super.key, this.title = 'School Admin'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
