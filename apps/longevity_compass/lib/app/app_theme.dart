import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const Color canvas = Color(0xFFF6F0E7);
  static const Color ink = Color(0xFF12292D);
  static const Color forest = Color(0xFF1D5C63);
  static const Color moss = Color(0xFF5E8F81);
  static const Color mint = Color(0xFFB9D7CB);
  static const Color sand = Color(0xFFF3E6D3);
  static const Color amber = Color(0xFFC98A3D);
  static const Color coral = Color(0xFFCA6642);
  static const Color wine = Color(0xFF8E3D36);
}

class AppTheme {
  static ThemeData build() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.forest,
      primary: AppPalette.forest,
      secondary: AppPalette.amber,
      surface: Colors.white,
      error: AppPalette.wine,
      brightness: Brightness.light,
    );

    final baseTextTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
    ).textTheme;

    final displayTheme = GoogleFonts.spaceGroteskTextTheme(baseTextTheme);
    final bodyTheme = GoogleFonts.manropeTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppPalette.canvas,
      textTheme: bodyTheme.copyWith(
        displayLarge: displayTheme.displayLarge,
        displayMedium: displayTheme.displayMedium,
        displaySmall: displayTheme.displaySmall,
        headlineLarge: displayTheme.headlineLarge,
        headlineMedium: displayTheme.headlineMedium,
        headlineSmall: displayTheme.headlineSmall,
        titleLarge: displayTheme.titleLarge,
        titleMedium: displayTheme.titleMedium,
        titleSmall: displayTheme.titleSmall,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.86),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: AppPalette.ink.withValues(alpha: 0.06),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.sand,
        selectedColor: AppPalette.mint,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: AppPalette.ink,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        indicatorColor: AppPalette.mint,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.manrope(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: AppPalette.ink,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: AppPalette.forest,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
    );
  }
}
