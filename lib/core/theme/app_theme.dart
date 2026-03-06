// core/theme/app_theme.dart
import 'package:flutter/material.dart';

/// Enhanced themes with multiple color schemes for different roles
class AppTheme {
  AppTheme._();

  /// Primary theme for Super Admin (Deep Blue)
  static ThemeData superAdminTheme() {
    return _buildTheme(
      primaryColor: const Color(0xFF1565C0),
      accentColor: const Color(0xFF42A5F5),
      backgroundColor: const Color(0xFFF0F4FF),
    );
  }

  /// Secondary theme for School Admin (Purple)
  static ThemeData schoolAdminTheme() {
    return _buildTheme(
      primaryColor: const Color(0xFF7C3AED),
      accentColor: const Color(0xFFA78BFA),
      backgroundColor: const Color(0xFFFAF5FF),
    );
  }

  /// Tertiary theme for Teachers (Teal)
  static ThemeData teacherTheme() {
    return _buildTheme(
      primaryColor: const Color(0xFF0D9488),
      accentColor: const Color(0xFF14B8A6),
      backgroundColor: const Color(0xFFF0FDFA),
    );
  }

  /// Quaternary theme for Students (Orange)
  static ThemeData studentTheme() {
    return _buildTheme(
      primaryColor: const Color(0xFFEA580C),
      accentColor: const Color(0xFFFB923C),
      backgroundColor: const Color(0xFFFFF7ED),
    );
  }

  /// Light theme (default)
  static ThemeData lightTheme() {
    return superAdminTheme();
  }

  /// Build theme helper
  static ThemeData _buildTheme({
    required Color primaryColor,
    required Color accentColor,
    required Color backgroundColor,
  }) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        prefixIconColor: primaryColor,
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.grey[700]),
      ),
    );
  }
}
