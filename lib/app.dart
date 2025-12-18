import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'features/onboarding/presentation/onboarding_provider.dart';
import 'features/settings/presentation/settings_provider.dart';

class PepIoApp extends StatelessWidget {
  const PepIoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        return MaterialApp(
          title: 'pep.io',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsProvider.themeMode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}

