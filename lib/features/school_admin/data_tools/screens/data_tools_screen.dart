import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_app/features/school_admin/data_tools/services/school_data_tools_service.dart';
import 'package:school_app/features/school_admin/layout/admin_layout.dart';
import 'package:school_app/providers/current_school_provider.dart';

class SchoolAdminDataToolsScreen extends ConsumerStatefulWidget {
  const SchoolAdminDataToolsScreen({super.key});

  @override
  ConsumerState<SchoolAdminDataToolsScreen> createState() =>
      _SchoolAdminDataToolsScreenState();
}

class _SchoolAdminDataToolsScreenState
    extends ConsumerState<SchoolAdminDataToolsScreen> {
  final _service = SchoolDataToolsService();

  bool _busy = false;
  String? _lastMessage;

  Future<void> _saveTextFile({
    required String suggestedName,
    required String content,
    required String mimeType,
  }) async {
    final location = await getSaveLocation(suggestedName: suggestedName);
    if (location == null) return;

    final bytes = Uint8List.fromList(utf8.encode(content));
    final file = XFile.fromData(bytes, mimeType: mimeType, name: suggestedName);
    await file.saveTo(location.path);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: ${location.path}')),
    );
  }

  Future<String?> _pickCsvFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'CSV',
          extensions: ['csv'],
          mimeTypes: ['text/csv', 'application/csv'],
        ),
      ],
    );

    if (file == null) return null;
    return file.readAsString();
  }

  Future<void> _runGuarded(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _lastMessage = null;
    });

    try {
      await fn();
    } catch (e) {
      setState(() => _lastMessage = 'Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportStudents() async {
    await _runGuarded(() async {
      final schoolDoc = await ref.read(currentSchoolProvider.future);
      final schoolId = schoolDoc.id;
      final csv = await _service.buildStudentsCsv(schoolId: schoolId);

      await _saveTextFile(
        suggestedName: 'students_$schoolId.csv',
        content: csv,
        mimeType: 'text/csv',
      );

      setState(() => _lastMessage = 'Exported students (${csv.split('\n').length - 1} rows).');
    });
  }

  Future<void> _exportTeachers() async {
    await _runGuarded(() async {
      final schoolDoc = await ref.read(currentSchoolProvider.future);
      final schoolId = schoolDoc.id;
      final csv = await _service.buildTeachersCsv(schoolId: schoolId);

      await _saveTextFile(
        suggestedName: 'teachers_$schoolId.csv',
        content: csv,
        mimeType: 'text/csv',
      );

      setState(() => _lastMessage = 'Exported teachers (${csv.split('\n').length - 1} rows).');
    });
  }

  Future<void> _exportClasses() async {
    await _runGuarded(() async {
      final schoolDoc = await ref.read(currentSchoolProvider.future);
      final schoolId = schoolDoc.id;
      final csv = await _service.buildClassesCsv(schoolId: schoolId);

      await _saveTextFile(
        suggestedName: 'classes_$schoolId.csv',
        content: csv,
        mimeType: 'text/csv',
      );

      setState(() => _lastMessage = 'Exported classes (${csv.split('\n').length - 1} rows).');
    });
  }

  Future<void> _importStudents() async {
    await _runGuarded(() async {
      final csvText = await _pickCsvFile();
      if (csvText == null) return;

      final previewRows = _service.parseCsvToMaps(csvText);
      if (previewRows.isEmpty) {
        throw StateError('CSV has no data rows.');
      }

      final ok = await _confirmImport(
        title: 'Import Students',
        body:
            'This will create or update students in the current school.\n\nRows detected: ${previewRows.length}',
        confirmLabel: 'Import',
      );
      if (!ok) return;

      final schoolDoc = await ref.read(currentSchoolProvider.future);
      final schoolId = schoolDoc.id;
      final result = await _service.importStudentsCsv(
        schoolId: schoolId,
        csvText: csvText,
      );

      await _showImportResult('Students import complete', result);
    });
  }

  Future<void> _importTeachers() async {
    await _runGuarded(() async {
      final csvText = await _pickCsvFile();
      if (csvText == null) return;

      final previewRows = _service.parseCsvToMaps(csvText);
      if (previewRows.isEmpty) {
        throw StateError('CSV has no data rows.');
      }

      final ok = await _confirmImport(
        title: 'Import Teachers',
        body:
            'This will create teacher logins (Cloud Function) and write teacher profiles for the current school.\n\nRows detected: ${previewRows.length}\n\nTip: import classes first if you plan to include assignments in classesJson.',
        confirmLabel: 'Import',
      );
      if (!ok) return;

      final schoolDoc = await ref.read(currentSchoolProvider.future);
      final schoolId = schoolDoc.id;
      final result = await _service.importTeachersCsv(
        schoolId: schoolId,
        csvText: csvText,
        createLogins: true,
      );

      await _showImportResult('Teachers import complete', result);
    });
  }

  Future<void> _importClasses() async {
    await _runGuarded(() async {
      final csvText = await _pickCsvFile();
      if (csvText == null) return;

      final previewRows = _service.parseCsvToMaps(csvText);
      if (previewRows.isEmpty) {
        throw StateError('CSV has no data rows.');
      }

      final ok = await _confirmImport(
        title: 'Import Classes',
        body:
            'This will create or update classes and their sections for the current school.\n\nRows detected: ${previewRows.length}',
        confirmLabel: 'Import',
      );
      if (!ok) return;

      final schoolDoc = await ref.read(currentSchoolProvider.future);
      final schoolId = schoolDoc.id;
      final result = await _service.importClassesCsv(
        schoolId: schoolId,
        csvText: csvText,
      );

      await _showImportResult('Classes import complete', result);
    });
  }

  Future<bool> _confirmImport({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _showImportResult(String title, ImportSummary summary) async {
    final errors = summary.errors.take(10).toList();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total rows: ${summary.totalRows}'),
                  Text('Created: ${summary.created}'),
                  Text('Updated: ${summary.updated}'),
                  Text('Skipped: ${summary.skipped}'),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'First errors:',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    for (final e in errors) Text('• $e'),
                    if (summary.errors.length > errors.length)
                      Text('…and ${summary.errors.length - errors.length} more'),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    setState(() {
      _lastMessage =
          '$title: ${summary.created} created, ${summary.updated} updated, ${summary.skipped} skipped.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Data Tools (Export / Import)',
      enableTopbar: true,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoBanner(
            busy: _busy,
            message: _lastMessage,
          ),
          const SizedBox(height: 12),
          _ToolCard(
            title: 'Export',
            subtitle:
                'Download CSV files for the current school. You can edit them in Excel/Google Sheets, then import back.',
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _exportStudents,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Students CSV'),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _exportTeachers,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Teachers CSV'),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _exportClasses,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Classes CSV'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ToolCard(
            title: 'Import',
            subtitle:
                'Upload CSV files for the current school. Students are upserted by admissionNo; teachers create logins via Cloud Function.',
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _importClasses,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Classes CSV'),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _importStudents,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Students CSV'),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _importTeachers,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Teachers CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Recommended order: Classes → Students → Teachers (if using class assignments).',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.busy,
    required this.message,
  });

  final bool busy;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (!busy && (message == null || message!.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          if (busy) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Working…')),
          ] else ...[
            const Icon(Icons.info_outline_rounded, color: Color(0xFF334155)),
            const SizedBox(width: 10),
            Expanded(child: Text(message ?? '')),
          ],
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.black.withAlpha(15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, height: 1.3),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
