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
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
        ),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD9E2EC))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 2)),
        labelStyle: const TextStyle(color: Color(0xFF718096)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: const TextStyle(color: primaryColor, fontSize: 21, fontWeight: FontWeight.w800),
        contentTextStyle: const TextStyle(color: Color(0xFF52606D), fontSize: 14, height: 1.4),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        iconColor: primaryColor,
        titleTextStyle: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w700),
        subtitleTextStyle: TextStyle(color: Color(0xFF718096), fontSize: 13, height: 1.35),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
      dialogTheme: DialogTheme(backgroundColor: const Color(0xFF162B3A), surfaceTintColor: const Color(0xFF162B3A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18), titleTextStyle: const TextStyle(color: Color(0xFF65E6B2), fontSize: 21, fontWeight: FontWeight.w800)),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), iconColor: Color(0xFF65E6B2), titleTextStyle: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), subtitleTextStyle: TextStyle(color: Color(0xFFB0BEC5), fontSize: 13)),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF20B486), foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF102B43), selectedItemColor: Color(0xFF65E6B2), unselectedItemColor: Color(0xFF90A4AE), type: BottomNavigationBarType.fixed),
    );
  }
}
