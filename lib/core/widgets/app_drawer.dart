// FULL PREMIUM DRAWER 2026
// Replace entire file:
// lib/core/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/rbac/app_navigation.dart';
import 'package:school_app/core/widgets/app_loader.dart';
import 'package:school_app/features/data_center/screens/data_center_screen.dart';
import 'package:school_app/models/user_role.dart';
import 'package:school_app/providers/auth_provider.dart';
import 'package:school_app/providers/core_providers.dart';
import 'package:school_app/providers/school_modules_provider.dart';
import 'package:school_app/providers/current_school_provider.dart';

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
              data: (modules) {
                final entries = AppNavigation.drawerEntriesFor(
                  role,
                  modules: modules,
                );

                return _DrawerBody(entries: entries);
              },
            );
          }

          final entries = AppNavigation.drawerEntriesFor(role);
          return _DrawerBody(entries: entries);
        },
      ),
    );
  }
}

class _DrawerBody extends ConsumerWidget {
  const _DrawerBody({
    required this.entries,
  });

  final List<AppNavEntry> entries;

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 760;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    final current = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();

    final mobile = _isMobile(context);

    return schoolAsync.when(
      loading: () => const Center(child: AppLoader()),
      error: (e, _) => Center(child: Text('$e')),

        data: (school) {
        final data =
          school.data() ?? <String, dynamic>{};

        final schoolName =
          (data['name'] ?? 'School').toString();

        final email =
          (data['email'] ?? '').toString();

        final logo =
          (data['logoUrl'] ??
              data['logo'] ??
              '')
            .toString();

        return SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                  14,
                  mobile ? 14 : 18,
                  14,
                  14,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _SchoolLogo(logo: logo),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            schoolName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w800,
                              color:
                                  Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color:
                                  Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (mobile)
                      IconButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    10,
                    10,
                    10,
                    10,
                  ),
                  children: [
                    for (final e in entries)
                      if (e.isHeader)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            8,
                            14,
                            8,
                            6,
                          ),
                          child: Text(
                            e.header!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                              letterSpacing: .4,
                              color:
                                  Color(0xFF64748B),
                            ),
                          ),
                        )
                      else
                        _NavItem(
                          label:
                              _display(e.label!),
                          style:
                              _style(e.label!),
                          selected: _selected(
                            current,
                            e.route!,
                          ),
                          onTap: () {
                            Navigator.of(context)
                                .maybePop();

                            context.go(
                              e.route!,
                            );
                          },
                        ),

                    const SizedBox(height: 8),

                    const Padding(
                      padding:
                          EdgeInsets.fromLTRB(
                        8,
                        14,
                        8,
                        6,
                      ),
                      child: Text(
                        'DATA TOOLS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing: .4,
                          color:
                              Color(0xFF64748B),
                        ),
                      ),
                    ),

                    _NavItem(
                      label: 'Data Center',
                      style:
                          _style('Data Center'),
                      selected:
                          current ==
                              '/school-admin/data-center',
                      onTap: () {
                        Navigator.of(context)
                            .maybePop();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DataCenterScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.all(10),
                decoration:
                    const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color:
                          Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: _NavItem(
                  label: 'Logout',
                  style: const _ItemStyle(
                    icon:
                        Icons.logout_rounded,
                    start:
                        Color(0xFFEF4444),
                    end:
                        Color(0xFFF97316),
                  ),
                  selected: false,
                  onTap: () async {
                    await ref
                        .read(
                          authServiceProvider,
                        )
                        .signOut();

                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _selected(
    String current,
    String route,
  ) {
    if (route == '/school-admin' &&
        current == '/school-admin') {
      return true;
    }

    if (route != '/school-admin' &&
        current.startsWith(route)) {
      return true;
    }

    return false;
  }

  String _display(String label) {
    if (label == 'School Dashboard') {
      return 'Dashboard';
    }
    return label;
  }

  _ItemStyle _style(String raw) {
    final label = _display(raw);

    switch (label) {
      case 'Dashboard':
        return const _ItemStyle(
          icon:
              Icons.dashboard_rounded,
          start:
              Color(0xFF3B82F6),
          end:
              Color(0xFF2563EB),
        );

      case 'Teachers':
        return const _ItemStyle(
          icon:
              Icons.badge_rounded,
          start:
              Color(0xFF06B6D4),
          end:
              Color(0xFF0EA5E9),
        );

      case 'Students':
        return const _ItemStyle(
          icon:
              Icons.groups_rounded,
          start:
              Color(0xFFEC4899),
          end:
              Color(0xFF8B5CF6),
        );

      case 'Classes':
        return const _ItemStyle(
          icon:
              Icons.class_rounded,
          start:
              Color(0xFFF59E0B),
          end:
              Color(0xFFF97316),
        );

      case 'Attendance':
        return const _ItemStyle(
          icon:
              Icons.fact_check_rounded,
          start:
              Color(0xFF10B981),
          end:
              Color(0xFF22C55E),
        );

      case 'Homework':
        return const _ItemStyle(
          icon:
              Icons.menu_book_rounded,
          start:
              Color(0xFF6366F1),
          end:
              Color(0xFF3B82F6),
        );

      case 'Fees':
        return const _ItemStyle(
          icon:
              Icons.account_balance_wallet_rounded,
          start:
              Color(0xFF14B8A6),
          end:
              Color(0xFF06B6D4),
        );

      case 'Announcements':
        return const _ItemStyle(
          icon:
              Icons.campaign_rounded,
          start:
              Color(0xFFF97316),
          end:
              Color(0xFFEF4444),
        );

      case 'Exam Types':
        return const _ItemStyle(
          icon:
              Icons.quiz_rounded,
          start:
              Color(0xFFEAB308),
          end:
              Color(0xFFF59E0B),
        );

      case 'Marks Card Templates':
        return const _ItemStyle(
          icon:
              Icons.description_rounded,
          start:
              Color(0xFF64748B),
          end:
              Color(0xFF475569),
        );

      case 'Reports':
        return const _ItemStyle(
          icon:
              Icons.bar_chart_rounded,
          start:
              Color(0xFF0EA5E9),
          end:
              Color(0xFF2563EB),
        );

      case 'Analytics':
        return const _ItemStyle(
          icon:
              Icons.analytics_rounded,
          start:
              Color(0xFF8B5CF6),
          end:
              Color(0xFF6366F1),
        );

      case 'Data Center':
        return const _ItemStyle(
          icon:
              Icons.storage_rounded,
          start:
              Color(0xFF111827),
          end:
              Color(0xFF334155),
        );

      default:
        return const _ItemStyle(
          icon:
              Icons.circle_rounded,
          start:
              Color(0xFF94A3B8),
          end:
              Color(0xFF64748B),
        );
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final _ItemStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF0F172A);

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          height: 54,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            color: selected
                ? const Color(
                    0xFFEFF4FF,
                  )
                : Colors.transparent,
            border: selected
                ? Border.all(
                    color: const Color(
                      0xFFCFE0FF,
                    ),
                  )
                : null,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(
                        0x142563EB,
                      ),
                      blurRadius: 14,
                      offset: Offset(
                        0,
                        8,
                      ),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                  gradient:
                      LinearGradient(
                    colors: [
                      style.start,
                      style.end,
                    ],
                  ),
                ),
                child: Icon(
                  style.icon,
                  size: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: selected
                    ? const Color(
                        0xFF1D4ED8,
                      )
                    : const Color(
                        0xFF94A3B8,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchoolLogo extends StatelessWidget {
  const _SchoolLogo({
    required this.logo,
  });

  final String logo;

  @override
  Widget build(BuildContext context) {
    if (logo.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(14),
        child: Image.network(
          logo,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) =>
                  _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF06B6D4),
          ],
        ),
      ),
      child: const Icon(
        Icons.school_rounded,
        color: Colors.white,
      ),
    );
  }
}

class _ItemStyle {
  const _ItemStyle({
    required this.icon,
    required this.start,
    required this.end,
  });

  final IconData icon;
  final Color start;
  final Color end;
}