import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const emerald = Color(0xFF059669);
  static const teal = Color(0xFF0D9488);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: AppColors.emerald,
        primary: AppColors.emerald,
        secondary: AppColors.teal,
        surface: Colors.white,
        surfaceContainerLowest: const Color(0xFFF9FAFB),
        onSurface: const Color(0xFF1F2937),
        onSurfaceVariant: const Color(0xFF6B7280),
      ),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF1F2937),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.emerald,
        primary: AppColors.emerald,
        secondary: AppColors.teal,
        surface: const Color(0xFF1F2937),
        surfaceContainerLowest: const Color(0xFF111827),
        onSurface: Colors.white,
        onSurfaceVariant: const Color(0xFF9CA3AF),
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        color: const Color(0xFF1F2937),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    Color displayColor = brightness == Brightness.light ? const Color(0xFF1F2937) : Colors.white;
    Color bodyColor = brightness == Brightness.light ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB);

    return GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: displayColor),
      displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: displayColor),
      displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: displayColor),
      headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: displayColor),
      headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: displayColor),
      headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: displayColor),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: displayColor),
      titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: displayColor),
      titleSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: displayColor),
      bodyLarge: GoogleFonts.outfit(color: bodyColor),
      bodyMedium: GoogleFonts.outfit(color: bodyColor),
      bodySmall: GoogleFonts.outfit(color: bodyColor),
      labelLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: displayColor),
      labelMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: displayColor),
      labelSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: displayColor),
    );
  }
}
