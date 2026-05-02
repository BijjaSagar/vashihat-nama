import 'package:flutter/material.dart';

class AppTheme {
  // Sentinel Palette: Calm, Premium, Serious
  static const Color backgroundColor = Color(0xFF050505); // Ink Black
  static const Color surfaceColor = Color(0xFF111111);     // Deep Charcoal
  static const Color slabColor = Color(0xFF181818);        // Elevated Slab
  static const Color accentColor = Color(0xFFBFA36D);      // Premium Gold
  static const Color platinumColor = Color(0xFFE5E5E5);    // Soft Platinum
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.black,
      ),
      fontFamily: 'Outfit', // High readability, clean, elegant
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1.5),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: slabColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
    );
  }
  
  static BoxDecoration slabDecoration = BoxDecoration(
    color: slabColor,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 30,
        offset: const Offset(0, 15),
      ),
    ],
  );

  static BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.03),
    borderRadius: BorderRadius.circular(32),
    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
  );

  static BoxDecoration accentGradientDecoration = BoxDecoration(
    gradient: const LinearGradient(
      colors: [accentColor, Color(0xFFB8860B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: accentColor.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static ThemeData get lightTheme => darkTheme;
}
