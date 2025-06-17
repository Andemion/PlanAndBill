import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const darkNavy = Color(0xFF0C1618);
  static const forestGreen = Color(0xFF3A5B44);
  static const lightBeige = Color(0xFFFBF5D4);
  static const goldenYellow = Color(0xFFDBA726);
  static const peach = Color(0xFFF6BE9A);
}

class AppTheme {
  static final TextTheme _textTheme = TextTheme(
    displayLarge: GoogleFonts.dancingScript(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.darkNavy,
    ),
    displayMedium: GoogleFonts.dancingScript(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.darkNavy,
    ),
    displaySmall: GoogleFonts.dancingScript(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.darkNavy,
    ),
    headlineMedium: GoogleFonts.dancingScript(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.darkNavy,
    ),
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.darkNavy,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.darkNavy,
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.darkNavy,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.forestGreen,
    scaffoldBackgroundColor: AppColors.lightBeige,
    colorScheme: ColorScheme.light(
      primary: AppColors.forestGreen,
      secondary: AppColors.goldenYellow,
      tertiary: AppColors.peach,
      background: AppColors.lightBeige,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: AppColors.darkNavy,
      onBackground: AppColors.darkNavy,
      onSurface: AppColors.darkNavy,
    ),
    textTheme: _textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.forestGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.dancingScript(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.forestGreen,
        side: const BorderSide(color: AppColors.forestGreen),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.forestGreen,          // Couleur du texte
        backgroundColor: AppColors.lightBeige,           // ✅ Fond du bouton
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(                   // ✅ Bords arrondis
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.forestGreen,
    scaffoldBackgroundColor: AppColors.darkNavy,
    colorScheme: ColorScheme.dark(
      primary: AppColors.forestGreen,
      secondary: AppColors.goldenYellow,
      tertiary: AppColors.peach,
      background: AppColors.darkNavy,
      surface: const Color(0xFF1C2B2D),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),
    textTheme: _textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.dancingScript(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightBeige,
        side: const BorderSide(color: AppColors.lightBeige),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lightBeige,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C2B2D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C2B2D),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
