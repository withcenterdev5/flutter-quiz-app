import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global theme configuration for the quiz app.
///
/// Uses Material Design 3 with a seed-based [ColorScheme] and
/// [GoogleFonts.poppins] as the base text theme.
abstract final class AppTheme {
  AppTheme._();

  /// The seed color that drives the entire MD3 colour system.
  static const Color _seedColor = Color(0xFF6750A4);

  /// Light theme — the only theme in scope for this project.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Apply Poppins across the entire text theme while keeping
      // Material 3 sizing and weight defaults intact.
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(colorScheme: colorScheme).textTheme,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
    );
  }
}