import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('Starting app initialization...');
    
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final protocolProvider = context.read<ProtocolProvider>();
      final peptideProvider = context.read<PeptideProvider>();
      final onboardingProvider = context.read<OnboardingProvider>();

      debugPrint('Providers obtained, starting initialization...');

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
      await Future.delayed(const Duration(milliseconds: 2500));

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
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.disclaimer);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to gradient if image not found
                return Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.splashGradient,
                  ),
                );
              },
            ),
          ),
          
          // Gradient overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Animated background orbs
          ..._buildBackgroundOrbs(),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                _buildAnimatedLogo(),
                
                const SizedBox(height: 40),
                
                // App Name with staggered reveal
                Text(
                  'pep.io',
                  style: AppTypography.display.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 600.ms, curve: Curves.easeOutCubic),
                
                const SizedBox(height: 12),
                
                // Tagline with letter-by-letter reveal
                _buildAnimatedTagline(),
                
                const SizedBox(height: 60),
                
                // Modern loading indicator
                _buildLoadingIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildBackgroundOrbs() {
    return [
      // Top left orb
      Positioned(
        top: -100,
        left: -100,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + (_pulseController.value * 0.1),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.3),
                      AppColors.primaryBlue.withOpacity(0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      
      // Bottom right orb
      Positioned(
        bottom: -150,
        right: -100,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.1 - (_pulseController.value * 0.1),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withOpacity(0.25),
                      AppColors.purple.withOpacity(0),
            ],
          ),
        ),
              ),
            );
          },
        ),
      ),
      
      // Center floating particles
      ...List.generate(6, (index) => _buildFloatingParticle(index)),
    ];
  }
  
  Widget _buildFloatingParticle(int index) {
    final random = Random(index);
    final size = 4.0 + random.nextDouble() * 4;
    final initialX = random.nextDouble() * MediaQuery.of(context).size.width;
    final initialY = random.nextDouble() * MediaQuery.of(context).size.height;
    
    return Positioned(
      left: initialX,
      top: initialY,
          child: AnimatedBuilder(
        animation: _rotateController,
            builder: (context, child) {
          final offset = sin(_rotateController.value * 2 * pi + index) * 30;
          return Transform.translate(
            offset: Offset(offset, -offset),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3 + random.nextDouble() * 0.3),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAnimatedLogo() {
    return Stack(
      alignment: Alignment.center,
                    children: [
        // Outer glow ring
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 160 + (_pulseController.value * 20),
              height: 160 + (_pulseController.value * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2 - (_pulseController.value * 0.15)),
                  width: 2,
                ),
              ),
            );
          },
        ),
        
        // Middle ring
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 140 + (_pulseController.value * 10),
              height: 140 + (_pulseController.value * 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3 - (_pulseController.value * 0.1)),
                  width: 1,
                ),
              ),
            );
          },
        ),
        
        // Main logo container with custom image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: AppColors.purple.withOpacity(0.3),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if image not found
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryBlue, AppColors.purple],
                    ),
                  ),
                  child: const Icon(Icons.science_outlined, size: 56, color: Colors.white),
                );
              },
            ),
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 800.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 400.ms),
      ],
    );
  }
  
  Widget _buildAnimatedTagline() {
    const tagline = 'Track. Learn. Optimize.';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tagline.split('').asMap().entries.map((entry) {
        return Text(
          entry.value,
          style: AppTypography.subhead.copyWith(
            color: Colors.white.withOpacity(0.8),
                          letterSpacing: 2,
                        ),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 800 + (entry.key * 40)),
              duration: 300.ms,
            )
            .slideY(
              begin: 0.5,
              end: 0,
              delay: Duration(milliseconds: 800 + (entry.key * 40)),
              duration: 300.ms,
              curve: Curves.easeOutCubic,
            );
      }).toList(),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        // Custom loading dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  delay: Duration(milliseconds: index * 200),
                  duration: 600.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.5, 1.5),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                );
          }),
        )
            .animate()
            .fadeIn(delay: 1200.ms, duration: 400.ms),
        
        const SizedBox(height: 16),
        
                      Text(
          'Preparing your experience...',
          style: AppTypography.caption1.copyWith(
            color: Colors.white.withOpacity(0.5),
                        ),
        )
            .animate()
            .fadeIn(delay: 1400.ms, duration: 400.ms),
                    ],
              );
  }
}
