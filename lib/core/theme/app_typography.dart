import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App typography based on PRD design specifications
class AppTypography {
  // Using system fonts - on iOS this is SF Pro, on Android this is Roboto
  static const String? fontFamily = null;
  
  // Large Title - 34px bold (iOS style)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  // Display - 34px bold
  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  // Title 1 - 28px bold
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.25,
  );
  
  // Title 2 - 22px bold
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  // Title 3 - 20px semibold
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );
  
  // Headline - 17px semibold
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
  );
  
  // Body - 17px regular
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.5,
  );
  
  // Callout - 16px regular
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Subhead - 15px regular
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Footnote - 13px regular
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Caption 1 - 12px regular
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Caption 2 - 11px regular
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.2,
  );
  
  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
}

/// Text theme for Material
TextTheme createTextTheme({required bool isDark}) {
  final Color textColor = isDark ? AppColors.white : AppColors.black;
  final Color secondaryColor = isDark ? AppColors.lightGray : AppColors.darkGray;
  
  return TextTheme(
    displayLarge: AppTypography.display.copyWith(color: textColor),
    displayMedium: AppTypography.title1.copyWith(color: textColor),
    displaySmall: AppTypography.title2.copyWith(color: textColor),
    headlineLarge: AppTypography.title2.copyWith(color: textColor),
    headlineMedium: AppTypography.title3.copyWith(color: textColor),
    headlineSmall: AppTypography.headline.copyWith(color: textColor),
    titleLarge: AppTypography.title3.copyWith(color: textColor),
    titleMedium: AppTypography.headline.copyWith(color: textColor),
    titleSmall: AppTypography.subhead.copyWith(color: textColor, fontWeight: FontWeight.w600),
    bodyLarge: AppTypography.body.copyWith(color: textColor),
    bodyMedium: AppTypography.callout.copyWith(color: textColor),
    bodySmall: AppTypography.footnote.copyWith(color: secondaryColor),
    labelLarge: AppTypography.labelLarge.copyWith(color: textColor),
    labelMedium: AppTypography.labelMedium.copyWith(color: secondaryColor),
    labelSmall: AppTypography.labelSmall.copyWith(color: secondaryColor),
  );
}

