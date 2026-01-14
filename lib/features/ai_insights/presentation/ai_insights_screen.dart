import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/navigation/app_router.dart';

class AIInsightsScreen extends StatelessWidget {
  const AIInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final premiumService = context.watch<PremiumService>();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI Insights'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'PRO',
                    style: AppTypography.caption2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              // AI Icon with glow effect
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 56,
                  color: Colors.white,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
              
              const SizedBox(height: AppSpacing.xl),
              
              Text(
                'AI-Powered Insights',
                style: AppTypography.title2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: AppSpacing.m),
              
              Text(
                'Get personalized recommendations and insights\nbased on your protocol data and progress.',
                style: AppTypography.body.copyWith(
                  color: AppColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Features list
              _buildFeatureItem(
                icon: Icons.trending_up,
                title: 'Protocol Optimization',
                description: 'AI suggests timing and dosage adjustments',
                delay: 400.ms,
              ),
              
              const SizedBox(height: AppSpacing.m),
              
              _buildFeatureItem(
                icon: Icons.insights,
                title: 'Progress Analysis',
                description: 'Understand your adherence patterns',
                delay: 500.ms,
              ),
              
              const SizedBox(height: AppSpacing.m),
              
              _buildFeatureItem(
                icon: Icons.lightbulb_outline,
                title: 'Smart Recommendations',
                description: 'Personalized tips based on your data',
                delay: 600.ms,
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              if (!premiumService.isPremium) ...[
                // Coming Soon / Upgrade prompt
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.accent.withOpacity(0.1)
                        : AppColors.accent.withOpacity(0.05),
                    borderRadius: AppRadius.largeRadius,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Premium Feature',
                            style: AppTypography.headline.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Unlock AI Insights with Premium',
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(
                            context, 
                            AppRoutes.upgrade,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.m,
                            ),
                          ),
                          child: const Text('Upgrade to Premium'),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms)
                    .slideY(begin: 0.2, end: 0),
              ] else ...[
                // Coming soon for premium users
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.primaryBlue.withOpacity(0.1)
                        : AppColors.primaryBlue.withOpacity(0.05),
                    borderRadius: AppRadius.largeRadius,
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'Coming Soon',
                        style: AppTypography.headline.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Duration delay,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: AppRadius.mediumRadius,
          ),
          child: Icon(
            icon,
            color: AppColors.accent,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.subhead.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: delay)
        .slideX(begin: 0.1, end: 0);
  }
}
