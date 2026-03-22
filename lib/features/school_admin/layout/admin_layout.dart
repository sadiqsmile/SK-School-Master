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

  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _subtleTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  bool _isDesktop(double width) => width >= 1100;
  bool _isTablet(double width) => width >= 700 && width < 1100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = _isDesktop(width);
    final isTablet = _isTablet(width);

    final content = Container(
      color: _bgColor,
      child: Column(
        children: [
          if (enableTopbar)
            _TopBar(
              title: title,
              actions: actions,
              isDesktop: isDesktop,
              onSearch: () => GlobalSearchDialog.open(context),
              onNotifications: () => context.go('/school-admin/notifications'),
              onLogout: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/');
              },
            ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1400 : (isTablet ? 1100 : double.infinity),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: isDesktop ? 24 : 16,
                  ),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Row(
          children: [
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: _cardColor,
                border: Border(
                  right: BorderSide(color: _borderColor),
                ),
              ),
              child: const SafeArea(
                child: AppDrawer(),
              ),
            ),
            Expanded(child: content),
          ],
        ),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      drawer: const AppDrawer(),
      appBar: enableTopbar
          ? AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: _cardColor,
              surfaceTintColor: _cardColor,
              iconTheme: const IconThemeData(color: _textColor),
              title: Text(
  title == 'Dashboard' ? 'SK School Master' : title,
                style: const TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                if (actions != null) ...actions!,
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => GlobalSearchDialog.open(context),
                  icon: const Icon(Icons.search_rounded, color: _textColor),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => context.go('/school-admin/notifications'),
                  icon: const Icon(Icons.notifications_none_rounded, color: _textColor),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Profile',
                  icon: const Icon(Icons.account_circle_outlined, color: _textColor),
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
            )
          : null,
      body: content,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.actions,
    required this.isDesktop,
    required this.onSearch,
    required this.onNotifications,
    required this.onLogout,
  });

  final String title;
  final List<Widget>? actions;
  final bool isDesktop;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final Future<void> Function() onLogout;

  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _subtleTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _cardColor,
        border: Border(
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isDesktop)
                  const Text(
                    'Manage your school operations from one place',
                    style: TextStyle(
                      color: _subtleTextColor,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
          _TopbarIconButton(
            tooltip: 'Search',
            icon: Icons.search_rounded,
            onTap: onSearch,
          ),
          const SizedBox(width: 8),
          _TopbarIconButton(
            tooltip: 'Notifications',
            icon: Icons.notifications_none_rounded,
            onTap: onNotifications,
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Profile',
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) async {
              if (v == 'logout') {
                await onLogout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_circle_outlined, color: _textColor),
                  SizedBox(width: 8),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, color: _subtleTextColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopbarIconButton extends StatelessWidget {
  const _TopbarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _textColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Icon(icon, color: _textColor, size: 22),
        ),
      ),
    );
  }
}