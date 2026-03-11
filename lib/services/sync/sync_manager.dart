// services/sync/sync_manager.dart
import 'excel_export_service.dart';
import 'excel_import_service.dart';
import 'google_sheet_service.dart';

enum SyncFlow { csvToGoogleSheet, googleSheetToCsv }

class SyncResult {
  const SyncResult({
    required this.flow,
    required this.rowsProcessed,
    required this.startedAt,
    required this.finishedAt,
    this.warnings = const <String>[],
  });

  final SyncFlow flow;
  final int rowsProcessed;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<String> warnings;

  Duration get duration => finishedAt.difference(startedAt);
}

class SyncManager {
  SyncManager({
    required GoogleSheetService googleSheetService,
    ExcelImportService excelImportService = const ExcelImportService(),
    ExcelExportService excelExportService = const ExcelExportService(),
  }) : _googleSheetService = googleSheetService,
       _excelImportService = excelImportService,
       _excelExportService = excelExportService;

  final GoogleSheetService _googleSheetService;
  final ExcelImportService _excelImportService;
  final ExcelExportService _excelExportService;

  /// Imports rows from CSV text and pushes them to a Google Sheet.
  Future<SyncResult> syncCsvToGoogleSheet({
    required String csvContent,
    required String spreadsheetId,
    required String worksheet,
    bool clearFirst = false,
  }) async {
    final startedAt = DateTime.now();
    final warnings = <String>[];

    final rows = _excelImportService.parseCsv(csvContent);
    if (rows.isEmpty) {
      warnings.add('No rows found in CSV payload.');
    }

    final normalizedRows = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    await _googleSheetService.upsertRows(
      spreadsheetId: spreadsheetId,
      worksheet: worksheet,
      rows: normalizedRows,
      clearFirst: clearFirst,
    );

    return SyncResult(
      flow: SyncFlow.csvToGoogleSheet,
      rowsProcessed: normalizedRows.length,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      warnings: warnings,
    );
  }

  /// Pulls rows from a Google Sheet and returns CSV text.
  Future<({SyncResult result, String csv})> syncGoogleSheetToCsv({
    required String spreadsheetId,
    required String worksheet,
  }) async {
    final startedAt = DateTime.now();
    final warnings = <String>[];

    final rows = await _googleSheetService.fetchRows(
      spreadsheetId: spreadsheetId,
      worksheet: worksheet,
    );

    if (rows.isEmpty) {
      warnings.add('Sheet is empty. Generated CSV has only headers (if any).');
    }

    final csv = _excelExportService.toCsv(rows);

    final result = SyncResult(
      flow: SyncFlow.googleSheetToCsv,
      rowsProcessed: rows.length,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      warnings: warnings,
    );

    return (result: result, csv: csv);
  }
}
