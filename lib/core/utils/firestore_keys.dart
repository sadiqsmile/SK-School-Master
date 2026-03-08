/// Utilities for generating Firestore-safe keys.
///
/// Keep this consistent across services and Firestore security rules.
library;

/// Sanitizes a value to be safe in Firestore document/collection IDs.
///
/// This mirrors the logic used by attendance + parent dashboard.
String sanitizeFirestoreId(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';

  final safe = trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
  return safe
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Returns the canonical class key used across the app.
///
/// Example: classId="5", sectionId="A" => "class_5_A"
String classKeyFrom(String classId, String sectionId) {
  final c = sanitizeFirestoreId(classId);
  final s = sanitizeFirestoreId(sectionId);
  return 'class_${c}_$s';
}
