import 'package:flutter/material.dart';

/// School branding settings stored in Firestore.
///
/// Document path: `schools/{schoolId}/settings/branding`
///
/// Stored fields (recommended):
/// - primaryColor: int (ARGB)
/// - secondaryColor: int (ARGB)
/// - logoPath: string (Cloud Storage object path)
class SchoolBranding {
  const SchoolBranding({
    required this.primaryColorValue,
    required this.secondaryColorValue,
    this.logoPath,
  });

  /// Default SK branding.
  static const int defaultPrimaryColorValue = 0xFF06B6D4;
  static const int defaultSecondaryColorValue = 0xFFEC4899;

  final int primaryColorValue;
  final int secondaryColorValue;
  final String? logoPath;

  Color get primaryColor => Color(primaryColorValue);
  Color get secondaryColor => Color(secondaryColorValue);

  SchoolBranding copyWith({
    int? primaryColorValue,
    int? secondaryColorValue,
    String? logoPath,
  }) {
    return SchoolBranding(
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      secondaryColorValue: secondaryColorValue ?? this.secondaryColorValue,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  static SchoolBranding defaults() {
    return const SchoolBranding(
      primaryColorValue: defaultPrimaryColorValue,
      secondaryColorValue: defaultSecondaryColorValue,
      logoPath: null,
    );
  }

  static SchoolBranding fromMap(Map<String, dynamic>? data) {
    if (data == null) return SchoolBranding.defaults();

    int readColor(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is String) {
        final s = v.trim();
        // Support formats like "0xFF06B6D4" or "#06B6D4".
        try {
          if (s.startsWith('0x')) return int.parse(s);
          if (s.startsWith('#')) {
            final hex = s.substring(1);
            if (hex.length == 6) {
              return int.parse('0xFF$hex');
            }
            if (hex.length == 8) {
              return int.parse('0x$hex');
            }
          }
        } catch (_) {
          return fallback;
        }
      }
      return fallback;
    }

    final p = readColor(data['primaryColor'], defaultPrimaryColorValue);
    final s = readColor(data['secondaryColor'], defaultSecondaryColorValue);
    final logoPath = (data['logoPath'] ?? '').toString().trim();

    return SchoolBranding(
      primaryColorValue: p,
      secondaryColorValue: s,
      logoPath: logoPath.isEmpty ? null : logoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColorValue,
      'secondaryColor': secondaryColorValue,
      if ((logoPath ?? '').trim().isNotEmpty) 'logoPath': logoPath,
    };
  }
}
