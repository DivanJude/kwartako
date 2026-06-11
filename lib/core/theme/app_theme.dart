import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.secondaryBlue,
        tertiary: AppColors.accentCyan,
        surface: AppColors.surface,
        error: AppColors.dangerRed,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1.0,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      extensions: [
        GlassThemeExtension(
          cardDecoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          inputDecoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1.0,
            ),
          ),
          accentCardDecoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue.withOpacity(0.2),
                AppColors.accentCyan.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.3),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GlassThemeExtension extends ThemeExtension<GlassThemeExtension> {
  final BoxDecoration? cardDecoration;
  final BoxDecoration? inputDecoration;
  final BoxDecoration? accentCardDecoration;

  GlassThemeExtension({
    required this.cardDecoration,
    required this.inputDecoration,
    required this.accentCardDecoration,
  });

  @override
  GlassThemeExtension copyWith({
    BoxDecoration? cardDecoration,
    BoxDecoration? inputDecoration,
    BoxDecoration? accentCardDecoration,
  }) {
    return GlassThemeExtension(
      cardDecoration: cardDecoration ?? this.cardDecoration,
      inputDecoration: inputDecoration ?? this.inputDecoration,
      accentCardDecoration: accentCardDecoration ?? this.accentCardDecoration,
    );
  }

  @override
  GlassThemeExtension lerp(ThemeExtension<GlassThemeExtension>? other, double t) {
    if (other is! GlassThemeExtension) {
      return this;
    }
    return GlassThemeExtension(
      cardDecoration: BoxDecoration.lerp(cardDecoration, other.cardDecoration, t),
      inputDecoration: BoxDecoration.lerp(inputDecoration, other.inputDecoration, t),
      accentCardDecoration: BoxDecoration.lerp(accentCardDecoration, other.accentCardDecoration, t),
    );
  }
}
