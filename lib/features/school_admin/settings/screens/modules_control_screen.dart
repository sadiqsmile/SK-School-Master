import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/models/school_modules.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/providers/school_modules_provider.dart';

class ModulesControlScreen extends ConsumerWidget {
  const ModulesControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(schoolModulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Control'),
      ),
      body: modulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load modules: $e'),
          ),
        ),
        data: (modules) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: const Color(0xFFF8FAFC),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turn modules ON/OFF',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Disabled modules are hidden in menus and access is blocked (e.g., Parents cannot login if “Parents App” is OFF).',
                        style: TextStyle(color: Colors.black54, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ModuleSwitch(
                keyName: SchoolModuleKey.teachers,
                value: modules.teachers,
              ),
              _ModuleSwitch(
                keyName: SchoolModuleKey.students,
                value: modules.students,
              ),
              _ModuleSwitch(
                keyName: SchoolModuleKey.attendance,
                value: modules.attendance,
              ),
              _ModuleSwitch(
                keyName: SchoolModuleKey.exams,
                value: modules.exams,
              ),
              _ModuleSwitch(
                keyName: SchoolModuleKey.parents,
                value: modules.parents,
              ),
              _ModuleSwitch(
                keyName: SchoolModuleKey.fees,
                value: modules.fees,
              ),
              _ModuleSwitch(
                keyName: SchoolModuleKey.homework,
                value: modules.homework,
              ),
              _ModuleSwitch(
                keyName: SchoolModuleKey.messages,
                value: modules.messages,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  final schoolId = await ref.read(schoolIdProvider.future);
                  await ref
                      .read(schoolModulesServiceProvider)
                      .setModules(schoolId: schoolId, modules: modules);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Modules saved')),
                  );
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save (re-write full config)'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tip: Changes apply immediately for all users who are online.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModuleSwitch extends ConsumerWidget {
  const _ModuleSwitch({
    required this.keyName,
    required this.value,
  });

  final SchoolModuleKey keyName;
  final bool value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: SwitchListTile(
        title: Text(
          keyName.label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        value: value,
        onChanged: (v) async {
          final schoolId = await ref.read(schoolIdProvider.future);
          await ref
              .read(schoolModulesServiceProvider)
              .setModule(schoolId: schoolId, key: keyName, enabled: v);
        },
      ),
    );
  }
}
