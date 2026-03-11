// features/super_admin/screens/schools_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/providers/super_admin_provider.dart';

class SchoolsScreen extends ConsumerWidget {
  const SchoolsScreen({super.key, this.searchQuery = ''});

  final String searchQuery;

  String _resolveSchoolName(Map<String, dynamic> data, String fallbackId) {
    final schoolName = (data['schoolName'] ?? '').toString().trim();
    final name = (data['name'] ?? '').toString().trim();
    final displayName = (data['displayName'] ?? '').toString().trim();

    bool isGeneric(String value) {
      final normalized = value.toLowerCase();
      return normalized == 'school' || normalized == 'schools';
    }

    if (schoolName.isNotEmpty && !isGeneric(schoolName)) return schoolName;
    if (name.isNotEmpty && !isGeneric(name)) return name;
    if (displayName.isNotEmpty && !isGeneric(displayName)) return displayName;

    if (schoolName.isNotEmpty) return schoolName;
    if (name.isNotEmpty) return name;
    if (displayName.isNotEmpty) return displayName;
    return fallbackId;
  }

  static const List<Map<String, dynamic>> _gradientPalettes = [
    {
      'name': 'Ocean Wave',
      'colors': ['#06B6D4', '#3B82F6', '#1E40AF'],
    },
    {
      'name': 'Sunset Blaze',
      'colors': ['#F59E0B', '#EC4899', '#8B5CF6'],
    },
    {
      'name': 'Forest Fresh',
      'colors': ['#10B981', '#14B8A6', '#06B6D4'],
    },
    {
      'name': 'Royal Purple',
      'colors': ['#8B5CF6', '#A855F7', '#EC4899'],
    },
    {
      'name': 'Fire Flame',
      'colors': ['#EF4444', '#F97316', '#F59E0B'],
    },
    {
      'name': 'Cool Mint',
      'colors': ['#14B8A6', '#10B981', '#84CC16'],
    },
    {
      'name': 'Night Sky',
      'colors': ['#1E3A8A', '#7C3AED', '#EC4899'],
    },
    {
      'name': 'Warm Sunset',
      'colors': ['#EC4899', '#FB923C', '#FDE047'],
    },
    {
      'name': 'Deep Ocean',
      'colors': ['#0891B2', '#3B82F6', '#6366F1'],
    },
    {
      'name': 'Tropical Paradise',
      'colors': ['#84CC16', '#14B8A6', '#0EA5E9'],
    },
  ];

  Color _hexToColor(String hex) {
    final normalized = hex.replaceAll('#', '');
    final value = int.tryParse('FF$normalized', radix: 16) ?? 0xFF1976D2;
    return Color(value);
  }

  List<Color> _getGradientColors(List<dynamic>? colorList) {
    if (colorList == null || colorList.isEmpty) {
      return [
        const Color(0xFF06B6D4),
        const Color(0xFF3B82F6),
        const Color(0xFF1E40AF),
      ];
    }
    return colorList.map((c) => _hexToColor(c.toString())).toList();
  }

  List<String>? _readCurrentThemeHex(Map<String, dynamic> data) {
    final primary = (data['themeColorPrimary'] ?? '').toString().trim();
    final secondary = (data['themeColorSecondary'] ?? '').toString().trim();
    final tertiary = (data['themeColorTertiary'] ?? '').toString().trim();

    if (primary.isNotEmpty && secondary.isNotEmpty && tertiary.isNotEmpty) {
      return [primary, secondary, tertiary];
    }

    final legacy = data['gradientColors'];
    if (legacy is List) {
      return legacy.map((c) => c.toString()).toList();
    }
    return null;
  }

