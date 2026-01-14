import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../settings/presentation/settings_provider.dart';
import 'onboarding_provider.dart';

class OnboardingSurveyScreen extends StatelessWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: provider.currentStep > 0
                            ? () => provider.previousStep()
                            : null,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (provider.currentStep + 1) / 4,
                          backgroundColor: AppColors.lightGray,
                          valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Text(
                        '${provider.currentStep + 1} of 4',
                        style: AppTypography.caption1,
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStep(context, provider),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(BuildContext context, OnboardingProvider provider) {
    switch (provider.currentStep) {
      case 0:
        return _IntentionsStep(provider: provider);
      case 1:
        return _ProfileStep(provider: provider);
      case 2:
        return _ExperienceStep(provider: provider);
      case 3:
        return _SetupStep(provider: provider);
      default:
        return _IntentionsStep(provider: provider);
    }
  }
}

class _IntentionsStep extends StatelessWidget {
  final OnboardingProvider provider;

  const _IntentionsStep({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome image
          Center(
            child: SizedBox(
              height: 160,
              child: Image.asset(
                'assets/images/onboarding_welcome.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.science_outlined,
                    size: 80,
                    color: AppColors.primaryBlue,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'What would you like to do with pep.io?',
            style: AppTypography.title2,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Select all that apply',
            style: AppTypography.subhead.copyWith(
              color: AppColors.mediumGray,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          
          Expanded(
            child: ListView(
              children: OnboardingIntentions.all.map((intention) {
                final isSelected = provider.selectedIntentions.contains(intention);
                return _SelectionCard(
                  title: intention,
                  isSelected: isSelected,
                  onTap: () => provider.toggleIntention(intention),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.selectedIntentions.isNotEmpty
                  ? () => provider.nextStep()
                  : null,
              child: const Text('Next'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => _skip(context),
              child: const Text('Skip Survey'),
            ),
          ),
        ],
      ),
    );
  }

  void _skip(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Survey?'),
        content: const Text(
          'You can always update your preferences later in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.skipOnboarding();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.main);
              }
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  final OnboardingProvider provider;

  const _ProfileStep({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track image
          Center(
            child: SizedBox(
              height: 120,
              child: Image.asset(
                'assets/images/onboarding_track.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'Tell us about yourself',
            style: AppTypography.title2,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Help us personalize your experience',
            style: AppTypography.subhead.copyWith(
              color: AppColors.mediumGray,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          
          Expanded(
            child: ListView(
              children: [
                // Name field
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Name (Optional)',
                    hintText: 'Enter your name',
                  ),
                  onChanged: provider.setUserName,
                ),
                const SizedBox(height: AppSpacing.m),
                
                // Weight field
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Weight (Optional)',
                          hintText: 'Enter weight',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final weight = double.tryParse(value);
                          provider.setUserWeight(weight);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    _WeightUnitToggle(
                      selectedUnit: provider.weightUnit,
                      onUnitChanged: provider.setWeightUnit,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                
                // Primary goal
                Text(
                  'Primary Goal *',
                  style: AppTypography.subhead.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ...PrimaryGoals.all.map((goal) {
                  final isSelected = provider.primaryGoal == goal;
                  return _SelectionCard(
                    title: goal,
                    isSelected: isSelected,
                    onTap: () => provider.setPrimaryGoal(goal),
                    compact: true,
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.primaryGoal != null
                  ? () => provider.nextStep()
                  : null,
              child: const Text('Next'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => provider.nextStep(),
              child: const Text('Skip'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceStep extends StatelessWidget {
  final OnboardingProvider provider;

  const _ExperienceStep({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Learn image
          Center(
            child: SizedBox(
              height: 140,
              child: Image.asset(
                'assets/images/onboarding_learn.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'What\'s your experience with peptides?',
            style: AppTypography.title2,
          ),
          const SizedBox(height: AppSpacing.l),
          
          _SelectionCard(
            title: 'Yes, I have experience with peptides',
            isSelected: provider.hasExperience,
            onTap: () => provider.setHasExperience(true),
          ),
          _SelectionCard(
            title: 'No, I\'m new to peptides',
            isSelected: !provider.hasExperience,
            onTap: () => provider.setHasExperience(false),
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => provider.nextStep(),
              child: const Text('Next'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => provider.nextStep(),
              child: const Text('Skip'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final OnboardingProvider provider;

  const _SetupStep({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Success header with animated gradient
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          
          Text(
            'Welcome to pep.io',
            style: AppTypography.title1.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your complete peptide companion',
            style: AppTypography.subhead.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.l),
          
          // Feature cards
          _FeatureCard(
            icon: Icons.science_outlined,
            iconColor: AppColors.purple,
            title: 'Comprehensive Library',
            description: 'Explore 60+ peptides across 9 categories with detailed benefits, research insights, and safety information.',
          ),
          const SizedBox(height: AppSpacing.s),
          
          _FeatureCard(
            icon: Icons.calendar_month_outlined,
            iconColor: AppColors.teal,
            title: 'Smart Protocol Tracking',
            description: 'Create personalized protocols with flexible scheduling, dose reminders, and seamless Apple Calendar sync.',
          ),
          const SizedBox(height: AppSpacing.s),
          
          _FeatureCard(
            icon: Icons.calculate_outlined,
            iconColor: AppColors.orange,
            title: 'Precision Calculator',
            description: 'Calculate reconstitution doses with ease—input your vial size, water volume, and desired dose for instant results.',
          ),
          const SizedBox(height: AppSpacing.s),
          
          _FeatureCard(
            icon: Icons.insights_outlined,
            iconColor: AppColors.green,
            title: 'Progress & Insights',
            description: 'Track your adherence, unlock achievements, and receive personalized insights to optimize your journey.',
          ),
          const SizedBox(height: AppSpacing.s),
          
          _FeatureCard(
            icon: Icons.lock_outline,
            iconColor: AppColors.primaryBlue,
            title: '100% Private & Secure',
            description: 'Your data stays on your device—always. No cloud sync, no accounts, complete privacy by design.',
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // CTA Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _createProtocol(context),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Create My First Protocol'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _finish(context),
              icon: const Icon(Icons.explore_outlined, size: 20),
              label: const Text('Explore the App First'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
        ],
      ),
    );
  }

  Future<void> _createProtocol(BuildContext context) async {
    // Save onboarding data
    await _saveData(context);
    
    if (!context.mounted) return;
    
    // Navigate to main with protocol creation
    Navigator.pushReplacementNamed(context, AppRoutes.main);
    // Then navigate to protocol creation
    Navigator.pushNamed(context, AppRoutes.protocolCreate);
  }

  Future<void> _finish(BuildContext context) async {
    await _saveData(context);
    
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.main);
  }

  Future<void> _saveData(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    
    // Save user profile
    if (provider.userName != null || provider.userWeight != null || provider.primaryGoal != null) {
      await settingsProvider.updateUserName(provider.userName);
      if (provider.userWeight != null) {
        await settingsProvider.updateUserWeight(provider.userWeight, provider.weightUnit);
      }
      if (provider.primaryGoal != null) {
        await settingsProvider.updatePrimaryGoal(provider.primaryGoal);
      }
    }
    
    await provider.completeOnboarding();
  }
}

/// Feature card for onboarding summary
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: AppRadius.largeRadius,
        border: Border.all(
          color: iconColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withOpacity(0.15),
                  iconColor.withOpacity(0.05),
                ],
              ),
              borderRadius: AppRadius.mediumRadius,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.mediumGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  const _SelectionCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? AppSpacing.xs : AppSpacing.s),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumRadius,
        child: Container(
          padding: EdgeInsets.all(compact ? AppSpacing.s : AppSpacing.m),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mediumRadius,
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.lightGray,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected 
                ? AppColors.primaryBlue.withOpacity(0.05) 
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.primaryBlue : AppColors.mediumGray,
                size: compact ? 20 : 24,
              ),
              SizedBox(width: compact ? AppSpacing.s : AppSpacing.m),
              Expanded(
                child: Text(
                  title,
                  style: compact ? AppTypography.body : AppTypography.headline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom weight unit toggle that doesn't rotate text
class _WeightUnitToggle extends StatelessWidget {
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;

  const _WeightUnitToggle({
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption('lbs'),
          _buildOption('kg'),
        ],
      ),
    );
  }

  Widget _buildOption(String unit) {
    final isSelected = selectedUnit == unit;
    return GestureDetector(
      onTap: () => onUnitChanged(unit),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : Colors.transparent,
          borderRadius: unit == 'lbs'
              ? const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                )
              : const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
        ),
        child: Text(
          unit,
          style: AppTypography.body.copyWith(
            color: isSelected ? Colors.white : AppColors.mediumGray,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
