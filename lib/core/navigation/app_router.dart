import 'package:flutter/material.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/disclaimer_screen.dart';
import '../../features/onboarding/presentation/privacy_screen.dart';
import '../../features/onboarding/presentation/onboarding_survey_screen.dart';
import '../../features/home/presentation/main_navigation_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/protocols/presentation/protocols_screen.dart';
import '../../features/protocols/presentation/protocol_detail_screen.dart';
import '../../features/protocols/presentation/protocol_form_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/library/presentation/peptide_detail_screen.dart';
import '../../features/calculator/presentation/calculator_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/upgrade/presentation/upgrade_screen.dart';
import '../../features/ai_insights/presentation/ai_insights_screen.dart';

/// App route names
class AppRoutes {
  static const String splash = '/';
  static const String disclaimer = '/disclaimer';
  static const String privacy = '/privacy';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String home = '/home';
  static const String protocols = '/protocols';
  static const String protocolDetail = '/protocols/detail';
  static const String protocolCreate = '/protocols/create';
  static const String protocolEdit = '/protocols/edit';
  static const String library = '/library';
  static const String peptideDetail = '/library/detail';
  static const String calculator = '/calculator';
  static const String calendar = '/calendar';
  static const String progress = '/progress';
  static const String settings = '/settings';
  static const String goals = '/settings/goals';
  static const String notifications = '/settings/notifications';
  static const String calendarSettings = '/settings/calendar';
  static const String upgrade = '/upgrade';
  static const String aiInsights = '/ai-insights';
}

/// App router for generating routes
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
        
      case AppRoutes.disclaimer:
        return MaterialPageRoute(
          builder: (_) => const DisclaimerScreen(),
        );
        
      case AppRoutes.privacy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyScreen(),
        );
        
      case AppRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingSurveyScreen(),
        );
        
      case AppRoutes.main:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );
        
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
        
      case AppRoutes.protocols:
        return MaterialPageRoute(
          builder: (_) => const ProtocolsScreen(),
        );
        
      case AppRoutes.protocolDetail:
        final protocolId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProtocolDetailScreen(protocolId: protocolId),
        );
        
      case AppRoutes.protocolCreate:
        // peptideId can be passed as argument for pre-filling protocol form
        return MaterialPageRoute(
          builder: (_) => ProtocolFormScreen(protocolId: null),
          fullscreenDialog: true,
        );
        
      case AppRoutes.protocolEdit:
        final protocolId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProtocolFormScreen(protocolId: protocolId),
          fullscreenDialog: true,
        );
        
      case AppRoutes.library:
        return MaterialPageRoute(
          builder: (_) => const LibraryScreen(),
        );
        
      case AppRoutes.peptideDetail:
        final peptideId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PeptideDetailScreen(peptideId: peptideId),
        );
        
      case AppRoutes.calculator:
        final peptideId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => CalculatorScreen(peptideId: peptideId),
        );
        
      case AppRoutes.calendar:
        return MaterialPageRoute(
          builder: (_) => const CalendarScreen(),
        );
        
      case AppRoutes.progress:
        return MaterialPageRoute(
          builder: (_) => const ProgressScreen(),
        );
        
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
        
      case AppRoutes.goals:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Goals')),
            body: const Center(child: Text('Goals Screen - Coming Soon')),
          ),
        );
        
      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Notification Settings')),
            body: const Center(child: Text('Notification Settings - Coming Soon')),
          ),
        );
        
      case AppRoutes.upgrade:
        return MaterialPageRoute(
          builder: (_) => const UpgradeScreen(),
          fullscreenDialog: true,
        );
        
      case AppRoutes.aiInsights:
        return MaterialPageRoute(
          builder: (_) => const AIInsightsScreen(),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}

