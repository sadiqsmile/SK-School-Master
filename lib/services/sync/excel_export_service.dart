// services/sync/excel_export_service.dart
class ExcelExportService {
  const ExcelExportService();

  /// Serializes row maps to CSV.
  String toCsv(
    List<Map<String, dynamic>> rows, {
    List<String>? columns,
    String delimiter = ',',
  }) {
    if (rows.isEmpty && (columns == null || columns.isEmpty)) {
      return '';
    }

    final headers = columns ?? _collectHeaders(rows);
    final buffer = StringBuffer();

    buffer.writeln(headers.join(delimiter));

    for (final row in rows) {
      final values = headers
          .map((key) => _escapeValue(row[key], delimiter))
          .toList(growable: false);
      buffer.writeln(values.join(delimiter));
    }

    return buffer.toString();
  }

  List<String> _collectHeaders(List<Map<String, dynamic>> rows) {
    final ordered = <String>[];
    final seen = <String>{};
    for (final row in rows) {
      for (final key in row.keys) {
        if (seen.add(key)) {
          ordered.add(key);
        }
      }
    }
    return ordered;
  }

  String _escapeValue(dynamic value, String delimiter) {
    final text = (value ?? '').toString();
    final needsQuotes =
        text.contains(delimiter) || text.contains('"') || text.contains('\n');
    if (!needsQuotes) {
      return text;
    }
    final escaped = text.replaceAll('"', '""');
    return '"$escaped"';
  }
}
