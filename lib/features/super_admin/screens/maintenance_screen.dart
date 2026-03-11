// features/super_admin/screens/maintenance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/features/super_admin/services/backfill_service.dart';
import 'package:school_app/providers/super_admin_provider.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
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
        const Color(0xFF8B5CF6),
        const Color(0xFFEC4899),
      ];
    }
    return colorList.map((c) => _hexToColor(c.toString())).toList();
  }

  List<String>? _readCurrentThemeHex(Map<String, dynamic>? data) {
    if (data == null) return null;

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

  Future<void> _openGradientPicker(
    List<dynamic>? currentGradient,
    bool currentApplyToAll,
  ) async {
    bool applyToAll = currentApplyToAll;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Customize Dashboard Theme',
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
                        title: const Text('Apply to Everything'),
                        subtitle: const Text('Enable to theme all UI elements'),
                        value: applyToAll,
                        onChanged: (value) {
                          setState(() {
                            applyToAll = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select a Gradient Palette',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._gradientPalettes.map((palette) {
                        final colors = (palette['colors'] as List<dynamic>)
                            .map((hex) => _hexToColor(hex as String))
                            .toList();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => Navigator.of(dialogContext).pop({
                              'colors': palette['colors'],
                              'applyToAll': applyToAll,
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: colors,
                                  begin: Alignment.bottomRight,
                                  end: Alignment.topLeft,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    palette['name'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
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

    if (result != null && mounted) {
      final colors = (result['colors'] as List<dynamic>)
          .map((c) => c.toString())
          .toList(growable: false);
      final applyToAll = result['applyToAll'] as bool;

      await FirebaseFirestore.instance.doc('platform/config').set({
        'themeColorPrimary': colors[0],
        'themeColorSecondary': colors[1],
        'themeColorTertiary': colors[2],
        'gradientColors': FieldValue.delete(),
        'applyToAll': applyToAll,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dashboard theme updated!')),
        );
      }
    }
  }

  String? _schoolId;

  bool _students = true;
  bool _teachers = true;
  bool _exams = true;
  bool _homework = true;

  bool _running = false;
  BackfillResult? _result;
  final List<String> _logs = [];

  bool _recomputing = false;
  Map<String, dynamic>? _counterResult;

  bool _recomputingAll = false;
  int _recomputeAllDone = 0;
  int _recomputeAllTotal = 0;

  bool _recomputingRisk = false;
  Map<String, dynamic>? _riskResult;

  void _log(String msg) {
    setState(() {
      _logs.insert(0, msg);
    });
  }

  Future<void> _recomputeCounters() async {
    final messenger = ScaffoldMessenger.of(context);
    final schoolId = _schoolId;

    if (schoolId == null || schoolId.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a school.')),
      );
      return;
    }

    setState(() {
      _recomputing = true;
      _counterResult = null;
    });

    try {
      // Callable is deployed in us-central1.
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('recomputeSchoolCounters');
      final resp = await callable.call(<String, dynamic>{'schoolId': schoolId});

      if (!mounted) return;
      final data = (resp.data is Map)
          ? Map<String, dynamic>.from(resp.data as Map)
          : <String, dynamic>{};

      setState(() {
        _counterResult = data;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Counters recomputed.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Recompute failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _recomputing = false;
        });
      }
    }
  }

  Future<void> _recomputeStudentRisk() async {
    final messenger = ScaffoldMessenger.of(context);
    final schoolId = _schoolId;

    if (schoolId == null || schoolId.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a school.')),
      );
      return;
    }

    setState(() {
      _recomputingRisk = true;
      _riskResult = null;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('recomputeStudentRisk');
      final resp = await callable.call(<String, dynamic>{'schoolId': schoolId});

      if (!mounted) return;
      final data = (resp.data is Map)
          ? Map<String, dynamic>.from(resp.data as Map)
          : <String, dynamic>{};

      setState(() {
        _riskResult = data;
      });

      _log(
        'Student risk recompute completed: scanned ${data['studentsScanned'] ?? '-'}',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Student risk recomputed.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Risk recompute failed: $e')),
      );
      _log('Risk recompute failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _recomputingRisk = false;
        });
      }
    }
  }

  Future<void> _recomputeCountersForAllSchools(
    List<({String id, String name})> schools,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (schools.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No schools found.')),
      );
      return;
    }

    setState(() {
      _recomputingAll = true;
      _recomputeAllDone = 0;
      _recomputeAllTotal = schools.length;
    });

    _log('Starting recompute for ${schools.length} schools…');

    try {
      // Callable is deployed in us-central1.
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('recomputeSchoolCounters');

      for (final s in schools) {
        if (!mounted) return;

        try {
          final resp = await callable.call(<String, dynamic>{'schoolId': s.id});
          final data = (resp.data is Map)
              ? Map<String, dynamic>.from(resp.data as Map)
              : <String, dynamic>{};

          setState(() {
            _recomputeAllDone += 1;
          });

          _log(
            '✔ ${s.name} (${s.id}) → '
            'students=${data['totalStudents'] ?? '-'}, '
            'teachers=${data['totalTeachers'] ?? '-'}, '
            'classes=${data['totalClasses'] ?? '-'}',
          );
        } catch (e) {
          setState(() {
            _recomputeAllDone += 1;
          });
          _log('✖ ${s.name} (${s.id}) → failed: $e');
        }
      }

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Recompute (all schools) completed.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _recomputingAll = false;
        });
      }
    }
  }

  Future<void> _run() async {
    final messenger = ScaffoldMessenger.of(context);
    final schoolId = _schoolId;

    if (schoolId == null || schoolId.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a school.')),
      );
      return;
    }

    setState(() {
      _running = true;
      _result = null;
      _logs.clear();
    });

    try {
      final service = BackfillService();
      final result = await service.backfillSchool(
        schoolId: schoolId,
        options: BackfillOptions(
          students: _students,
          teachers: _teachers,
          exams: _exams,
          homework: _homework,
        ),
        onProgress: (p) => _log(p.message),
      );

      if (!mounted) return;

      setState(() {
        _result = result;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Backfill completed.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Backfill failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const panelColor = Color(0xF2FFFFFF);
    final topInset = MediaQuery.of(context).padding.top;
    final platformData = ref.watch(platformProvider).asData?.value.data();
    final themeHex = _readCurrentThemeHex(platformData);
    final themeColors = _getGradientColors(themeHex);
    final primaryColor = themeColors.first;

    final schoolsAsync = ref.watch(schoolsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/super-admin');
            }
          },
        ),
        title: const Text(
          'Maintenance & Data Tools',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColors[0],
              themeColors.length > 1 ? themeColors[1] : themeColors[0],
              themeColors.length > 2 ? themeColors[2] : themeColors[0],
            ],
          ),
        ),
        child: schoolsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load schools: $e')),
          data: (snapshot) {
            final schools =
                snapshot.docs
                    .map((d) {
                      final data = d.data();
                      final name = (data['name'] ?? data['schoolName'] ?? '')
                          .toString();
                      final id = (data['schoolId'] ?? d.id).toString();
                      return (id: id, name: name.isEmpty ? id : name);
                    })
                    .toList(growable: false)
                  ..sort((a, b) => a.name.compareTo(b.name));

            if (schools.isNotEmpty &&
                (_schoolId == null || _schoolId!.trim().isEmpty)) {
              _schoolId = schools.first.id;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16,
              ).copyWith(top: topInset + kToolbarHeight + 16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Dashboard Theme Customization',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Consumer(
                          builder: (context, ref, _) {
                            final platformAsync = ref.watch(platformProvider);
                            return platformAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Text('Error: $e'),
                              data: (doc) {
                                final data = doc.data();
                                final gradientColors = _readCurrentThemeHex(
                                  data,
                                );
                                final applyToAll =
                                    (data?['applyToAll'] ?? false) as bool;
                                final colors = _getGradientColors(
                                  gradientColors,
                                );

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: colors,
                                          begin: Alignment.bottomRight,
                                          end: Alignment.topLeft,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Current Theme Preview',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
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
                                    const SizedBox(height: 12),
                                    FilledButton.icon(
                                      onPressed: () => _openGradientPicker(
                                        gradientColors,
                                        applyToAll,
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.palette_rounded),
                                      label: const Text('Customize Theme'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Fix Missing Data (One-Time Setup)',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This checks and fixes missing details so reports and features work correctly. Use this when setting up or after importing old data.',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'School',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: schools.any((s) => s.id == _schoolId)
                                  ? _schoolId
                                  : null,
                              isExpanded: true,
                              items: [
                                for (final s in schools)
                                  DropdownMenuItem(
                                    value: s.id,
                                    child: Text('${s.name}  •  ${s.id}'),
                                  ),
                              ],
                              onChanged: _running
                                  ? null
                                  : (v) => setState(() {
                                      _schoolId = v;
                                    }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Toggle(
                          title: 'Fix Student Records',
                          subtitle: 'Complete missing student details',
                          value: _students,
                          onChanged: _running
                              ? null
                              : (v) => setState(() => _students = v),
                        ),
                        _Toggle(
                          title: 'Fix Teacher Records',
                          subtitle: 'Complete missing teacher assignments',
                          value: _teachers,
                          onChanged: _running
                              ? null
                              : (v) => setState(() => _teachers = v),
                        ),
                        _Toggle(
                          title: 'Fix Exam Records',
                          subtitle: 'Complete missing exam class details',
                          value: _exams,
                          onChanged: _running
                              ? null
                              : (v) => setState(() => _exams = v),
                        ),
                        _Toggle(
                          title: 'Fix Homework Records',
                          subtitle: 'Complete missing homework class details',
                          value: _homework,
                          onChanged: _running
                              ? null
                              : (v) => setState(() => _homework = v),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _running ? null : _run,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: _running
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.play_circle_fill_rounded),
                          label: Text(
                            _running ? 'Working...' : 'Start Data Fix',
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed:
                              (_running || _recomputing || _recomputingAll)
                              ? null
                              : _recomputeCounters,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.72,
                            ),
                            side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: _recomputing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.calculate_rounded),
                          label: Text(
                            _recomputing ? 'Updating...' : 'Refresh Totals',
                          ),
                        ),

                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed:
                              (_running || _recomputing || _recomputingAll)
                              ? null
                              : () => _recomputeCountersForAllSchools(schools),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.72,
                            ),
                            side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: _recomputingAll
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_fix_high_rounded),
                          label: Text(
                            _recomputingAll
                                ? 'Updating all schools... ($_recomputeAllDone/$_recomputeAllTotal)'
                                : 'Refresh Totals (All Schools)',
                          ),
                        ),

                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed:
                              (_running ||
                                  _recomputing ||
                                  _recomputingAll ||
                                  _recomputingRisk)
                              ? null
                              : _recomputeStudentRisk,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.72,
                            ),
                            side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: _recomputingRisk
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.psychology_alt_rounded),
                          label: Text(
                            _recomputingRisk
                                ? 'Updating risk report...'
                                : 'Update Student Risk Report',
                          ),
                        ),
                        if (_riskResult != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Student risk summary',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Students checked: ${_riskResult!['studentsScanned'] ?? '-'}',
                                ),
                                Text(
                                  'Need attention: ${_riskResult!['studentsHighRisk'] ?? '-'}',
                                ),
                                Text(
                                  'Fee defaulters: ${_riskResult!['feeDefaulters'] ?? '-'}',
                                ),
                                Text(
                                  'Low attendance: ${_riskResult!['lowAttendance'] ?? '-'}',
                                ),
                                Text(
                                  'Top performers: ${_riskResult!['topPerformers'] ?? '-'}',
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_counterResult != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Updated totals',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Students: ${_counterResult!['totalStudents'] ?? '-'}',
                                ),
                                Text(
                                  'Teachers: ${_counterResult!['totalTeachers'] ?? '-'}',
                                ),
                                Text(
                                  'Classes: ${_counterResult!['totalClasses'] ?? '-'}',
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_result != null) ...[
                          const SizedBox(height: 12),
                          _ResultCard(result: _result!),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logs',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_logs.isEmpty)
                          const Text(
                            'No activity yet. Run a task to see updates here.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          )
                        else
                          ..._logs
                              .take(40)
                              .map(
                                (m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    m,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final BackfillResult result;

  @override
  Widget build(BuildContext context) {
    final errors = result.errors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Summary', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Students: updated ${result.studentsUpdated} / scanned ${result.studentsScanned}',
          ),
          Text(
            'Teachers: updated ${result.teachersUpdated} / scanned ${result.teachersScanned}',
          ),
          Text(
            'Exams: updated ${result.examsUpdated} / scanned ${result.examsScanned}',
          ),
          Text(
            'Homework: updated ${result.homeworkUpdated} / scanned ${result.homeworkScanned}',
          ),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Errors', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            for (final e in errors.take(5)) Text('• $e'),
            if (errors.length > 5) Text('…and ${errors.length - 5} more.'),
          ],
        ],
      ),
    );
  }
}
