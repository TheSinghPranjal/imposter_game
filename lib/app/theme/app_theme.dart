import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brightViolet,
      brightness: Brightness.light,
      primary: AppColors.brightViolet,
      secondary: AppColors.electricBlue,
      tertiary: AppColors.coral,
      surface: AppColors.offWhite,
    );
    return _base(scheme, dark: false);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brightViolet,
      brightness: Brightness.dark,
      primary: AppColors.brightViolet,
      secondary: AppColors.electricBlue,
      tertiary: AppColors.coral,
      surface: AppColors.deepNavy,
    );
    return _base(scheme, dark: true);
  }

  static ThemeData _base(ColorScheme scheme, {required bool dark}) {
    final bg = dark ? AppColors.deepNavy : AppColors.offWhite;
    final card = dark ? AppColors.cardDark : AppColors.cardLight;
    final text = dark ? Colors.white : AppColors.deepPurple;
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Nunito',
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: text,
        titleTextStyle: AppTextStyles.title(text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brightViolet,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          textStyle: AppTextStyles.title(Colors.white).copyWith(fontSize: 18),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: text.withValues(alpha: 0.25)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          textStyle: AppTextStyles.title(text).copyWith(fontSize: 16),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display(text),
        headlineMedium: AppTextStyles.headline(text),
        titleLarge: AppTextStyles.title(text),
        bodyLarge: AppTextStyles.body(text),
        labelLarge: AppTextStyles.label(text),
      ),
    );
  }
}
