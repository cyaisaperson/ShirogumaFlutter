import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      brightness: Brightness.light,
      surface: AppColors.card,
      onSurface: AppColors.foreground,
      primary: AppColors.coral,
      onPrimary: Colors.white,
      secondary: AppColors.clay,
      onSecondary: AppColors.foreground,
    ),
    useMaterial3: true,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.foreground,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.foreground,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.foreground),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.coralSoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.coralDark
              : AppColors.mutedText,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.coralDark
              : AppColors.mutedText,
        ),
      ),
    ),
  );
}
