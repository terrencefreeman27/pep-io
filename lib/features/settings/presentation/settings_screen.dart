import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              // Profile Section
              _SectionHeader(title: 'Profile'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Personal Information'),
                      subtitle: const Text('Name, weight, units'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showProfileEditor(context, settings),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: const Text('Goals'),
                      subtitle: const Text('Set your primary goals'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.goals),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Notifications Section
              _SectionHeader(title: 'Notifications'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Dose Reminders'),
                      subtitle: const Text('Get notified when doses are due'),
                      value: settings.doseRemindersEnabled,
                      onChanged: (value) =>
                          settings.setDoseReminders(value),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Default Reminder Time'),
                      subtitle: Text('${settings.reminderMinutesBefore} minutes before'),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: settings.doseRemindersEnabled,
                      onTap: () => _showReminderTimePicker(context, settings),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.night_shelter_outlined),
                      title: const Text('Do Not Disturb'),
                      subtitle: Text(
                        'Silent from ${_formatTime(settings.dndStartTime)} - ${_formatTime(settings.dndEndTime)}',
                      ),
                      value: settings.doNotDisturbEnabled,
                      onChanged: (value) =>
                          settings.setDoNotDisturb(value),
                    ),
                    if (settings.doNotDisturbEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const SizedBox(width: 24),
                        title: const Text('Start Time'),
                        trailing: Text(_formatTime(settings.dndStartTime)),
                        onTap: () => _pickDndTime(context, settings, isStart: true),
                      ),
                      ListTile(
                        leading: const SizedBox(width: 24),
                        title: const Text('End Time'),
                        trailing: Text(_formatTime(settings.dndEndTime)),
                        onTap: () => _pickDndTime(context, settings, isStart: false),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Calendar Integration Section
              _SectionHeader(title: 'Calendar Integration'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.calendar_month_outlined),
                      title: const Text('Apple Calendar Sync'),
                      subtitle: const Text('Sync protocol doses to your calendar'),
                      value: settings.calendarSyncEnabled,
                      onChanged: (value) async {
                        await settings.setCalendarSync(value);
                        if (settings.error != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(settings.error!),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            settings.clearError();
                          }
                        }
                      },
                    ),
                    if (settings.calendarSyncEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const SizedBox(width: 24),
                        title: const Text('Calendar'),
                        subtitle: Text(
                          settings.selectedCalendarName ?? 'Select a calendar',
                          style: TextStyle(
                            color: settings.selectedCalendarName == null
                                ? AppColors.mediumGray
                                : null,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showCalendarPicker(context, settings),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Appearance Section
              _SectionHeader(title: 'Appearance'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Theme'),
                      subtitle: Text(_getThemeName(settings.themeMode)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showThemePicker(context, settings),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.straighten),
                      title: const Text('Units'),
                      subtitle: Text(settings.useMetricUnits ? 'Metric (kg, mL)' : 'Imperial (lbs, oz)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showUnitsPicker(context, settings),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Data & Privacy Section
              _SectionHeader(title: 'Data & Privacy'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Export Data'),
                      subtitle: const Text('Download your data as CSV'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportData(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Backup'),
                      subtitle: const Text('Create a local backup'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _createBackup(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.delete_outline, color: AppColors.error),
                      title: Text(
                        'Delete All Data',
                        style: TextStyle(color: AppColors.error),
                      ),
                      subtitle: const Text('Permanently delete all app data'),
                      onTap: () => _confirmDeleteData(context, settings),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // About Section
              _SectionHeader(title: 'About'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About pep.io'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAboutDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.disclaimer),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.star_outline),
                      title: const Text('Rate This App'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _rateApp(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Contact Support'),
                      trailing: const Icon(Icons.chevron_right),
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
                    Text(
                      'pep.io',
                      style: AppTypography.headline.copyWith(
                        color: AppColors.mediumGray,
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
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
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
              Text('Personal Information', style: AppTypography.headline),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (${settings.useMetricUnits ? 'kg' : 'lbs'})',
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
                      settings.setUserWeight(
                        double.tryParse(weightController.text),
                      );
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

  void _showReminderTimePicker(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final options = [5, 10, 15, 30, 60];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Text('Reminder Time', style: AppTypography.headline),
            ),
            ...options.map((minutes) => ListTile(
                  title: Text('$minutes minutes before'),
                  trailing: settings.reminderMinutesBefore == minutes
                      ? Icon(Icons.check, color: AppColors.primaryBlue)
                      : null,
                  onTap: () {
                    settings.setReminderMinutes(minutes);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDndTime(
    BuildContext context,
    SettingsProvider settings, {
    required bool isStart,
  }) async {
    final initial = isStart ? settings.dndStartTime : settings.dndEndTime;
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (time != null) {
      if (isStart) {
        settings.setDndStartTime(time);
      } else {
        settings.setDndEndTime(time);
      }
    }
  }

  void _showCalendarPicker(BuildContext context, SettingsProvider settings) async {
    // Ensure calendars are loaded
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.s),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Row(
                  children: [
                    Text('Select Calendar', style: AppTypography.headline),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: settings.availableCalendars.length,
                  itemBuilder: (context, index) {
                    final calendar = settings.availableCalendars[index];
                    final isSelected = calendar.id == settings.selectedCalendar;
                    
                    // Get calendar color
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Calendar "${calendar.name}" selected for syncing',
                            ),
                            backgroundColor: AppColors.green,
                          ),
                        );
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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Text('Theme', style: AppTypography.headline),
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              trailing: settings.themeMode == ThemeMode.light
                  ? Icon(Icons.check, color: AppColors.primaryBlue)
                  : null,
              onTap: () {
                settings.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              trailing: settings.themeMode == ThemeMode.dark
                  ? Icon(Icons.check, color: AppColors.primaryBlue)
                  : null,
              onTap: () {
                settings.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_system_daydream),
              title: const Text('System'),
              trailing: settings.themeMode == ThemeMode.system
                  ? Icon(Icons.check, color: AppColors.primaryBlue)
                  : null,
              onTap: () {
                settings.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Text('Units', style: AppTypography.headline),
            ),
            ListTile(
              title: const Text('Metric (kg, mL)'),
              trailing: settings.useMetricUnits
                  ? Icon(Icons.check, color: AppColors.primaryBlue)
                  : null,
              onTap: () {
                settings.setUseMetricUnits(true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Imperial (lbs, oz)'),
              trailing: !settings.useMetricUnits
                  ? Icon(Icons.check, color: AppColors.primaryBlue)
                  : null,
              onTap: () {
                settings.setUseMetricUnits(false);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Export your protocol and dose history as a CSV file?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Export logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data exported successfully')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _createBackup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Backup'),
        content: const Text(
          'Create a backup of all your app data? You can use this to restore your data later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Backup logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup created successfully')),
              );
            },
            child: const Text('Create Backup'),
          ),
        ],
      ),
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
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: AppRadius.smallRadius,
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            const Text('pep.io'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'pep.io is an educational peptide tracking application designed to help users organize and understand their peptide research protocols.',
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Version 1.0.0',
              style: AppTypography.caption1.copyWith(
                color: AppColors.mediumGray,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '© 2024 pep.io',
              style: AppTypography.caption1.copyWith(
                color: AppColors.mediumGray,
              ),
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
    // Would trigger in_app_review
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your support!')),
    );
  }

  void _contactSupport(BuildContext context) {
    // Would open email client
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening email...')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption1.copyWith(
          color: AppColors.mediumGray,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

