import 'package:flutter/material.dart';

/// Design tokens matching the iconic Cellfin / Islami Bank premium mobile design system.
class AppColors {
  AppColors._();

  // ─── CELLFIN PRIMARY PALETTE ─────────────────────────────────────
  static const Color primary = Color(0xFF136B3E); // Cellfin signature Forest Green
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF0A4425);
  static const Color primarySurface = Color(0xFFE8F5E9);

  // ─── CELLFIN GOLDEN YELLOW ACCENT ───────────────────────────────
  static const Color accent = Color(0xFFFFB300); // Cellfin Golden Yellow
  static const Color accentLight = Color(0xFFFFF8E1);
  static const Color accentDark = Color(0xFFF57F17);

  // ─── SEMANTIC COLORS ─────────────────────────────────────────────
  static const Color success = Color(0xFF136B3E);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ─── NEUTRALS ────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF0F4F2); // Soft mint/grayish backdrop
  static const Color scaffold = Color(0xFFF0F4F2);

  // ─── CELLFIN SPECIFIC COLORS ─────────────────────────────────────
  static const Color cellfinGreen = Color(0xFF136B3E);
  static const Color cellfinDarkGreen = Color(0xFF0C4A29);
  static const Color cellfinYellow = Color(0xFFFFB300);
  static const Color cellfinLightMint = Color(0xFFE8F5E9);
  static const Color cellfinCircleMint = Color(0xFFD6EFE0);

  // ─── DARK MODE ────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1B13);
  static const Color darkSurface = Color(0xFF13281D);
  static const Color darkCard = Color(0xFF1A3326);
  static const Color darkBorder = Color(0xFF264736);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkPrimary = Color(0xFF4ADE80);

  // ─── GRADIENT STOPS ──────────────────────────────────────────────
  static const Color gradientStart = Color(0xFF136B3E);
  static const Color gradientMid = Color(0xFF177A47);
  static const Color gradientEnd = Color(0xFF1B8A51);

  // ─── CATEGORY ACCENT COLORS ──────────────────────────────────────
  static const Color teal = Color(0xFF0D9488);
  static const Color blue = Color(0xFF1E88E5);
  static const Color purple = Color(0xFF7E57C2);
  static const Color pink = Color(0xFFEC407A);
  static const Color orange = Color(0xFFFB8C00);
  static const Color amber = Color(0xFFFFB300);
  static const Color emerald = Color(0xFF2E7D32);
  static const Color indigo = Color(0xFF3949AB);
  static const Color rose = Color(0xFFE53935);
  static const Color cyan = Color(0xFF00ACC1);

  // ─── GRADIENTS ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [Color(0xFF0C4A29), Color(0xFF136B3E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0D1B13), Color(0xFF13281D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF136B3E), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFB8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── SHADOWS ──────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primary.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: primary.withOpacity(0.18),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static Color tintedBackground(Color color) =>
      Color.lerp(Colors.white, color, 0.12)!;
}
