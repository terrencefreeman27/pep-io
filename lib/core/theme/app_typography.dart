import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App typography using Google Fonts for a distinctive, modern look
/// Using Plus Jakarta Sans for body text and DM Sans for headlines
class AppTypography {
  // Font families
  static String get headlineFont => GoogleFonts.dmSans().fontFamily!;
  static String get bodyFont => GoogleFonts.plusJakartaSans().fontFamily!;
  static String get displayFont => GoogleFonts.spaceGrotesk().fontFamily!;
  
  // Display - 40px bold (hero text)
  static TextStyle get display => GoogleFonts.spaceGrotesk(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    letterSpacing: -1,
    height: 1.1,
  );
  
  // Large Title - 34px bold
  static TextStyle get largeTitle => GoogleFonts.dmSans(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  // Title 1 - 28px bold
  static TextStyle get title1 => GoogleFonts.dmSans(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.25,
  );
  
  // Title 2 - 22px bold
  static TextStyle get title2 => GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  // Title 3 - 20px semibold
  static TextStyle get title3 => GoogleFonts.dmSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );
  
  // Headline - 17px semibold
  static TextStyle get headline => GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
  );
  
  // Body - 17px regular
  static TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.5,
  );
  
  // Callout - 16px regular
  static TextStyle get callout => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Subhead - 15px regular
  static TextStyle get subhead => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Footnote - 13px regular
  static TextStyle get footnote => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Caption 1 - 12px regular
  static TextStyle get caption1 => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Caption 2 - 11px regular
  static TextStyle get caption2 => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Button text
  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.2,
  );
  
  // Label styles
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );
  
  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );
  
  // Monospace for numbers/metrics
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );
  
  // Large metric display
  static TextStyle get metricLarge => GoogleFonts.spaceGrotesk(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    letterSpacing: -1,
    height: 1.1,
  );
  
  // Medium metric display  
  static TextStyle get metricMedium => GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
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
