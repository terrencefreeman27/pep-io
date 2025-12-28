import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_widgets.dart';
import 'onboarding_provider.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _hasCheckedBox = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() => _hasScrolledToBottom = true);
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.surfaceDark]
                : [AppColors.backgroundLight, AppColors.white],
          ),
        ),
        child: SafeArea(
        child: Column(
          children: [
              // Header with animated logo
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                    // Animated Logo with custom image
                  Container(
                      width: 80,
                      height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                        boxShadow: AppShadows.glow(AppColors.primaryBlue, intensity: 0.4),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Icon(Icons.science_outlined, size: 40, color: Colors.white),
                          );
                        },
                      ),
                    ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .fadeIn(),
                    
                  const SizedBox(height: AppSpacing.m),
                    
                  Text(
                    'Important Information',
                    style: AppTypography.title1,
                    textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: AppSpacing.xs),
                    
                    Text(
                      'Please read carefully before continuing',
                      style: AppTypography.subhead.copyWith(
                        color: AppColors.mediumGray,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 300.ms),
                ],
              ),
            ),
            
            // Scrollable content
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.white,
                    borderRadius: AppRadius.largeRadius,
                  border: Border.all(
                      color: isDark ? AppColors.cardDark : AppColors.lightGray,
                  ),
                    boxShadow: isDark ? null : AppShadows.level2,
                ),
                child: ClipRRect(
                    borderRadius: AppRadius.largeRadius,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                            context,
                          'TERMS OF SERVICE & DISCLAIMER',
                          'Welcome to pep.io. Before accessing this application, you must read and acknowledge the following:',
                            Icons.gavel_outlined,
                            AppColors.primaryBlue,
                            0,
                        ),
                        _buildSection(
                            context,
                          'EDUCATIONAL PURPOSE ONLY',
                          '''This application is designed for educational, informational, and personal tracking purposes only. It does NOT:
                          
• Provide medical advice
• Diagnose any condition
• Treat any disease or illness
• Replace consultation with licensed healthcare professionals''',
                            Icons.school_outlined,
                            AppColors.purple,
                            1,
                        ),
                        _buildSection(
                            context,
                          'NO MEDICAL CLAIMS',
                          '''• pep.io does not make any therapeutic claims about peptides
• Information provided is from publicly available, non-clinical sources
• Benefits listed are "commonly researched" or "community-discussed" only
• We do not endorse or recommend any specific peptide or protocol''',
                            Icons.medical_information_outlined,
                            AppColors.teal,
                            2,
                        ),
                        _buildSection(
                            context,
                          'USER RESPONSIBILITY',
                          '''• Consult a licensed healthcare professional before making any decisions related to peptides
• Do not use this app to self-diagnose or self-treat
• Results may vary; no outcomes are guaranteed
• You are solely responsible for your use of the information provided''',
                            Icons.person_outline,
                            AppColors.orange,
                            3,
                        ),
                        _buildSection(
                            context,
                          'DATA & PRIVACY',
                          '''• All data is stored locally on your device only
• No cloud storage or data transmission occurs
• You are responsible for backing up your own data
• pep.io cannot recover lost data''',
                            Icons.lock_outline,
                            AppColors.green,
                            4,
                        ),
                        _buildSection(
                            context,
                          'COMPLIANCE',
                          '''• This app complies with Apple App Store guidelines
• No prescription services are offered
• No product sales or referrals are made
• We are not affiliated with any peptide manufacturers''',
                            Icons.verified_outlined,
                            AppColors.indigo,
                            5,
                        ),
                        const SizedBox(height: AppSpacing.m),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: AppRadius.mediumRadius,
                              border: Border.all(
                                color: AppColors.primaryBlue.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Expanded(
                                  child: Text(
                          'By tapping "I Understand and Agree" below, you acknowledge that you have read, understood, and agree to these terms.',
                                    style: AppTypography.footnote.copyWith(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w500,
                          ),
                        ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 600.ms),
                        const SizedBox(height: AppSpacing.l),
                      ],
                    ),
                  ),
                ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),
            ),
            
            // Bottom actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                    // Checkbox with animation
                  AnimatedOpacity(
                      opacity: _hasScrolledToBottom ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 300),
                      child: BouncyTap(
                      onTap: _hasScrolledToBottom
                          ? () => setState(() => _hasCheckedBox = !_hasCheckedBox)
                          : null,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.s),
                          decoration: BoxDecoration(
                            color: _hasCheckedBox
                                ? AppColors.primaryBlue.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: AppRadius.mediumRadius,
                            border: Border.all(
                              color: _hasCheckedBox
                                  ? AppColors.primaryBlue
                                  : AppColors.lightGray,
                            ),
                          ),
                        child: Row(
                          children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _hasCheckedBox
                                      ? AppColors.primaryBlue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _hasCheckedBox
                                        ? AppColors.primaryBlue
                                        : AppColors.mediumGray,
                                    width: 2,
                                  ),
                                ),
                                child: _hasCheckedBox
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                  : null,
                            ),
                              const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: Text(
                                'I have read and understand the terms above',
                                style: AppTypography.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                    
                  const SizedBox(height: AppSpacing.m),
                  
                    // Continue button
                  SizedBox(
                    width: double.infinity,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.mediumRadius,
                          boxShadow: _hasCheckedBox
                              ? AppShadows.glow(AppColors.primaryBlue, intensity: 0.3)
                              : null,
                        ),
                    child: ElevatedButton(
                      onPressed: _hasCheckedBox ? _onAgree : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('I Understand and Agree'),
                              if (_hasCheckedBox) ...[
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ],
                          ),
                        ),
                    ),
                  ),
                    
                  const SizedBox(height: AppSpacing.s),
                    
                  TextButton(
                    onPressed: _onDecline,
                    child: Text(
                      'Decline',
                        style: AppTypography.subhead.copyWith(
                          color: AppColors.error,
                        ),
                    ),
                  ),
                ],
              ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms),
            ],
            ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppRadius.smallRadius,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
            title,
            style: AppTypography.headline.copyWith(
                    color: color,
                  ),
                ),
            ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
            content,
              style: AppTypography.body.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.lightGray
                    : AppColors.darkGray,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + index * 80))
        .slideX(begin: -0.05, end: 0);
  }

  Future<void> _onAgree() async {
    HapticFeedback.mediumImpact();
    
    final provider = context.read<OnboardingProvider>();
    await provider.acceptTos();
    
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.privacy);
  }

  void _onDecline() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text(
          'You must accept the Terms of Service to use pep.io. '
          'Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(
              'Exit',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

