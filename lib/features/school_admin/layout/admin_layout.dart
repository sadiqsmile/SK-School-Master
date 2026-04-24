import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/search/global_search_dialog.dart';
import 'package:school_app/core/widgets/app_drawer.dart';
import 'package:school_app/providers/current_school_provider.dart';

class AdminLayout extends ConsumerWidget {
  const AdminLayout({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  static const bg = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final desktop = width >= 1100;
    final mobile = width < 700;

    final schoolAsync = ref.watch(currentSchoolProvider);

    return schoolAsync.when(
      data: (school) {
        final data = school.data() ?? {};

        final schoolName =
            (data['name'] ?? 'School').toString();

        final logo =
            (data['logo'] ?? '').toString();

        final email =
            (data['email'] ?? '').toString();

        final page = _pageData(title);

        final bodyWidget = Container(
          color: bg,
          child: Column(
            children: [
              mobile
                  ? _MobileHeader(
                      schoolName: schoolName,
                      email: email,
                      logo: logo,
                      page: page,
                    )
                  : _TopBar(page: page),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: body,
                ),
              ),
            ],
          ),
        );

        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: _SidebarWrapper(
                    schoolName: schoolName,
                    email: email,
                    logo: logo,
                  ),
                ),
                Expanded(child: bodyWidget),
              ],
            ),
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation:
                floatingActionButtonLocation,
          );
        }

        return Scaffold(
          drawer: const AppDrawer(),
          body: SafeArea(child: bodyWidget),
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation:
              floatingActionButtonLocation,
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('$e')),
      ),
    );
  }
}

class _SidebarWrapper extends StatelessWidget {
  const _SidebarWrapper({
    required this.schoolName,
    required this.email,
    required this.logo,
  });

  final String schoolName;
  final String email;
  final String logo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: logo.isNotEmpty
                      ? NetworkImage(logo)
                      : null,
                  child: logo.isEmpty
                      ? const Icon(Icons.school)
                      : null,
                ),
                const SizedBox(width: 10),
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
                              FontWeight.w700,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: AppDrawer()),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.page,
  });

  final _PageMeta page;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: page.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              page.icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          Text(
            page.label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),

          const Spacer(),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.schoolName,
    required this.email,
    required this.logo,
    required this.page,
  });

  final String schoolName;
  final String email;
  final String logo;
  final _PageMeta page;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        12,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: logo.isNotEmpty
                    ? NetworkImage(logo)
                    : null,
                child: logo.isEmpty
                    ? const Icon(Icons.school)
                    : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  children: [
                    Text(
                      schoolName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Builder(
                builder: (context) =>
                    IconButton(
                  onPressed: () =>
                      Scaffold.of(context)
                          .openDrawer(),
                  icon:
                      const Icon(Icons.menu),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: page.color,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  page.icon,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  page.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    GlobalSearchDialog.open(
                        context),
                icon:
                    const Icon(Icons.search),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageMeta {
  final IconData icon;
  final Color color;
  final String label;

  const _PageMeta(
    this.icon,
    this.color,
    this.label,
  );
}

_PageMeta _pageData(String title) {
  final t = title.toLowerCase();

  if (t.contains('dashboard')) {
    return const _PageMeta(
      Icons.dashboard_customize_rounded,
      Color(0xFF3B82F6),
      'Dashboard',
    );
  }

  if (t.contains('teacher')) {
    return const _PageMeta(
      Icons.badge_rounded,
      Color(0xFF0EA5E9),
      'Teachers',
    );
  }

  if (t.contains('student')) {
    return const _PageMeta(
      Icons.groups_rounded,
      Color(0xFF8B5CF6),
      'Students',
    );
  }

  if (t.contains('class')) {
    return const _PageMeta(
      Icons.meeting_room_rounded,
      Color(0xFFF59E0B),
      'Classes',
    );
  }

  if (t.contains('attendance')) {
    return const _PageMeta(
      Icons.fact_check_rounded,
      Color(0xFF22C55E),
      'Attendance',
    );
  }

  if (t.contains('homework')) {
    return const _PageMeta(
      Icons.menu_book_rounded,
      Color(0xFF6366F1),
      'Homework',
    );
  }

  if (t.contains('fee')) {
    return const _PageMeta(
      Icons.account_balance_wallet_rounded,
      Color(0xFF06B6D4),
      'Fees',
    );
  }

  if (t.contains('announcement')) {
    return const _PageMeta(
      Icons.campaign_rounded,
      Color(0xFFEF4444),
      'Announcements',
    );
  }

  if (t.contains('exam')) {
    return const _PageMeta(
      Icons.quiz_rounded,
      Color(0xFFEAB308),
      'Exam Types',
    );
  }

  if (t.contains('report')) {
    return const _PageMeta(
      Icons.insert_chart_rounded,
      Color(0xFF2563EB),
      'Reports',
    );
  }

  if (t.contains('analytic')) {
    return const _PageMeta(
      Icons.analytics_rounded,
      Color(0xFF7C3AED),
      'Analytics',
    );
  }

  return const _PageMeta(
    Icons.grid_view_rounded,
    Color(0xFF3B82F6),
    'Dashboard',
  );
}