import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// App spacing constants
class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// App border radius constants
class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xLarge = 24;
  
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(large));
  static const BorderRadius xLargeRadius = BorderRadius.all(Radius.circular(xLarge));
}

/// App shadow elevations
class AppShadows {
  static List<BoxShadow> get level1 => [
    BoxShadow(
      offset: const Offset(0, 2),
      blurRadius: 4,
      color: Colors.black.withOpacity(0.1),
    ),
  ];
  
  static List<BoxShadow> get level2 => [
    BoxShadow(
      offset: const Offset(0, 4),
      blurRadius: 8,
      color: Colors.black.withOpacity(0.15),
    ),
  ];
  
  static List<BoxShadow> get level3 => [
    BoxShadow(
      offset: const Offset(0, 8),
      blurRadius: 16,
      color: Colors.black.withOpacity(0.2),
    ),
  ];
}

/// Main app theme configuration
class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = createTextTheme(isDark: false);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.purple,
        onSecondary: AppColors.white,
        secondaryContainer: Color(0xFFE1BEE7),
        onSecondaryContainer: AppColors.purple,
        tertiary: AppColors.teal,
        onTertiary: AppColors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.black,
        surfaceContainerHighest: AppColors.lightGray,
        onSurfaceVariant: AppColors.darkGray,
        error: AppColors.error,
        onError: AppColors.white,
        outline: AppColors.lightGray,
        outlineVariant: Color(0xFFE0E0E0),
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headline.copyWith(color: AppColors.black),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mediumRadius,
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smallRadius,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smallRadius,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: AppRadius.smallRadius,
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallRadius,
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallRadius,
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTypography.body.copyWith(color: AppColors.mediumGray),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlue;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: const BorderSide(color: AppColors.mediumGray, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlue;
          }
          return AppColors.lightGray;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightGray,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
        ),
        titleTextStyle: AppTypography.title3.copyWith(color: AppColors.black),
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.darkGray),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    final textTheme = createTextTheme(isDark: true);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.black,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: AppColors.primaryLight,
        secondary: Color(0xFFCE93D8),
        onSecondary: AppColors.black,
        secondaryContainer: AppColors.purple,
        onSecondaryContainer: Color(0xFFE1BEE7),
        tertiary: Color(0xFF4DB6AC),
        onTertiary: AppColors.black,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.white,
        surfaceContainerHighest: Color(0xFF2C2C2C),
        onSurfaceVariant: AppColors.lightGray,
        error: Color(0xFFEF5350),
        onError: AppColors.black,
        outline: Color(0xFF444444),
        outlineVariant: Color(0xFF333333),
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headline.copyWith(color: AppColors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mediumRadius,
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smallRadius,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smallRadius,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smallRadius,
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallRadius,
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallRadius,
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallRadius,
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTypography.body.copyWith(color: AppColors.mediumGray),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.black,
        elevation: 4,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.black),
        side: const BorderSide(color: AppColors.mediumGray, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.black;
          }
          return AppColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return const Color(0xFF444444);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF333333),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
        ),
        titleTextStyle: AppTypography.title3.copyWith(color: AppColors.white),
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.lightGray),
      ),
    );
  }
}

