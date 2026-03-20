import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF054A91);
  static const Color secondaryOrange = Color(0xFFF17300); 
  static const Color lightBlue = Color(0xFFDBE4EE);
  static const Color mediumBlue = Color(0xFF3E7CB1);

  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        secondary: secondaryOrange,
        background: lightBlue, 
      ),
      
      // Configuración de la AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),

      // Configuración de los botones naranjas
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryOrange,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}