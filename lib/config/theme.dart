import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  // paleta corporativa
  static const Color primaryBlue    = Color(0xFF054A91);
  static const Color secondaryOrange = Color(0xFFF17300);
  static const Color lightBlue      = Color(0xFFDBE4EE);
  static const Color mediumBlue     = Color(0xFF3E7CB1);

  // semáforo: verde activo | naranja aviso | rojo inactivo
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color danger  = Color(0xFFC62828);

  // sombra estándar para tarjetas
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  // decoración reutilizable para tarjetas
  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    double radius = 20,
    Color? borderColor,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
        boxShadow: cardShadow,
      );

  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: secondaryOrange,
        surface: Colors.white,
        background: lightBlue,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryBlue,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: primaryBlue),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F6F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 15),
        prefixIconColor: mediumBlue,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Color(0xFFADB5BD),
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryBlue),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryBlue),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryBlue),
        bodyLarge: TextStyle(fontSize: 15, color: Color(0xFF2D3748)),
        bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF718096)),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF718096), letterSpacing: 0.8),
      ),

      scaffoldBackgroundColor: lightBlue,
      dividerTheme: const DividerThemeData(color: Color(0xFFE9ECEF), thickness: 1),
    );
  }
}
