import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF1877F2);
  static const Color primaryDarkColor = Color(0xFF0D5CC7);
  static const Color accentColor = Color(0xFF1877F2);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF31A24C);
  static const Color warningColor = Color(0xFFF7B928);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      fontFamily: 'Roboto',
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: primaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
        ),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFDADDE1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: accentColor, width: 2)),
        labelStyle: const TextStyle(color: Color(0xFF718096)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        titleTextStyle: const TextStyle(color: primaryColor, fontSize: 21, fontWeight: FontWeight.w800),
        contentTextStyle: const TextStyle(color: Color(0xFF52606D), fontSize: 14, height: 1.4),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
      scaffoldBackgroundColor: const Color(0xFF18191A),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF4599FF), secondary: Color(0xFF4599FF), error: Color(0xFFFF6B6B)),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF242526), foregroundColor: Colors.white, elevation: 0, centerTitle: false),
      cardTheme: CardTheme(color: const Color(0xFF242526), elevation: 0, margin: const EdgeInsets.symmetric(vertical: 3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
      inputDecorationTheme: InputDecorationTheme(isDense: true, filled: true, fillColor: const Color(0xFF242526), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF3E4042))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF3E4042))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF4599FF), width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11)),
      dialogTheme: DialogTheme(backgroundColor: const Color(0xFF242526), surfaceTintColor: const Color(0xFF242526), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12), titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), iconColor: Color(0xFF4599FF), titleTextStyle: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), subtitleTextStyle: TextStyle(color: Color(0xFFB0B3B8), fontSize: 13)),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4599FF), foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF242526), selectedItemColor: Color(0xFF4599FF), unselectedItemColor: Color(0xFFB0B3B8), type: BottomNavigationBarType.fixed),
    );
  }
}
