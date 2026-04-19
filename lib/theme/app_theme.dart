import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Apple Light Glass Style
  static const Color primaryColor = Color(0xFF007AFF); // iOS Blue
  static const Color secondaryColor = Color(0xFF5AC8FA); // iOS Light Blue
  static const Color backgroundColor = Color(0xFFF2F2F7); // iOS System Background (Light Gray)
  static const Color surfaceColor = Color(0xFFFFFFFF); // White Surface
  
  // Text Colors
  static const Color textPrimary = Color(0xFF000000); // Black
  static const Color textSecondary = Color(0xFF8E8E93); // iOS Gray

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      // Font Family
      fontFamily: 'Helvetica Neue', // Typical Apple font (or SF Pro if available)
      
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary), // Changed to primary for better readability
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(color: primaryColor),
    );
  }

  // Maintaining this getter for compatibility, but it returns the Light Theme now
  static ThemeData get darkTheme => lightTheme;
}
