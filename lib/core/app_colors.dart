import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2D6BFF);
  static const primaryDark = Color(0xFF1B3FA0);
  static const accent = Color(0xFF00D0FF);
  static const success = Color(0xFF2ECC8F);
  static const warning = Color(0xFFFFB020);
  static const danger = Color(0xFFFF5C63);
  static const purple = Color(0xFF8B5CF6);

  static const lightBg = Color(0xFFF3F6FD);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF0E1A38);
  static const lightMuted = Color(0xFF7A88A8);

  static const darkBg = Color(0xFF0E1013);
  static const darkSurface = Color(0xFF17191D);
  static const darkText = Color(0xFFE9EAEC);
  static const darkMuted = Color(0xFF979BA3);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B3FA0), Color(0xFF2D6BFF), Color(0xFF00A8E8)],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D6BFF), Color(0xFF6C4BFF)],
  );

  static const darkField = Color(0xFF1F2227);
  static const darkElevated = Color(0xFF2A2D33);

  static List<Color> difficultyColors = [success, warning, danger];
}
