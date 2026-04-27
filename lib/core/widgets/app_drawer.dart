import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/rbac/app_navigation.dart';
import 'package:school_app/core/widgets/app_loader.dart';
import 'package:school_app/models/user_role.dart';
import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/core_providers.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:school_app/providers/school_modules_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return Material(
      color: const Color(0xFFF8FAFC),
      child: roleAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(child: Text('$e')),
        data: (role) {
          if (role == UserRole.admin) {
            final modulesAsync = ref.watch(schoolModulesProvider);

            return modulesAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (e, _) => Center(child: Text('$e')),
              data: (modules) => _DrawerBody(
                entries: AppNavigation.drawerEntriesFor(
                  role,
                  modules: modules,
                ),
              ),
            );
          }

          return _DrawerBody(
            entries: AppNavigation.drawerEntriesFor(role),
          );
        },
      ),
    );
  }
}

class _DrawerBody extends ConsumerWidget {
  const _DrawerBody({required this.entries});

  final List<AppNavEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);
    final current =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();

    final isWeb = MediaQuery.of(context).size.width >= 760;

    return schoolAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (e, _) => Center(child: Text('$e')),
      data: (school) {
        final data = school.data() ?? {};
        final schoolName = data['name'] ?? 'School';
        final email = data['email'] ?? '';
        final logo = data['logoUrl'] ?? data['logo'] ?? '';

        return Column(
          children: [
            /// SHOW SCHOOL INFO ONLY ON MOBILE
            if (!isWeb)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          logo.toString().isNotEmpty ? NetworkImage(logo) : null,
                      child: logo.toString().isEmpty
                          ? const Icon(Icons.school)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schoolName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            /// SHOW ADMIN TITLE ONLY ON MOBILE
            if (!isWeb)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School Admin',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Management Panel',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  for (final e in entries)
                    if (e.isHeader)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          top: 14,
                          bottom: 6,
                        ),
                        child: Text(
                          e.header!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      _Tile(
                        title: e.label!,
                        route: e.route!,
                        selected: current.startsWith(e.route!),
                      ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: _Tile(
                title: 'Logout',
                route: '/logout',
                selected: false,
                logout: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({
    required this.title,
    required this.route,
    required this.selected,
    this.logout = false,
  });

  final String title;
  final String route;
  final bool selected;
  final bool logout;

  IconData get icon {
    switch (title) {
      case 'Dashboard':
      case 'School Dashboard':
        return Icons.dashboard_rounded;
      case 'Teachers':
        return Icons.badge_rounded;
      case 'Students':
        return Icons.groups_rounded;
      case 'Classes':
        return Icons.class_rounded;
      case 'Attendance':
        return Icons.fact_check_rounded;
      case 'Homework':
        return Icons.menu_book_rounded;
      case 'Fees':
        return Icons.account_balance_wallet_rounded;
      case 'Announcements':
        return Icons.campaign_rounded;
      case 'Exam Types':
        return Icons.quiz_rounded;
      case 'Marks Card Templates':
        return Icons.description_rounded;
      case 'Reports':
        return Icons.bar_chart_rounded;
      case 'Analytics':
        return Icons.analytics_rounded;
      case 'Module Control':
        return Icons.settings_input_component_rounded;
      case 'Promote Students':
        return Icons.trending_up_rounded;
      case 'Logout':
        return Icons.logout_rounded;
      default:
        return Icons.circle;
    }
  }

  Color getBg() {
    switch (title) {
      case 'Dashboard':
        return const Color(0xFF4F7DF3);
      case 'Teachers':
        return const Color(0xFF38BDF8);
      case 'Students':
        return const Color(0xFFD946EF);
      case 'Classes':
        return const Color(0xFFF59E0B);
      case 'Attendance':
        return const Color(0xFF22C55E);
      case 'Homework':
        return const Color(0xFF6366F1);
      case 'Fees':
        return const Color(0xFF14B8A6);
      case 'Announcements':
        return const Color(0xFFF97316);
      case 'Exam Types':
        return const Color(0xFFEAB308);
      case 'Marks Card Templates':
        return const Color(0xFF64748B);
      case 'Reports':
        return const Color(0xFF0EA5E9);
      case 'Analytics':
        return const Color(0xFF8B5CF6);
      case 'Module Control':
        return const Color(0xFF475569);
      case 'Promote Students':
        return const Color(0xFF10B981);
      case 'Logout':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = selected;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        if (logout) {
          await ref.read(authServiceProvider).signOut();
          if (context.mounted) context.go('/');
          return;
        }

        context.go(route);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: getBg(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title == 'School Dashboard' ? 'Dashboard' : title,
                style: TextStyle(
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF334155),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: active
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}