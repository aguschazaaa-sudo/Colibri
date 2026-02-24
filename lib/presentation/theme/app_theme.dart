import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define custom colors based on our design system
  static const Color primary = Color(0xFF00695C); // Deep Teal
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF6FF9E8);
  static const Color onPrimaryContainer = Color(0xFF00201B);

  static const Color secondary = Color(0xFFFF6D00); // Energic Orange
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFDCC2);
  static const Color onSecondaryContainer = Color(0xFF331400);

  static const Color tertiary = Color(0xFF10B981); // Money/Emerald Green
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFD1FAE5);
  static const Color onTertiaryContainer = Color(0xFF065F46);

  static const Color error = Color(0xFFBA1A1A); // Coral Red
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color background = Color(0xFFF8FAFC); // Slate lightest
  static const Color onBackground = Color(0xFF0F172A);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF475569);

  static const Color outline = Color(0xFFCBD5E1);

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
  );

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.sourceSans3TextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: background,

      // Typography
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          textStyle: baseTextTheme.displayLarge,
          color: onSurface,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          textStyle: baseTextTheme.displayMedium,
          color: onSurface,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          textStyle: baseTextTheme.displaySmall,
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          textStyle: baseTextTheme.headlineLarge,
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          textStyle: baseTextTheme.headlineMedium,
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          textStyle: baseTextTheme.headlineSmall,
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          textStyle: baseTextTheme.titleLarge,
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.sourceSans3(
          textStyle: baseTextTheme.titleMedium,
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.sourceSans3(
          textStyle: baseTextTheme.titleSmall,
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.sourceSans3(
          textStyle: baseTextTheme.bodyLarge,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.sourceSans3(
          textStyle: baseTextTheme.bodyMedium,
          color: onSurface,
        ),
        bodySmall: GoogleFonts.sourceSans3(
          textStyle: baseTextTheme.bodySmall,
          color: onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.sourceSans3(
          // Useful for buttons
          textStyle: baseTextTheme.labelLarge,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Component Themes
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceContainer),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        elevation: 4,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: onSurfaceVariant),
      ),
    );
  }
}
