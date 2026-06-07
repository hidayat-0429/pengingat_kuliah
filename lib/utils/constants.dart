import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color bgPrimary = Color(0xFF0A0A1A);
  static const Color bgSecondary = Color(0xFF12122A);
  static const Color bgTertiary = Color(0xFF1A1A3E);

  // Brand
  static const Color primary = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF6366F1);
  static const Color accent = Color(0xFFC084FC);

  // Semantic
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Glass
  static const Color glassBg = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color border = Color(0xFF2A2A4A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0A1A), Color(0xFF0F0F2D), Color(0xFF0A0A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF14142E), Color(0xFF0F0F23)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}
