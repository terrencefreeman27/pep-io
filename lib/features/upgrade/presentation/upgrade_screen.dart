import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/premium_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  PlanType _selectedPlan = PlanType.yearly;

  bool _isPurchasing = false;

  final List<_FeatureSlide> _features = [
    _FeatureSlide(
      title: 'Unlimited Protocols & Stacking',
      description: 'Track multiple protocols simultaneously',
      icon: Icons.science_outlined,
    ),
    _FeatureSlide(
      title: 'Medium & Large Widgets',
      description: 'Beautiful home screen widgets',
      icon: Icons.widgets_outlined,
    ),
    _FeatureSlide(
      title: 'AI Insights',
      description: 'AI-powered protocol recommendations',
      icon: Icons.auto_awesome,
    ),
    _FeatureSlide(
      title: 'Priority Support',
      description: 'Get help when you need it',
      icon: Icons.support_agent_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase(BuildContext context) async {
    setState(() => _isPurchasing = true);
    
    try {
      final premiumService = context.read<PremiumService>();
      
      // Get the appropriate package based on selected plan
      final package = _selectedPlan == PlanType.yearly
          ? premiumService.yearlyPackage
          : premiumService.monthlyPackage;
      
      if (package == null) {
        // If no packages available from RevenueCat, show message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription products not yet configured. Please try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Attempt purchase via RevenueCat
      final success = await premiumService.purchasePackage(package);
      
      if (!mounted) return;
      
      if (success) {
        // Show success and close
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Welcome to Premium!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    setState(() => _isPurchasing = true);
    
    try {
      final premiumService = context.read<PremiumService>();
      final restored = await premiumService.restorePurchases();
      
      if (!mounted) return;
      
      if (restored) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase restored successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchase found'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s, right: AppSpacing.s),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.mediumGray,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Feature carousel
                SizedBox(
                  height: isSmallScreen ? 200 : 260,
                  child: _buildFeatureCarousel(isSmallScreen),
                ),

                const SizedBox(height: AppSpacing.m),

                // Page indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _features.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == index
                            ? AppColors.primaryBlue
                            : AppColors.mediumGray.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.l),

                // Plans section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Column(
                    children: [
                      Text(
                        'Select Plan',
                        style: AppTypography.title2.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),

                      // Monthly plan
                      _buildPlanCard(
                        plan: PlanType.monthly,
                        title: 'Monthly',
                        originalPrice: '\$6.99/mo',
                        price: '\$ 4.99/mo',
                        discount: '-20%',
                        isSelected: _selectedPlan == PlanType.monthly,
                        isPopular: false,
                      ),

                      const SizedBox(height: AppSpacing.m),

                      // Yearly plan
                      _buildPlanCard(
                        plan: PlanType.yearly,
                        title: 'Yearly',
                        originalPrice: '\$64.99/yr',
                        price: '\$ 47.99/yr',
                        discount: '-20%',
                        isSelected: _selectedPlan == PlanType.yearly,
                        isPopular: true,
                      ),

                      const SizedBox(height: AppSpacing.m),

                      // Early access notice
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: AppColors.mediumGray,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Early access pricing - limited time only!',
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.l),

                      // Upgrade button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isPurchasing ? null : () => _handlePurchase(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isPurchasing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Upgrade to Premium',
                                  style: AppTypography.headline.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: AppSpacing.s),

                      // No commitment text
                      Text(
                        'No commitment. Cancel anytime.',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Restore Purchase button
                      TextButton(
                        onPressed: _isPurchasing ? null : () => _handleRestore(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Restore Purchase',
                          style: AppTypography.subhead.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Privacy & Terms
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              // TODO: Open privacy policy
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Privacy Policy',
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          Text(
                            '•',
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.mediumGray,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Open terms of use
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Terms of Use',
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.m),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCarousel(bool isSmallScreen) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final feature = _features[index];
        return _buildFeatureSlide(feature, isSmallScreen);
      },
    );
  }

  Widget _buildFeatureSlide(_FeatureSlide feature, bool isSmallScreen) {
    final mockupHeight = isSmallScreen ? 160.0 : 200.0;
    final mockupWidth = isSmallScreen ? 120.0 : 150.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Phone mockup placeholder
          Container(
            width: mockupWidth,
            height: mockupHeight,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.softGray,
                      AppColors.white,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Fake status bar
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: 50,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    // Feature icon
                    Container(
                      width: isSmallScreen ? 50 : 60,
                      height: isSmallScreen ? 50 : 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        feature.icon,
                        size: isSmallScreen ? 26 : 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    // Placeholder content lines
                    _buildPlaceholderCard(AppColors.purple, isSmallScreen),
                    const SizedBox(height: 4),
                    _buildPlaceholderCard(AppColors.teal, isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            feature.title,
            style: AppTypography.headline.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(Color color, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 24 : 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Container(
            width: isSmallScreen ? 14 : 18,
            height: isSmallScreen ? 14 : 18,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required PlanType plan,
    required String title,
    required String originalPrice,
    required String price,
    required String discount,
    required bool isSelected,
    required bool isPopular,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.cardDark,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.headline.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            originalPrice,
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.mediumGray,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Text(
                            price,
                            style: AppTypography.title3.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Discount badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    discount,
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.m),

                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.accent
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.mediumGray,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),

          // Most Popular badge
          if (isPopular)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Most Popular',
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum PlanType { monthly, yearly }

class _FeatureSlide {
  final String title;
  final String description;
  final IconData icon;

  _FeatureSlide({
    required this.title,
    required this.description,
    required this.icon,
  });
}
