import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app/core/rbac/app_navigation.dart';
import 'package:school_app/core/widgets/app_loader.dart';
import 'package:school_app/models/user_role.dart';
import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/core_providers.dart';
import 'package:school_app/providers/school_modules_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return Material(
      color: Colors.white,
      child: roleAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load menu: $e'),
          ),
        ),
        data: (role) {
          if (role == UserRole.admin) {
            final modulesAsync = ref.watch(schoolModulesProvider);
            return modulesAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load modules: $e'),
                ),
              ),
              data: (modules) {
                final entries = AppNavigation.drawerEntriesFor(
                  role,
                  modules: modules,
                );
                return _DrawerList(entries: entries, role: role);
              },
            );
          }

          final entries = AppNavigation.drawerEntriesFor(role);
          return _DrawerList(entries: entries, role: role);
        },
      ),
    );
  }
}

class _DrawerList extends ConsumerWidget {
  const _DrawerList({
    required this.entries,
    required this.role,
  });

  final List<AppNavEntry> entries;
  final UserRole role;

  static const Color _sidebarBg = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedText = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _activeBg = Color(0xFFF6F8FF);

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    final isMobile = _isMobile(context);

    return Container(
      color: _sidebarBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, isMobile ? 16 : 18, 16, 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _borderColor),
              ),
            ),
            child: isMobile
                ? Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x332563EB),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppNavigation.roleTitle(role),
                          style: const TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x332563EB),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppNavigation.roleTitle(role),
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No menu items for this role.',
                      style: TextStyle(color: _mutedText),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    children: [
                      for (final e in entries)
                        if (e.isHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                            child: Text(
                              e.header!,
                              style: const TextStyle(
                                color: _mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          )
                        else
                          _NavTile(
                            style: _menuStyleForLabel(e.label!),
                            label: e.label!,
                            route: e.route!,
                            selected: _isSelected(currentLocation, e.route!),
                            onTap: () {
                              Navigator.of(context).maybePop();
                              context.go(e.route!);
                            },
                          ),
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _borderColor),
              ),
            ),
            child: _NavTile(
              style: const _MenuItemStyle(
                icon: Icons.logout_rounded,
                startColor: Color(0xFFEF4444),
                endColor: Color(0xFFF97316),
              ),
              label: 'Logout',
              route: '',
              selected: false,
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go('/');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isSelected(String currentLocation, String route) {
    if (route == '/school-admin' && currentLocation == '/school-admin') {
      return true;
    }
    if (route != '/school-admin' && currentLocation.startsWith(route)) {
      return true;
    }
    return false;
  }

  _MenuItemStyle _menuStyleForLabel(String label) {
    switch (label) {
      case 'Dashboard':
        return const _MenuItemStyle(
          icon: Icons.space_dashboard_rounded,
          startColor: Color(0xFF4F46E5),
          endColor: Color(0xFF7C3AED),
        );
      case 'Teachers':
        return const _MenuItemStyle(
          icon: Icons.badge_rounded,
          startColor: Color(0xFF0EA5E9),
          endColor: Color(0xFF06B6D4),
        );
      case 'Students':
        return const _MenuItemStyle(
          icon: Icons.groups_rounded,
          startColor: Color(0xFFEC4899),
          endColor: Color(0xFF8B5CF6),
        );
      case 'Classes':
        return const _MenuItemStyle(
          icon: Icons.meeting_room_rounded,
          startColor: Color(0xFFF59E0B),
          endColor: Color(0xFFF97316),
        );
      case 'Attendance':
        return const _MenuItemStyle(
          icon: Icons.fact_check_rounded,
          startColor: Color(0xFF10B981),
          endColor: Color(0xFF22C55E),
        );
      case 'Homework':
        return const _MenuItemStyle(
          icon: Icons.menu_book_rounded,
          startColor: Color(0xFF6366F1),
          endColor: Color(0xFF3B82F6),
        );
      case 'Fees':
        return const _MenuItemStyle(
          icon: Icons.account_balance_wallet_rounded,
          startColor: Color(0xFF14B8A6),
          endColor: Color(0xFF06B6D4),
        );
      case 'Announcements':
        return const _MenuItemStyle(
          icon: Icons.campaign_rounded,
          startColor: Color(0xFFF97316),
          endColor: Color(0xFFEF4444),
        );
      case 'Exam Types':
        return const _MenuItemStyle(
          icon: Icons.quiz_rounded,
          startColor: Color(0xFFEAB308),
          endColor: Color(0xFFF59E0B),
        );
      case 'Marks Card Templates':
        return const _MenuItemStyle(
          icon: Icons.description_rounded,
          startColor: Color(0xFF64748B),
          endColor: Color(0xFF475569),
        );
      case 'Reports':
        return const _MenuItemStyle(
          icon: Icons.insert_chart_rounded,
          startColor: Color(0xFF06B6D4),
          endColor: Color(0xFF2563EB),
        );
      case 'Analytics':
        return const _MenuItemStyle(
          icon: Icons.analytics_rounded,
          startColor: Color(0xFF8B5CF6),
          endColor: Color(0xFF6366F1),
        );
      case 'Module Control':
        return const _MenuItemStyle(
          icon: Icons.tune_rounded,
          startColor: Color(0xFF475569),
          endColor: Color(0xFF334155),
        );
      case 'Promote Students':
        return const _MenuItemStyle(
          icon: Icons.trending_up_rounded,
          startColor: Color(0xFF22C55E),
          endColor: Color(0xFF16A34A),
        );
      default:
        return const _MenuItemStyle(
          icon: Icons.circle_rounded,
          startColor: Color(0xFF94A3B8),
          endColor: Color(0xFF64748B),
        );
    }
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.style,
    required this.label,
    required this.route,
    required this.selected,
    required this.onTap,
  });

  final _MenuItemStyle style;
  final String label;
  final String route;
  final bool selected;
  final VoidCallback onTap;

  static const Color _primaryDark = Color(0xFF1D4ED8);
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _activeBg = Color(0xFFF1F5FF);

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? _primaryDark : _textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? _activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(color: const Color(0xFFD6E4FF))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: LinearGradient(
                      colors: [style.startColor, style.endColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: style.startColor.withOpacity(0.22),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    style.icon,
                    color: Colors.white,
                    size: 14.5,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label == 'Dashboard' ? 'School Dashboard' : label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _primaryDark,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemStyle {
  const _MenuItemStyle({
    required this.icon,
    required this.startColor,
    required this.endColor,
  });

  final IconData icon;
  final Color startColor;
  final Color endColor;
}