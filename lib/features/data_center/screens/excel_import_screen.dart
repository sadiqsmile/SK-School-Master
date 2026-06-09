// features/data_center/screens/excel_import_screen.dart
import 'dart:typed_data';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExcelImportScreen extends StatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  bool _isLoading = false;
  bool _isImporting = false;
  String _fileName = '';
  List<List<String>> _rows = [];
  String _selectedType = 'Students';

  final List<String> _types = [
    'Students',
    'Teachers',
    'Parents',
    'Fees',
    'Marks',
    'Attendance',
  ];

  Future<void> _pickExcelFile() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.first;
      final Uint8List? bytes = file.bytes;

      if (bytes == null) {
        throw Exception('Unable to read file');
      }

      final excel = ex.Excel.decodeBytes(bytes);
      final firstSheet = excel.tables.keys.first;
      final sheet = excel.tables[firstSheet];

      final rows = <List<String>>[];

      if (sheet != null) {
        for (final row in sheet.rows) {
          rows.add(
            row.map((cell) => cell?.value?.toString() ?? '').toList(),
          );
        }
      }

      setState(() {
        _fileName = file.name;
        _rows = rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _validateHeaders() {
    if (_rows.isEmpty) return false;

    final headers = _rows.first.map((e) => e.trim().toLowerCase()).toList();

    if (_selectedType == 'Students') {
      return headers.contains('name') &&
          headers.contains('class') &&
          headers.contains('roll no');
    }

    if (_selectedType == 'Teachers') {
      return headers.contains('name') && headers.contains('subject');
    }

    return true;
  }

  Future<void> _importData() async {
    if (_rows.isEmpty) return;

    if (!_validateHeaders()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Excel format'),
        ),
      );
      return;
    }

    setState(() => _isImporting = true);

    try {
      final headers = _rows.first;

      for (int i = 1; i < _rows.length; i++) {
        final row = _rows[i];

        final data = <String, dynamic>{};

        for (int j = 0; j < headers.length; j++) {
          final key = headers[j].toLowerCase().trim();
          final value = j < row.length ? row[j] : '';
          data[key] = value;
        }

        await FirebaseFirestore.instance.collection('students').add({
          'name': data['name'] ?? '',
          'class': data['class'] ?? '',
          'rollNo': data['roll no'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Students imported successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }

    setState(() => _isImporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _rows.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Excel Import'),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Import Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _types.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedType = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickExcelFile,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Choose File'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: (!hasData || _isImporting) ? null : _importData,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: const Text('Import'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : !hasData
                        ? Center(
                            child: Text(
                              _fileName.isEmpty
                                  ? 'No Excel file selected'
                                  : 'No data found',
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File: $_fileName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _validateHeaders()
                                    ? 'Header validation passed'
                                    : 'Header validation failed',
                                style: TextStyle(
                                  color: _validateHeaders()
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      columns: _rows.first
                                          .map(
                                            (cell) => DataColumn(
                                              label: Text(
                                                cell,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      rows: _rows.length > 1
                                          ? _rows.skip(1).map((row) {
                                              return DataRow(
                                                cells: row
                                                    .map((cell) =>
                                                        DataCell(Text(cell)))
                                                    .toList(),
                                              );
                                            }).toList()
                                          : [],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
