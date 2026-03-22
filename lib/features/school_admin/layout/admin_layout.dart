import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/search/global_search_dialog.dart';
import 'package:school_app/core/widgets/app_drawer.dart';
import 'package:school_app/providers/core_providers.dart';

class AdminLayout extends ConsumerWidget {
  const AdminLayout({
    super.key,
    required this.body,
    this.title = 'Dashboard',
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

  static const Color _bgColor = Color(0xFFF4F7FB);
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
          if (enableTopbar && isDesktop)
            _TopBar(
              title: title,
              actions: actions,
              isDesktop: true,
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
                  maxWidth: isDesktop ? 1480 : (isTablet ? 1100 : double.infinity),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 20 : 14,
                    vertical: isDesktop ? 20 : 14,
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
              width: 248,
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
final isDashboard = title == 'Dashboard';
final pageStyle = _pageStyleForTitle(title);

return Scaffold(
  backgroundColor: _bgColor,
  drawer: isDashboard ? const AppDrawer() : null,
  drawerEdgeDragWidth: 24,
  appBar: enableTopbar
      ? AppBar(
          toolbarHeight: 66,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _cardColor,
          surfaceTintColor: _cardColor,
          automaticallyImplyLeading: false,
          leadingWidth: 52,
          leading: isDashboard
              ? Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: _textColor,
                      size: 22,
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'Back',
                  onPressed: () => context.go('/school-admin'),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _textColor,
                    size: 20,
                  ),
                ),
          titleSpacing: 4,
          title: Row(
            children: [
              if (!isDashboard) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [pageStyle.startColor, pageStyle.endColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pageStyle.startColor.withOpacity(0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    pageStyle.icon,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  isDashboard ? 'Dashboard' : title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          actions: isDashboard
              ? [
                  if (actions != null) ...actions!,
                  IconButton(
                    tooltip: 'Search',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => GlobalSearchDialog.open(context),
                    icon: const Icon(
                      Icons.search_rounded,
                      color: _textColor,
                      size: 21,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notifications',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.go('/school-admin/notifications'),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: _textColor,
                      size: 21,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: PopupMenuButton<String>(
                      tooltip: 'Profile',
                      icon: const Icon(
                        Icons.account_circle_outlined,
                        color: _textColor,
                        size: 22,
                      ),
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
                  ),
                ]
              : null,
        )
      : null,
  body: content,
  floatingActionButton: floatingActionButton,
  floatingActionButtonLocation: floatingActionButtonLocation,
);

  }

  _PageStyle _pageStyleForTitle(String title) {
    switch (title) {
      case 'Teachers':
        return const _PageStyle(
          icon: Icons.badge_rounded,
          startColor: Color(0xFF0EA5E9),
          endColor: Color(0xFF06B6D4),
        );
      case 'Students':
        return const _PageStyle(
          icon: Icons.groups_rounded,
          startColor: Color(0xFFEC4899),
          endColor: Color(0xFF8B5CF6),
        );
      case 'Classes':
        return const _PageStyle(
          icon: Icons.meeting_room_rounded,
          startColor: Color(0xFFF59E0B),
          endColor: Color(0xFFF97316),
        );
      case 'Attendance':
        return const _PageStyle(
          icon: Icons.fact_check_rounded,
          startColor: Color(0xFF10B981),
          endColor: Color(0xFF22C55E),
        );
      case 'Homework':
        return const _PageStyle(
          icon: Icons.menu_book_rounded,
          startColor: Color(0xFF6366F1),
          endColor: Color(0xFF3B82F6),
        );
      case 'Fees':
        return const _PageStyle(
          icon: Icons.account_balance_wallet_rounded,
          startColor: Color(0xFF14B8A6),
          endColor: Color(0xFF06B6D4),
        );
      case 'Announcements':
        return const _PageStyle(
          icon: Icons.campaign_rounded,
          startColor: Color(0xFFF97316),
          endColor: Color(0xFFEF4444),
        );
      case 'Exam Types':
        return const _PageStyle(
          icon: Icons.quiz_rounded,
          startColor: Color(0xFFEAB308),
          endColor: Color(0xFFF59E0B),
        );
      case 'Marks Card Templates':
        return const _PageStyle(
          icon: Icons.description_rounded,
          startColor: Color(0xFF64748B),
          endColor: Color(0xFF475569),
        );
      case 'Reports':
        return const _PageStyle(
          icon: Icons.insert_chart_rounded,
          startColor: Color(0xFF06B6D4),
          endColor: Color(0xFF2563EB),
        );
      case 'Analytics':
        return const _PageStyle(
          icon: Icons.analytics_rounded,
          startColor: Color(0xFF8B5CF6),
          endColor: Color(0xFF6366F1),
        );
      case 'Module Control':
        return const _PageStyle(
          icon: Icons.tune_rounded,
          startColor: Color(0xFF475569),
          endColor: Color(0xFF334155),
        );
      case 'Promote Students':
        return const _PageStyle(
          icon: Icons.trending_up_rounded,
          startColor: Color(0xFF22C55E),
          endColor: Color(0xFF16A34A),
        );
      default:
        return const _PageStyle(
          icon: Icons.dashboard_rounded,
          startColor: Color(0xFF94A3B8),
          endColor: Color(0xFF64748B),
        );
    }
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
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 22),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isDesktop)
                  const Text(
                    'Manage your school operations from one place',
                    style: TextStyle(
                      color: _subtleTextColor,
                      fontSize: 12,
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
                  Icon(Icons.account_circle_outlined, color: _textColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Icon(icon, color: _textColor, size: 20),
        ),
      ),
    );
  }
}

class _PageStyle {
  const _PageStyle({
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final IconData icon;
  final Color startColor;
  final Color endColor;
}