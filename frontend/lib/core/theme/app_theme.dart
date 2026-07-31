import 'package:flutter/material.dart';

class AppColors {
  // Slate-blue palette based on the supplied mobile reference.
  static const Color primary = Color(0xFF465A73);
  static const Color primaryLight = Color(0xFF6D7F95);
  static const Color primaryDark = Color(0xFF35475E);
  static const Color accent = Color(0xFF8FA2B8);
  static const Color accentDark = Color(0xFF63778F);
  static const Color accentLight = Color(0xFFE7ECF2);
  static const Color scaffoldLight = Color(0xFFF2F4F7);
  static const Color scaffoldDark = Color(0xFFF2F4F7);
  static const Color cardDark = Color(0xFFFFFFFF);
  static const Color online = Color(0xFF5ACB8A);

  static const Color amber = accent;
  static const Color amberBg = accentLight;
  static const Color amberBorder = Color(0xFFD4DEE8);
  static const Color chipBg = accentLight;
  static const Color badgeGreen = Color(0xFF1E9E6A);
  static const Color badgeGreenBg = Color(0xFFE4F5EB);
}

class AppTheme {
  /// The application intentionally uses one soft slate-blue visual system.
  static ThemeData get light => _slateTheme;
  static ThemeData get dark => _slateTheme;

  static final ThemeData _slateTheme = (() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Color(0xFF31445B),
      surface: AppColors.cardDark,
      onSurface: Color(0xFF31445B),
      error: Color(0xFFD45B69),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.scaffoldDark,
      fontFamily: 'Roboto',
      dividerColor: const Color(0xFFDCE3EB),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.28),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : const Color(0xFF93A2B3),
          fontWeight: FontWeight.w600,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : const Color(0xFF93A2B3),
        )),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F3F7),
        hintStyle: const TextStyle(color: Color(0xFF8E9CAD)),
      ),
    );
  })();
}
