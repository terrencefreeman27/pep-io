import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Important Information',
                    style: AppTypography.title1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.mediumRadius,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.mediumRadius,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          'TERMS OF SERVICE & DISCLAIMER',
                          'Welcome to pep.io. Before accessing this application, you must read and acknowledge the following:',
                        ),
                        _buildSection(
                          'EDUCATIONAL PURPOSE ONLY',
                          '''This application is designed for educational, informational, and personal tracking purposes only. It does NOT:
                          
• Provide medical advice
• Diagnose any condition
• Treat any disease or illness
• Replace consultation with licensed healthcare professionals''',
                        ),
                        _buildSection(
                          'NO MEDICAL CLAIMS',
                          '''• pep.io does not make any therapeutic claims about peptides
• Information provided is from publicly available, non-clinical sources
• Benefits listed are "commonly researched" or "community-discussed" only
• We do not endorse or recommend any specific peptide or protocol''',
                        ),
                        _buildSection(
                          'USER RESPONSIBILITY',
                          '''• Consult a licensed healthcare professional before making any decisions related to peptides
• Do not use this app to self-diagnose or self-treat
• Results may vary; no outcomes are guaranteed
• You are solely responsible for your use of the information provided''',
                        ),
                        _buildSection(
                          'DATA & PRIVACY',
                          '''• All data is stored locally on your device only
• No cloud storage or data transmission occurs
• You are responsible for backing up your own data
• pep.io cannot recover lost data''',
                        ),
                        _buildSection(
                          'COMPLIANCE',
                          '''• This app complies with Apple App Store guidelines
• No prescription services are offered
• No product sales or referrals are made
• We are not affiliated with any peptide manufacturers''',
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          'By tapping "I Understand and Agree" below, you acknowledge that you have read, understood, and agree to these terms.',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.l),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                  // Checkbox
                  AnimatedOpacity(
                    opacity: _hasScrolledToBottom ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    child: InkWell(
                      onTap: _hasScrolledToBottom
                          ? () => setState(() => _hasCheckedBox = !_hasCheckedBox)
                          : null,
                      borderRadius: AppRadius.smallRadius,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _hasCheckedBox,
                              onChanged: _hasScrolledToBottom
                                  ? (value) => setState(() => _hasCheckedBox = value ?? false)
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.xs),
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
                  
                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasCheckedBox ? _onAgree : null,
                      child: const Text('I Understand and Agree'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextButton(
                    onPressed: _onDecline,
                    child: Text(
                      'Decline',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headline.copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            content,
            style: AppTypography.body,
          ),
        ],
      ),
    );
  }

  Future<void> _onAgree() async {
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

