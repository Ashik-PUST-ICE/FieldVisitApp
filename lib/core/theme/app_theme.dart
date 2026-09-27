import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF123047);
  static const Color primaryDarkColor = Color(0xFF0B2233);
  static const Color accentColor = Color(0xFF20B486);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF20B486);
  static const Color warningColor = Color(0xFFF4A340);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF4F7F8),
      fontFamily: 'Roboto',
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF78909C),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0D1B26),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF65E6B2), secondary: Color(0xFF20B486), error: Color(0xFFFF6B6B)),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF102B43), foregroundColor: Colors.white, elevation: 0, centerTitle: false),
      cardTheme: CardTheme(color: const Color(0xFF162B3A), elevation: 1, margin: const EdgeInsets.symmetric(vertical: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF162B3A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF102B43), selectedItemColor: Color(0xFF65E6B2), unselectedItemColor: Color(0xFF90A4AE), type: BottomNavigationBarType.fixed),
    );
  }
}
