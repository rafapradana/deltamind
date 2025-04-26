import 'package:deltamind/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configurations
class AppTheme {
  /// Primary color used for main actions and highlights
  static const Color primaryColor = Colors.black;

  /// Background color for the app
  static const Color backgroundColor = Colors.white;

  /// Success color for positive states
  static const Color successColor = Color(0xFF22C55E);

  /// Error color for negative states
  static const Color errorColor = Color(0xFFEF4444);

  /// Warning color for caution states
  static const Color warningColor = Color(0xFFFACC15);

  /// Info color for informational states
  static const Color infoColor = Color(0xFF3B82F6);

  /// Border color for separators
  static const Color borderColor = Color(0xFFE5E7EB);

  /// Secondary button text and border color
  static const Color secondaryColor = Colors.black;

  /// Border radius for large components
  static const double borderRadiusLarge = 16.0;

  /// Border radius for medium components
  static const double borderRadiusMedium = 12.0;

  /// Border radius for small components
  static const double borderRadiusSmall = 8.0;

  /// Text style for large headers
  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      );

  /// Text style for medium headers
  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      );

  /// Text style for small headers
  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      );

  /// Text style for subtitle
  static TextStyle get subtitle => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      );

  /// Text style for body text
  static TextStyle get bodyText => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primaryColor,
      );

  /// Text style for small text
  static TextStyle get smallText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: primaryColor,
      );

  /// Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      background: AppColors.background,
      surface: AppColors.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onBackground: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(
        color: AppColors.primary,
      ),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.error),
      ),
      floatingLabelStyle: TextStyle(color: AppColors.primary),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textPrimary,
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondary,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(color: AppColors.textPrimary),
      secondaryLabelStyle: TextStyle(color: AppColors.primary),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.divider),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.primary.withOpacity(0.1),
      circularTrackColor: AppColors.primary.withOpacity(0.1),
    ),
  );

  /// Dark theme (to be implemented)
  static final ThemeData darkTheme = ThemeData(
    // Dark theme implementation can be added later
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
  );
} 