  Future<void> _openGradientPicker({
    required BuildContext context,
    required String schoolDocId,
    required String schoolId,
    required String schoolName,
    required List<dynamic>? currentGradient,
    required bool currentApplyToAll,
  }) async {
    bool applyToAll = currentApplyToAll;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Choose Gradient Theme',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        value: applyToAll,
                        onChanged: (value) {
                          setState(() => applyToAll = value);
                        },
                        title: const Text(
                          'Apply to Everything',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          applyToAll
                              ? 'AppBar, cards, buttons & dashboard'
                              : 'Dashboard background only',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        activeThumbColor: const Color(0xFF00A876),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Gradient',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_gradientPalettes.length, (index) {
                        final palette = _gradientPalettes[index];
                        final name = palette['name'] as String;
                        final colors = (palette['colors'] as List<String>)
                            .map(_hexToColor)
                            .toList();
                        final isCurrent =
                            currentGradient != null &&
                            currentGradient.length == colors.length &&
                            currentGradient.asMap().entries.every(
                              (entry) =>
                                  entry.value ==
                                  (palette['colors'] as List)[entry.key],
                            );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => Navigator.of(dialogContext).pop({
                              'colors': palette['colors'],
                              'applyToAll': applyToAll,
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomRight,
                                  end: Alignment.topLeft,
                                  colors: colors,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent
                                      ? Colors.black87
                                      : Colors.grey[300]!,
                                  width: isCurrent ? 3 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final selected = (result['colors'] as List<dynamic>)
        .map((c) => c.toString())
        .toList(growable: false);
    final payload = {
      'themeColorPrimary': selected[0],
      'themeColorSecondary': selected[1],
      'themeColorTertiary': selected[2],
      'gradientColors': FieldValue.delete(),
      'applyToAll': result['applyToAll'],
    };

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolDocId)
        .set(payload, SetOptions(merge: true));

    // Backward compatibility: some datasets may resolve school by schoolId.
    if (schoolId.isNotEmpty && schoolId != schoolDocId) {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .set(payload, SetOptions(merge: true));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gradient theme updated for $schoolName'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsData = ref.watch(schoolsProvider);

    return schoolsData.when(
      data: (snapshot) {
        final allDocs = snapshot.docs;

        // Filter schools based on search query
        final docs = searchQuery.isEmpty
            ? allDocs
            : allDocs.where((doc) {
                final data = doc.data();
                final name = _resolveSchoolName(data, doc.id).toLowerCase();
                final schoolId = (data['schoolId'] ?? doc.id)
                    .toString()
                    .toLowerCase();
                final query = searchQuery.toLowerCase();
                return name.contains(query) || schoolId.contains(query);
              }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  searchQuery.isEmpty
                      ? 'No schools created yet'
                      : 'No schools found matching "$searchQuery"',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final name = _resolveSchoolName(data, docs[index].id);
            final schoolId = (data['schoolId'] ?? docs[index].id).toString();
            final plan = (data['subscriptionPlan'] ?? '').toString();
            final gradientColors = _readCurrentThemeHex(data);
            final applyToAll = (data['applyToAll'] ?? false) as bool;
            final colors = _getGradientColors(gradientColors);

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1A00A876),
                  child: Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF00A876),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'School ID: $schoolId',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1A00A876),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        plan.isEmpty ? 'Standard' : plan,
                        style: const TextStyle(
                          color: Color(0xFF00A876),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Change gradient theme',
                      onPressed: () => _openGradientPicker(
                        context: context,
                        schoolDocId: docs[index].id,
                        schoolId: schoolId,
                        schoolName: name.isEmpty ? schoolId : name,
                        currentGradient: gradientColors,
                        currentApplyToAll: applyToAll,
                      ),
                      icon: const Icon(
                        Icons.palette_rounded,
                        color: Color(0xFF00A876),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Archive/Unarchive button
                    Builder(
                      builder: (context) {
                        final archived = (data['archived'] ?? false) as bool;
                        return archived
                            ? IconButton(
                                tooltip: 'Unarchive school',
                                icon: const Icon(Icons.unarchive_rounded, color: Colors.orange),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('schools')
                                      .doc(docs[index].id)
                                      .update({'archived': false});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('School unarchived')),
                                  );
                                },
                              )
                            : IconButton(
                                tooltip: 'Archive school',
                                icon: const Icon(Icons.archive_rounded, color: Colors.red),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('schools')
                                      .doc(docs[index].id)
                                      .update({'archived': true});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('School archived')),
                                  );
                                },
                              );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A876)),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
