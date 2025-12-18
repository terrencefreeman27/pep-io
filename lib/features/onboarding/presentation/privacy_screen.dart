import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import 'onboarding_provider.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              const Spacer(),
              
              // Shield icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 50,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              
              // Title
              Text(
                'Your Privacy Matters',
                style: AppTypography.title1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Privacy points
              _buildPrivacyPoint(
                context,
                Icons.storage_outlined,
                'Local Storage Only',
                'All your data stays on your device. We never transmit, store, or access your information on any server.',
              ),
              _buildPrivacyPoint(
                context,
                Icons.no_accounts_outlined,
                'No Account Required',
                'No email, no password, no login. Your data is yours alone.',
              ),
              _buildPrivacyPoint(
                context,
                Icons.visibility_off_outlined,
                'No Tracking',
                'We don\'t track your usage, collect analytics, or share data with third parties.',
              ),
              _buildPrivacyPoint(
                context,
                Icons.devices_outlined,
                'Your Device, Your Data',
                'You maintain complete control. Export your data anytime.',
              ),
              _buildPrivacyPoint(
                context,
                Icons.backup_outlined,
                'Backup Responsibility',
                'Since data is local-only, we recommend regular device backups through iCloud.',
              ),
              
              const Spacer(),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onContinue(context),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              
              // Privacy policy link
              TextButton(
                onPressed: () => _showPrivacyPolicy(context),
                child: const Text('View Full Privacy Policy'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPoint(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withOpacity(0.1),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryBlue,
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
                  style: AppTypography.headline,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.footnote.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onContinue(BuildContext context) async {
    final provider = context.read<OnboardingProvider>();
    await provider.markPrivacyViewed();
    
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Text(
                'Privacy Policy',
                style: AppTypography.title2,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Text(
                  _privacyPolicyText,
                  style: AppTypography.body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _privacyPolicyText = '''
PRIVACY POLICY FOR PEP.IO

Last Updated: December 2024

1. INTRODUCTION

pep.io ("we", "our", "us") is committed to protecting your privacy. This Privacy Policy explains our data practices for the pep.io mobile application ("App").

2. DATA COLLECTION

We do NOT collect any personal information. The App does not require:
• Email address
• Phone number
• Name (unless you voluntarily enter it for personalization)
• Account creation
• Login credentials

We do NOT collect or transmit any health information. All data you enter (protocols, doses, notes) is stored locally on your device only.

We do NOT collect usage analytics, tracking data, or behavioral information.

We do NOT collect device identifiers, IP addresses, or location data.

3. DATA STORAGE

All data is stored locally on your device using:
• SQLite database
• Local file storage
• iOS secure storage (for sensitive settings)

We do NOT:
• Transmit data to any servers
• Store data in the cloud
• Sync data across devices
• Back up data to our servers

4. DATA SHARING

We do NOT share, sell, rent, or disclose your data to any third parties.

We do NOT use your data for advertising purposes.

We do NOT use third-party analytics services.

5. PERMISSIONS

Calendar Access (Optional): We request permission to access your calendar only to sync your protocol schedules. We do NOT read or access other calendar events.

Notifications (Optional): We request permission to send local notifications. Notifications are generated locally on your device. No data is transmitted to any server.

6. YOUR RIGHTS

You have full access to all your data within the App. You can delete any or all of your data at any time. You can export your data at any time.

7. CONTACT

For questions about this Privacy Policy, contact us through the App Store page.

IN SHORT:
• We do NOT collect any data
• All data stays on your device
• No cloud storage or transmission
• No tracking or analytics
• You control your data completely
''';

