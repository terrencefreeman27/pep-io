import 'package:flutter/material.dart';

/// App color palette based on PRD design specifications
class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color primaryDark = Color(0xFF2E5C8A);
  static const Color primaryLight = Color(0xFF7AB8FF);
  
  // Secondary Colors
  static const Color purple = Color(0xFF9B59B6);
  static const Color green = Color(0xFF27AE60);
  static const Color orange = Color(0xFFE67E22);
  static const Color red = Color(0xFFE74C3C);
  static const Color yellow = Color(0xFFF39C12);
  static const Color teal = Color(0xFF16A085);
  
  // Neutral Colors
  static const Color black = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF4A4A4A);
  static const Color mediumGray = Color(0xFF9B9B9B);
  static const Color lightGray = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Category Colors (for peptide categories)
  static const Color ghSecretagogues = Color(0xFF9B59B6);      // Purple
  static const Color bodyComposition = Color(0xFFE67E22);       // Orange
  static const Color regenerative = Color(0xFF27AE60);          // Green
  static const Color neuroCognitive = Color(0xFF3498DB);        // Blue
  static const Color energyPerformance = Color(0xFFE74C3C);     // Red
  static const Color skinHairBeauty = Color(0xFFF39C12);        // Yellow
  static const Color muscleStrength = Color(0xFFC0392B);        // Dark Red
  static const Color longevity = Color(0xFF16A085);             // Teal
  static const Color gutMetabolic = Color(0xFF8E44AD);          // Dark Purple
  
  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryDark],
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB39DDB), purple],
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF81C784), green],
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB74D), orange],
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF90CAF9), primaryBlue],
  );
  
  /// Get category color by category name
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'growth hormone releasing / gh secretagogues':
      case 'gh secretagogues':
        return ghSecretagogues;
      case 'body composition / metabolism':
      case 'body composition':
        return bodyComposition;
      case 'regenerative / soft tissue support':
      case 'regenerative':
        return regenerative;
      case 'neuro / cognitive support':
      case 'cognitive':
        return neuroCognitive;
      case 'energy / performance / endurance':
      case 'energy':
        return energyPerformance;
      case 'skin, hair, beauty':
      case 'beauty':
        return skinHairBeauty;
      case 'muscle / strength / recovery':
      case 'muscle':
        return muscleStrength;
      case 'longevity / systemic peptides':
      case 'longevity':
        return longevity;
      case 'gut / metabolic support':
      case 'gut':
        return gutMetabolic;
      default:
        return primaryBlue;
    }
  }
}

