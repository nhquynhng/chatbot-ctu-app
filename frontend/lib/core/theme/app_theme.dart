import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A5FC4);
  static const Color primaryDark = Color(0xFF0B4DA2);
  static const Color scaffoldLight = Color(0xFFF5F7FA);
  static const Color scaffoldDark = Color(0xFF121417);
  static const Color cardDark = Color(0xFF1E2228);
  static const Color online = Color(0xFF34C759);

  static const Color amber = Color(0xFFF5A623);
  static const Color amberBg = Color(0xFFFFF6E5);
  static const Color amberBorder = Color(0xFFFCE0AC);
  static const Color chipBg = Color(0xFFE8F0FB);
  static const Color badgeGreen = Color(0xFF1E9E6A);
  static const Color badgeGreenBg = Color(0xFFE3F5EC);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient homeHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E63C9), Color(0xFF0B4DA2)],
  );
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(primary: AppColors.primary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.scaffoldLight,
      fontFamily: 'Roboto',
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(primary: AppColors.primary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.scaffoldDark,
      fontFamily: 'Roboto',
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
