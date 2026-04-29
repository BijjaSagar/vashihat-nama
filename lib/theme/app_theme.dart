import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Midnight & Platinum Luxury Style
  static const Color primaryColor = Color(0xFF0A0E21); // Midnight Navy
  static const Color accentColor = Color(0xFFD4AF37); // Classic Gold
  static const Color platinumColor = Color(0xFFE5E5E5); // Platinum Silver
  static const Color backgroundColor = Color(0xFF05070A); // Deepest Black/Blue
  static const Color surfaceColor = Color(0xFF161B22); // Dark Slate Surface
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF0F6FC); // Near White
  static const Color textSecondary = Color(0xFF8B949E); // Muted Gray

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Inter', // Modern, clean typeface
      
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: platinumColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.black,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1.0),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: platinumColor),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          elevation: 8, 
          shadowColor: accentColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      
      iconTheme: const IconThemeData(color: platinumColor, size: 24),
    );
  }

  // Set darkTheme as the default for this high-security app
  static ThemeData get lightTheme => darkTheme;
}
