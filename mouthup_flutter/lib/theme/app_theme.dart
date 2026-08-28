import 'package:flutter/material.dart';

/// Black & white flat theme — no color accents.
class AppColors {
  static const bg = Color(0xFF000000);
  static const bgCard = Color(0xFF111111);
  static const bgElevated = Color(0xFF1A1A1A);
  static const bgInput = Color(0xFF0A0A0A);

  static const primary = Color(0xFFFFFFFF);
  static const primarySoft = Color(0x1AFFFFFF);
  static const onPrimary = Color(0xFF000000);

  static const text = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFAAAAAA);
  static const textDim = Color(0xFF666666);
  static const border = Color(0xFF2A2A2A);

  static const success = Color(0xFFDDDDDD);
  static const danger = Color(0xFF888888);
  static const like = Color(0xFFFFFFFF);
  static const dislike = Color(0xFF555555);

  static const maleBg = Color(0xFF1A1A1A);
  static const maleFg = Color(0xFFFFFFFF);
  static const femaleBg = Color(0xFF222222);
  static const femaleFg = Color(0xFFCCCCCC);
  static const otherBg = Color(0xFF2A2A2A);
  static const otherFg = Color(0xFF999999);
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.bgCard,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.text,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInput,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        hintStyle: const TextStyle(color: AppColors.textDim),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
        ),
      ),
      useMaterial3: true,
    );
  }
}
