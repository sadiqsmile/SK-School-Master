// services/sync/excel_import_service.dart
class ExcelImportService {
  const ExcelImportService();

  /// Parses CSV content into rows.
  ///
  /// Note: This is a lightweight parser for simple CSV payloads and does not
  /// support quoted multi-line cells.
  List<Map<String, String>> parseCsv(
    String csvContent, {
    String delimiter = ',',
    bool skipEmptyRows = true,
  }) {
    final lines = csvContent
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .toList();

    if (lines.isEmpty || lines.first.isEmpty) {
      return const <Map<String, String>>[];
    }

    final headers = _splitLine(lines.first, delimiter);
    if (headers.isEmpty) {
      return const <Map<String, String>>[];
    }

    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty && skipEmptyRows) {
        continue;
      }

      final cells = _splitLine(line, delimiter);
      final row = <String, String>{};
      for (var c = 0; c < headers.length; c++) {
        final key = headers[c];
        if (key.isEmpty) {
          continue;
        }
        final value = c < cells.length ? cells[c] : '';
        row[key] = value;
      }

      if (row.isNotEmpty || !skipEmptyRows) {
        rows.add(row);
      }
    }

    return rows;
  }

  List<String> _splitLine(String line, String delimiter) {
    return line.split(delimiter).map((e) => e.trim()).toList();
  }
}
