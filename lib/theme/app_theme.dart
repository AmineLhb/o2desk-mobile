import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color (--bs-primary)
  static const Color primary = Color(0xFF009FE3);
  static const Color primaryDark = Color(0xFF0082BD);
  static const Color secondary = Color(0xFF808390);
  static const Color success = Color(0xFF28C76F);
  static const Color warning = Color(0xFFFF9F43);
  static const Color danger = Color(0xFFFF4C51);
  static const Color info = Color(0xFF00BAD1);

  // Backward compatible color aliases
  static const Color bgLight = Color(0xFFF8F7FA);
  static const Color lightBg = Color(0xFFF8F7FA);
  static const Color surfaceLight = Colors.white;
  static const Color lightSurface = Colors.white;
  static const Color cardBorder = Color(0xFFDBDADE);
  static const Color lightBorder = Color(0xFFDBDADE);
  static const Color textDark = Color(0xFF2F2B3D);
  static const Color lightTextDark = Color(0xFF2F2B3D);
  static const Color textMuted = Color(0xFF808390);
  static const Color lightTextMuted = Color(0xFF808390);

  // Dark Mode Colors (Vuexy Web)
  static const Color darkBg = Color(0xFF25293C);
  static const Color darkSurface = Color(0xFF2F3349);
  static const Color darkBorder = Color(0xFF434968);
  static const Color darkTextLight = Color(0xFFE0E0E0);
  static const Color darkTextMuted = Color(0xFFA19EBF);

  // Web Exact Status Colors (Matching Web Screenshot 1:1)
  // En cours -> Solid Cyan (#00BAD1)
  // Ouvert / Nouveau -> Solid Grey (#6E7881)
  // En attente -> Solid Orange (#FF9F43)
  // Résolu -> Solid Green (#28C76F)
  // Fermé / Clôturé -> Solid Slate Grey (#6E7881)
  static String normalizeStatus(String? status) {
    if (status == null) return '';
    return status
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ã´', 'o')
        .trim();
  }

  static Color getStatusColor(String? status) {
    final s = normalizeStatus(status);
    if (s.contains('cours') || s.contains('process') || s.contains('traitement')) {
      return const Color(0xFF00BAD1); // Cyan
    }
    if (s.contains('ouvert') || s.contains('open') || s.contains('nouveau') || s.contains('new')) {
      return const Color(0xFF6E7881); // Grey
    }
    if (s.contains('attente') || s.contains('pending') || s.contains('hold')) {
      return const Color(0xFFFF9F43); // Orange
    }
    if (s.contains('resolu') || s.contains('resolved') || s.contains('traite')) {
      return const Color(0xFF28C76F); // Green
    }
    if (s.contains('ferme') || s.contains('closed') || s.contains('cloture') || s.contains('annule')) {
      return const Color(0xFF6E7881); // Slate Grey
    }
    return const Color(0xFF00BAD1);
  }

  static Color getStatusBg(String? status, [bool isDark = false]) {
    return getStatusColor(status);
  }

  static Color getStatusText(String? status, [bool isDark = false]) {
    return Colors.white;
  }

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.publicSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightSurface,
        error: danger,
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: lightTextDark),
        titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: lightTextDark),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: lightTextDark),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: lightTextMuted),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: lightBorder, width: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: lightTextDark),
        titleTextStyle: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w600, color: lightTextDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.publicSansTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: darkSurface,
        error: danger,
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: darkTextLight),
        titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: darkTextLight),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: darkTextLight),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: darkTextMuted),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkBorder, width: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: darkTextLight),
        titleTextStyle: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.publicSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}