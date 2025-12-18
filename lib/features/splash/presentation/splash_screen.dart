import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../onboarding/presentation/onboarding_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../protocols/presentation/protocol_provider.dart';
import '../../library/presentation/peptide_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('Starting app initialization...');
    
    try {
      // Get providers
      final settingsProvider = context.read<SettingsProvider>();
      final protocolProvider = context.read<ProtocolProvider>();
      final peptideProvider = context.read<PeptideProvider>();
      final onboardingProvider = context.read<OnboardingProvider>();

      debugPrint('Providers obtained, starting initialization...');

      // Initialize each with individual error handling
      try {
        debugPrint('Initializing settings...');
        await settingsProvider.initialize().timeout(const Duration(seconds: 5));
        debugPrint('Settings initialized');
      } catch (e) {
        debugPrint('Settings init failed: $e');
      }

      try {
        debugPrint('Loading protocols...');
        await protocolProvider.loadProtocols().timeout(const Duration(seconds: 5));
        debugPrint('Protocols loaded');
      } catch (e) {
        debugPrint('Protocol load failed: $e');
      }

      try {
        debugPrint('Loading peptides...');
        await peptideProvider.loadPeptides().timeout(const Duration(seconds: 5));
        debugPrint('Peptides loaded');
      } catch (e) {
        debugPrint('Peptide load failed: $e');
      }

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      debugPrint('Navigating... TOS accepted: ${onboardingProvider.tosAccepted}, Onboarding complete: ${onboardingProvider.onboardingCompleted}');

      // Navigate based on onboarding status
      if (!onboardingProvider.tosAccepted) {
        Navigator.pushReplacementNamed(context, AppRoutes.disclaimer);
      } else if (!onboardingProvider.onboardingCompleted) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    } catch (e, stack) {
      debugPrint('Critical initialization error: $e');
      debugPrint('Stack: $stack');
      // Wait a bit then navigate to disclaimer (first-time setup)
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.disclaimer);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryBlue.withOpacity(0.8),
                              AppColors.purple.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.science_outlined,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // App Name
                      Text(
                        'pep.io',
                        style: AppTypography.display.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tagline
                      Text(
                        'Track. Learn. Optimize.',
                        style: AppTypography.subhead.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

