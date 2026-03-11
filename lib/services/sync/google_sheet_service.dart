// services/sync/google_sheet_service.dart
abstract class GoogleSheetService {
  const GoogleSheetService();

  Future<List<Map<String, dynamic>>> fetchRows({
    required String spreadsheetId,
    required String worksheet,
  });

  Future<void> upsertRows({
    required String spreadsheetId,
    required String worksheet,
    required List<Map<String, dynamic>> rows,
    bool clearFirst = false,
  });
}

/// Default implementation used until a real Google Sheets API integration is
/// wired in.
class PlaceholderGoogleSheetService extends GoogleSheetService {
  const PlaceholderGoogleSheetService();

  @override
  Future<List<Map<String, dynamic>>> fetchRows({
    required String spreadsheetId,
    required String worksheet,
  }) {
    throw UnimplementedError(
      'Google Sheets fetch is not configured yet. '
      'Provide a concrete GoogleSheetService implementation.',
    );
  }

  @override
  Future<void> upsertRows({
    required String spreadsheetId,
    required String worksheet,
    required List<Map<String, dynamic>> rows,
    bool clearFirst = false,
  }) {
    throw UnimplementedError(
      'Google Sheets upsert is not configured yet. '
      'Provide a concrete GoogleSheetService implementation.',
    );
  }
}
