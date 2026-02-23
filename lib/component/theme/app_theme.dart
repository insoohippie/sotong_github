import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 라이트 테마 — 흰색 배경
ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: AppColors.primary,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
        ).copyWith(
          surface: Colors.white,
          onSurface: Colors.black,
          onSurfaceVariant: AppColors.subText,
        ),
    iconTheme: const IconThemeData(color: Colors.black),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    ),
    dividerColor: Colors.grey[300],
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
      titleMedium: TextStyle(color: Colors.black),
      titleLarge: TextStyle(color: Colors.black),
    ),
  );
}

/// 다크 테마 — 검정/진한 회색 배경
ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.primary,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          surface: AppColors.darkSurface,
        ).copyWith(
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          onSurfaceVariant: AppColors.darkSubText,
          outline: AppColors.darkBorder,
        ),
    iconTheme: const IconThemeData(color: AppColors.darkText),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    dividerColor: AppColors.darkDivider,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBackground,
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: AppColors.darkText),
      bodyMedium: const TextStyle(color: AppColors.darkText),
      titleMedium: const TextStyle(color: AppColors.darkText),
      titleLarge: const TextStyle(color: AppColors.darkText),
    ),
  );
}
