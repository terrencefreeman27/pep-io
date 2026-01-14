import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/services/premium_service.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.title3),
      ),
      body: Consumer2<SettingsProvider, PremiumService>(
        builder: (context, settings, premiumService, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              // Premium Section
              _AnimatedSection(
                index: 0,
                title: 'Subscription',
                child: _buildPremiumCard(context, premiumService, isDark),
              ),

              const SizedBox(height: AppSpacing.l),

              // Profile Section
              _AnimatedSection(
                index: 1,
                title: 'Profile',
                child: _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline,
                      iconColor: AppColors.primaryBlue,
                      title: 'Personal Information',
                      subtitle: 'Name, weight, units',
                      onTap: () => _showProfileEditor(context, settings),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.flag_outlined,
                      iconColor: AppColors.orange,
                      title: 'Goals',
                      subtitle: 'Set your primary goals',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.goals),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Notifications Section
              _AnimatedSection(
                index: 2,
                title: 'Notifications',
                child: _SettingsCard(
                  children: [
                    _SettingsToggle(
                      icon: Icons.notifications_outlined,
                      iconColor: AppColors.purple,
                      title: 'Dose Reminders',
                      subtitle: 'Get notified when doses are due',
                      value: settings.doseRemindersEnabled,
                      onChanged: (value) => settings.setDoseReminders(value),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.access_time,
                      iconColor: AppColors.teal,
                      title: 'Default Reminder Time',
                      subtitle: '${settings.reminderMinutesBefore} minutes before',
                      enabled: settings.doseRemindersEnabled,
                      onTap: () => _showReminderTimePicker(context, settings),
                    ),
                    const _SettingsDivider(),
                    _SettingsToggle(
                      icon: Icons.nights_stay_outlined,
                      iconColor: AppColors.indigo,
                      title: 'Do Not Disturb',
                      subtitle: 'Silent from ${_formatTime(settings.dndStartTime)} - ${_formatTime(settings.dndEndTime)}',
                      value: settings.doNotDisturbEnabled,
                      onChanged: (value) => settings.setDoNotDisturb(value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Calendar Integration Section
              _AnimatedSection(
                index: 3,
                title: 'Calendar Integration',
                child: _SettingsCard(
                  children: [
                    _SettingsToggle(
                      icon: Icons.calendar_month_outlined,
                      iconColor: AppColors.green,
                      title: 'Apple Calendar Sync',
                      subtitle: 'Sync protocol doses to your calendar',
                      value: settings.calendarSyncEnabled,
                      onChanged: (value) async {
                        await settings.setCalendarSync(value);
                        if (settings.error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(settings.error!),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            settings.clearError();
                        }
                      },
                    ),
                    if (settings.calendarSyncEnabled) ...[
                      const _SettingsDivider(),
                      _SettingsTile(
                        icon: Icons.event_note_outlined,
                        iconColor: AppColors.green,
                        title: 'Calendar',
                        subtitle: settings.selectedCalendarName ?? 'Select a calendar',
                        onTap: () => _showCalendarPicker(context, settings),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Appearance Section
              _AnimatedSection(
                index: 4,
                title: 'Appearance',
                child: _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.palette_outlined,
                      iconColor: AppColors.pink,
                      title: 'Theme',
                      subtitle: _getThemeName(settings.themeMode),
                      onTap: () => _showThemePicker(context, settings),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.straighten,
                      iconColor: AppColors.yellow,
                      title: 'Units',
                      subtitle: settings.useMetricUnits ? 'Metric (kg, mL)' : 'Imperial (lbs, oz)',
                      onTap: () => _showUnitsPicker(context, settings),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Data & Privacy Section
              _AnimatedSection(
                index: 5,
                title: 'Data & Privacy',
                child: _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.file_download_outlined,
                      iconColor: AppColors.teal,
                      title: 'Export Data',
                      subtitle: 'Download your data as CSV',
                      onTap: () => _exportData(context),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.backup_outlined,
                      iconColor: AppColors.primaryBlue,
                      title: 'Backup',
                      subtitle: 'Create a local backup',
                      onTap: () => _createBackup(context),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.delete_outline,
                      iconColor: AppColors.error,
                      title: 'Delete All Data',
                      subtitle: 'Permanently delete all app data',
                      titleColor: AppColors.error,
                      onTap: () => _confirmDeleteData(context, settings),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // About Section
              _AnimatedSection(
                index: 6,
                title: 'About',
                child: _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline,
                      iconColor: AppColors.primaryBlue,
                      title: 'About pep.io',
                      onTap: () => _showAboutDialog(context),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      iconColor: AppColors.mediumGray,
                      title: 'Terms of Service',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.disclaimer),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppColors.mediumGray,
                      title: 'Privacy Policy',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.star_outline,
                      iconColor: AppColors.yellow,
                      title: 'Rate This App',
                      onTap: () => _rateApp(context),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      iconColor: AppColors.purple,
                      title: 'Contact Support',
                      onTap: () => _contactSupport(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Version info
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.largeRadius,
                        boxShadow: AppShadows.glow(AppColors.primaryBlue, intensity: 0.3),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.largeRadius,
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Icon(
                                Icons.science_outlined,
                                color: Colors.white,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'pep.io',
                      style: AppTypography.headline.copyWith(
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms),

              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, PremiumService premiumService, bool isDark) {
    if (premiumService.isPremium) {
      // Premium user card
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withOpacity(0.15),
              AppColors.purple.withOpacity(0.1),
            ],
          ),
          borderRadius: AppRadius.largeRadius,
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: AppRadius.mediumRadius,
                      boxShadow: AppShadows.glow(AppColors.accent, intensity: 0.3),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Premium',
                              style: AppTypography.headline.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: AppTypography.caption2.copyWith(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          premiumService.subscriptionExpiry != null
                              ? 'Renews ${_formatDate(premiumService.subscriptionExpiry!)}'
                              : 'All premium features unlocked',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              // Features list
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.xs,
                children: [
                  _PremiumFeatureChip(label: 'Unlimited Protocols', icon: Icons.all_inclusive),
                  _PremiumFeatureChip(label: 'Large Widgets', icon: Icons.widgets),
                  _PremiumFeatureChip(label: 'AI Insights', icon: Icons.auto_awesome),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Free user card - encourage upgrade
      return _SettingsCard(
        children: [
          BouncyTap(
            onTap: () => Navigator.pushNamed(context, AppRoutes.upgrade),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: AppRadius.mediumRadius,
                    ),
                    child: const Icon(
                      Icons.star_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to Premium',
                          style: AppTypography.headline.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Unlimited protocols, widgets & more',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: AppRadius.mediumRadius,
                    ),
                    child: Text(
                      'PRO',
                      style: AppTypography.caption1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showProfileEditor(BuildContext context, SettingsProvider settings) {
    final nameController = TextEditingController(text: settings.userName);
    final weightController = TextEditingController(
      text: settings.userWeight?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text('Personal Information', style: AppTypography.title3),
              const SizedBox(height: AppSpacing.l),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (${settings.useMetricUnits ? 'kg' : 'lbs'})',
                  prefixIcon: const Icon(Icons.monitor_weight_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.l),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    settings.setUserName(nameController.text);
                    if (weightController.text.isNotEmpty) {
                      settings.setUserWeight(double.tryParse(weightController.text));
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
          ),
        ),
      ),
    );
  }

  void _showReminderTimePicker(BuildContext context, SettingsProvider settings) {
    final options = [5, 10, 15, 30, 60];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.m),
            Text('Reminder Time', style: AppTypography.title3),
            const SizedBox(height: AppSpacing.m),
            ...options.map((minutes) => ListTile(
                  title: Text('$minutes minutes before'),
                  trailing: settings.reminderMinutesBefore == minutes
                  ? Icon(Icons.check_circle, color: AppColors.primaryBlue)
                      : null,
                  onTap: () {
                    settings.setReminderMinutes(minutes);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  Future<void> _showCalendarPicker(BuildContext context, SettingsProvider settings) async {
    if (settings.availableCalendars.isEmpty) {
      await settings.loadAvailableCalendars();
    }

    if (!context.mounted) return;

    if (settings.availableCalendars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No calendars available. Please check calendar permissions.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: AppSpacing.s),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Text('Select Calendar', style: AppTypography.title3),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: settings.availableCalendars.length,
                  itemBuilder: (context, index) {
                    final calendar = settings.availableCalendars[index];
                    final isSelected = calendar.id == settings.selectedCalendar;
                    
                    Color calendarColor = AppColors.primaryBlue;
                    if (calendar.color != null) {
                      calendarColor = Color(calendar.color!);
                    }
                    
                    return ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: calendarColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      title: Text(calendar.name ?? 'Unknown'),
                      subtitle: calendar.accountName != null
                          ? Text(
                              calendar.accountName!,
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.mediumGray,
                              ),
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: AppColors.primaryBlue)
                          : null,
                      onTap: () {
                        settings.selectCalendar(calendar);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.m),
            Text('Theme', style: AppTypography.title3),
            const SizedBox(height: AppSpacing.m),
            _ThemeOption(
              icon: Icons.light_mode,
              title: 'Light',
              isSelected: settings.themeMode == ThemeMode.light,
              onTap: () {
                settings.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.dark_mode,
              title: 'Dark',
              isSelected: settings.themeMode == ThemeMode.dark,
              onTap: () {
                settings.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.settings_system_daydream,
              title: 'System',
              isSelected: settings.themeMode == ThemeMode.system,
              onTap: () {
                settings.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  void _showUnitsPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.m),
            Text('Units', style: AppTypography.title3),
            const SizedBox(height: AppSpacing.m),
            ListTile(
              title: const Text('Metric (kg, mL)'),
              trailing: settings.useMetricUnits
                  ? Icon(Icons.check_circle, color: AppColors.primaryBlue)
                  : null,
              onTap: () {
                settings.setUseMetricUnits(true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Imperial (lbs, oz)'),
              trailing: !settings.useMetricUnits
                  ? Icon(Icons.check_circle, color: AppColors.primaryBlue)
                  : null,
              onTap: () {
                settings.setUseMetricUnits(false);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  void _exportData(BuildContext context) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data exported successfully')),
    );
  }

  void _createBackup(BuildContext context) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup created successfully')),
    );
  }

  void _confirmDeleteData(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete All Data?',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'This will permanently delete all your protocols, dose history, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              settings.deleteAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data has been deleted')),
              );
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: AppRadius.largeRadius,
                boxShadow: AppShadows.glow(AppColors.primaryBlue, intensity: 0.3),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.largeRadius,
                child: Image.asset(
                  'assets/images/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.science_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text('pep.io', style: AppTypography.title2),
            const SizedBox(height: AppSpacing.s),
            Text(
              'pep.io is an educational peptide tracking application designed to help users organize and understand their peptide research protocols.',
              style: AppTypography.body.copyWith(color: AppColors.mediumGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Version 1.0.0\n© 2024 pep.io',
              style: AppTypography.caption1.copyWith(color: AppColors.mediumGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your support!')),
    );
  }

  void _contactSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening email...')),
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final int index;
  final String title;
  final Widget child;

  const _AnimatedSection({
    required this.index,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption1.copyWith(
          color: AppColors.mediumGray,
          letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
        ),
      ),
        ),
        child,
      ],
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 100), duration: 400.ms)
        .slideY(begin: 0.05, end: 0, delay: Duration(milliseconds: index * 100));
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: AppRadius.largeRadius,
        border: Border.all(
          color: isDark ? AppColors.cardDark : AppColors.lightGray.withOpacity(0.5),
        ),
        boxShadow: isDark ? null : AppShadows.level1,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool enabled;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: AppRadius.mediumRadius,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.mediumGray,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.mediumGray,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: AppRadius.mediumRadius,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body),
                Text(
                  subtitle,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(height: 1, color: AppColors.lightGray.withOpacity(0.5)),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.1)
              : AppColors.softGray,
          borderRadius: AppRadius.mediumRadius,
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primaryBlue : AppColors.mediumGray,
        ),
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primaryBlue)
          : null,
      onTap: onTap,
    );
  }
}

class _PremiumFeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PremiumFeatureChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: AppRadius.smallRadius,
        border: Border.all(
          color: AppColors.accent.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption2.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
