// features/school_admin/layout/admin_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/widgets/app_drawer.dart';
import 'package:school_app/core/search/global_search_dialog.dart';
import 'package:school_app/providers/core_providers.dart';

class AdminLayout extends ConsumerWidget {
  const AdminLayout({
    super.key,
    required this.body,
    this.title = 'School Admin Dashboard',
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.enableTopbar = true,
  });

  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool enableTopbar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (actions != null) ...actions!,
          if (enableTopbar) ...[
            IconButton(
              tooltip: 'Search',
              onPressed: () => GlobalSearchDialog.open(context),
              icon: const Icon(Icons.search_rounded, color: Colors.white),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.go('/school-admin/notifications'),
              icon: const Icon(Icons.notifications_rounded, color: Colors.white),
            ),
            PopupMenuButton<String>(
              tooltip: 'Profile',
              icon: const Icon(Icons.account_circle_rounded, color: Colors.white),
              onSelected: (v) async {
                if (v == 'logout') {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/');
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ],
            ),
          ],
        ],
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
