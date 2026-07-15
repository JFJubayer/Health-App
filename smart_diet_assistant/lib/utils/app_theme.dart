import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const peach = Color(0xFFF79E74);
  static const peachLight = Color(0xFFFCAE82);
  static const charcoal = Color(0xFF3E3F43);
  static const cream = Color(0xFFF5EFEB);
  static const cardCream = Color(0xFFFCFAF8);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: AppColors.peach,
        primary: AppColors.peach,
        secondary: AppColors.charcoal,
        surface: AppColors.cardCream,
        surfaceContainerLowest: AppColors.cream,
        onSurface: AppColors.charcoal,
        onSurfaceVariant: const Color(0xFF7E7E82),
      ),
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.charcoal,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.charcoal),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
        color: AppColors.cardCream,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.peach,
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
        seedColor: AppColors.peach,
        primary: AppColors.peach,
        secondary: AppColors.peachLight,
        surface: const Color(0xFF1E1E1E),
        surfaceContainerLowest: const Color(0xFF121212),
        onSurface: Colors.white,
        onSurfaceVariant: const Color(0xFF9CA3AF),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
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
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        color: const Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.peach,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    Color displayColor = brightness == Brightness.light ? AppColors.charcoal : Colors.white;
    Color bodyColor = brightness == Brightness.light ? const Color(0xFF5E5E62) : const Color(0xFFD1D5DB);

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
