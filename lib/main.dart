import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'app.dart';
import 'core/services/calendar_service.dart';
import 'core/services/database_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/premium_service.dart';
import 'features/protocols/data/protocol_repository.dart';
import 'features/protocols/presentation/protocol_provider.dart';
import 'features/library/data/peptide_repository.dart';
import 'features/library/presentation/peptide_provider.dart';
import 'features/calculator/presentation/calculator_provider.dart';
import 'features/progress/presentation/progress_provider.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_provider.dart';
import 'features/onboarding/data/onboarding_repository.dart';
import 'features/onboarding/presentation/onboarding_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  
  // Initialize RevenueCat
  await _initializeRevenueCat();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize services
  final databaseService = DatabaseService();
  await databaseService.database;
  
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  final calendarService = CalendarService();
  
  // Initialize premium service
  final premiumService = PremiumService();
  await premiumService.initialize();
  
  // Initialize repositories
  final protocolRepository = ProtocolRepository(databaseService);
  final peptideRepository = PeptideRepository(databaseService);
  final settingsRepository = SettingsRepository(storageService, databaseService);
  final onboardingRepository = OnboardingRepository(storageService, databaseService);
  
  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<DatabaseService>.value(value: databaseService),
        Provider<StorageService>.value(value: storageService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<CalendarService>.value(value: calendarService),
        ChangeNotifierProvider<PremiumService>.value(value: premiumService),
        
        // Repositories
        Provider<ProtocolRepository>.value(value: protocolRepository),
        Provider<PeptideRepository>.value(value: peptideRepository),
        Provider<SettingsRepository>.value(value: settingsRepository),
        Provider<OnboardingRepository>.value(value: onboardingRepository),
        
        // Providers
        ChangeNotifierProvider(
          create: (_) => OnboardingProvider(onboardingRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProtocolProvider(protocolRepository, notificationService, calendarService),
        ),
        ChangeNotifierProvider(
          create: (_) => PeptideProvider(peptideRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CalculatorProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(protocolRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsRepository, calendarService),
        ),
      ],
      child: const PepIoApp(),
    ),
  );
}

/// Initialize RevenueCat SDK
Future<void> _initializeRevenueCat() async {
  await Purchases.setLogLevel(LogLevel.debug);
  
  // Platform-specific API keys
  // Note: Replace with production keys before release
  String apiKey;
  if (Platform.isIOS) {
    apiKey = 'test_fQaWdMxsjZvqqAGATuUIVZrkIEb';
  } else if (Platform.isAndroid) {
    apiKey = 'test_fQaWdMxsjZvqqAGATuUIVZrkIEb'; // Use Android key when available
  } else {
    // Skip RevenueCat on unsupported platforms
    return;
  }
  
  await Purchases.configure(PurchasesConfiguration(apiKey));
}
