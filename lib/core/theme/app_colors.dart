import 'package:flutter/material.dart';

/// App color palette based on PRD design specifications
/// Enhanced with gradients and glow effects for modern UI
class AppColors {
  // Primary Colors - Deep blue with vibrant accent
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primarySoft = Color(0xFFDBEAFE);
  
  // Accent Colors - Vibrant purple-pink
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentDark = Color(0xFF6D28D9);
  static const Color accentLight = Color(0xFFA78BFA);
  
  // Secondary Colors
  static const Color purple = Color(0xFF8B5CF6);
  static const Color green = Color(0xFF10B981);
  static const Color orange = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color yellow = Color(0xFFFBBF24);
  static const Color teal = Color(0xFF14B8A6);
  static const Color pink = Color(0xFFEC4899);
  static const Color indigo = Color(0xFF6366F1);
  
  // Neutral Colors
  static const Color black = Color(0xFF0F172A);
  static const Color darkGray = Color(0xFF334155);
  static const Color mediumGray = Color(0xFF94A3B8);
  static const Color lightGray = Color(0xFFE2E8F0);
  static const Color softGray = Color(0xFFF1F5F9);
  static const Color white = Color(0xFFFFFFFF);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF334155);
  
  // Category Colors (for peptide categories)
  static const Color ghSecretagogues = Color(0xFF8B5CF6);      // Purple
  static const Color bodyComposition = Color(0xFFF59E0B);       // Amber
  static const Color regenerative = Color(0xFF10B981);          // Emerald
  static const Color neuroCognitive = Color(0xFF3B82F6);        // Blue
  static const Color energyPerformance = Color(0xFFEF4444);     // Red
  static const Color skinHairBeauty = Color(0xFFEC4899);        // Pink
  static const Color muscleStrength = Color(0xFFDC2626);        // Dark Red
  static const Color longevity = Color(0xFF14B8A6);             // Teal
  static const Color gutMetabolic = Color(0xFF7C3AED);          // Violet
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Glow Colors (for shadows and effects)
  static Color glowBlue = primaryBlue.withOpacity(0.4);
  static Color glowPurple = purple.withOpacity(0.4);
  static Color glowGreen = green.withOpacity(0.4);
  static Color glowOrange = orange.withOpacity(0.4);
  
  // Gradient Colors - Enhanced
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryDark],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA78BFA), purple],
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), green],
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), orange],
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF60A5FA), primaryBlue],
  );
  
  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF87171), red],
  );
  
  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF472B6), pink],
  );
  
  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2DD4BF), teal],
  );
  
  // Dark mode background gradients
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E293B),
    ],
  );
  
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E1B4B),
      Color(0xFF312E81),
    ],
  );
  
  // Card gradients for glassmorphism effect
  static LinearGradient glassGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.6),
      Colors.white.withOpacity(0.3),
    ],
  );
  
  static LinearGradient glassGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.1),
      Colors.white.withOpacity(0.05),
    ],
  );
  
  // Mesh gradient colors for backgrounds
  static const List<Color> meshGradientColors = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
  
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
  
  /// Get gradient by color
  static LinearGradient getGradientForColor(Color color) {
    if (color == primaryBlue) return blueGradient;
    if (color == purple) return purpleGradient;
    if (color == green) return greenGradient;
    if (color == orange) return orangeGradient;
    if (color == red) return redGradient;
    if (color == pink) return pinkGradient;
    if (color == teal) return tealGradient;
    
    // Default: create a gradient from the color
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(color, Colors.white, 0.2)!,
        color,
      ],
    );
  }
  
  /// Get category icon asset path by category name
  static String? getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'growth hormone releasing / gh secretagogues':
      case 'gh secretagogues':
        return 'assets/images/category_gh.png';
      case 'body composition / metabolism':
      case 'body composition':
        return 'assets/images/category_metabolism.png';
      case 'regenerative / soft tissue support':
      case 'regenerative':
        return 'assets/images/category_regenerative.png';
      case 'neuro / cognitive support':
      case 'cognitive':
        return 'assets/images/category_cognitive.png';
      case 'energy / performance / endurance':
      case 'energy':
        return 'assets/images/category_performance.png';
      case 'skin, hair, beauty':
      case 'beauty':
        return 'assets/images/category_beauty.png';
      case 'muscle / strength / recovery':
      case 'muscle':
        return 'assets/images/category_growth.png';
      case 'longevity / systemic peptides':
      case 'longevity':
        return 'assets/images/category_longevity.png';
      case 'gut / metabolic support':
      case 'gut':
        return 'assets/images/category_gut.png';
      default:
        return null;
    }
  }
}
