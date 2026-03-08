import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/rbac/app_navigation.dart';
import 'package:school_app/core/widgets/app_loader.dart';
import 'package:school_app/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: roleAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load menu: $e'),
          ),
        ),
        data: (role) {
          final entries = AppNavigation.drawerEntriesFor(role);

          return ListView(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    AppNavigation.roleTitle(role),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No menu items for this role.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              else
                for (final e in entries)
                  if (e.isHeader)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Text(
                        e.header!,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    ListTile(
                      leading: Icon(
                        e.icon,
                        color: const Color(0xFF1E40AF),
                      ),
                      title: Text(e.label!),
                      onTap: () {
                        Navigator.of(context).maybePop();
                        context.go(e.route!);
                      },
                    ),
            ],
          );
        },
      ),
    );
  }
}
