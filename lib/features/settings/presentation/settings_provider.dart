import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../data/settings_repository.dart';

/// Provider for settings state management
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  UserProfile? _userProfile;
  List<String> _userGoals = [];
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = false;
  bool _doseRemindersEnabled = true;
  int _reminderMinutesBefore = 15;
  bool _doNotDisturbEnabled = false;
  TimeOfDay _dndStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dndEndTime = const TimeOfDay(hour: 7, minute: 0);
  bool _quietHoursEnabled = false;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '07:00';
  bool _dailySummaryEnabled = false;
  String _dailySummaryTime = '08:00';
  int _missedDoseDelay = 30;
  bool _calendarSyncEnabled = false;
  String? _selectedCalendar;
  String? _defaultCalendarId;
  bool _useMetricUnits = true;
  String? _userName;
  double? _userWeight;
  bool _isLoading = false;
  String? _error;

  SettingsProvider(this._repository);

  // Getters
  UserProfile? get userProfile => _userProfile;
  List<String> get userGoals => _userGoals;
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get doseRemindersEnabled => _doseRemindersEnabled;
  int get reminderMinutesBefore => _reminderMinutesBefore;
  bool get doNotDisturbEnabled => _doNotDisturbEnabled;
  TimeOfDay get dndStartTime => _dndStartTime;
  TimeOfDay get dndEndTime => _dndEndTime;
  bool get quietHoursEnabled => _quietHoursEnabled;
  String get quietHoursStart => _quietHoursStart;
  String get quietHoursEnd => _quietHoursEnd;
  bool get dailySummaryEnabled => _dailySummaryEnabled;
  String get dailySummaryTime => _dailySummaryTime;
  int get missedDoseDelay => _missedDoseDelay;
  bool get calendarSyncEnabled => _calendarSyncEnabled;
  String? get selectedCalendar => _selectedCalendar;
  String? get defaultCalendarId => _defaultCalendarId;
  bool get useMetricUnits => _useMetricUnits;
  String? get userName => _userName;
  double? get userWeight => _userWeight;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize settings from storage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _repository.getUserProfile();
      _userGoals = await _repository.getUserGoals();
      
      _themeMode = _parseThemeMode(_repository.themeMode);
      _notificationsEnabled = _repository.notificationsEnabled;
      _quietHoursEnabled = _repository.quietHoursEnabled;
      _quietHoursStart = _repository.quietHoursStart;
      _quietHoursEnd = _repository.quietHoursEnd;
      _dailySummaryEnabled = _repository.dailySummaryEnabled;
      _dailySummaryTime = _repository.dailySummaryTime;
      _missedDoseDelay = _repository.missedDoseDelay;
      _calendarSyncEnabled = _repository.calendarSyncEnabled;
      _defaultCalendarId = _repository.defaultCalendarId;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Parse theme mode string to ThemeMode
  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Save user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      _userProfile = await _repository.saveUserProfile(profile);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update user name
  Future<void> updateUserName(String? name) async {
    if (_userProfile != null) {
      await saveUserProfile(_userProfile!.copyWith(name: name));
    } else {
      await saveUserProfile(UserProfile(
        id: 0,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  /// Update user weight
  Future<void> updateUserWeight(double? weight, String? unit) async {
    if (_userProfile != null) {
      await saveUserProfile(_userProfile!.copyWith(
        weight: weight,
        weightUnit: unit,
      ));
    }
  }

  /// Update primary goal
  Future<void> updatePrimaryGoal(String? goal) async {
    if (_userProfile != null) {
      await saveUserProfile(_userProfile!.copyWith(primaryGoal: goal));
    }
  }

  /// Save user goals
  Future<void> saveUserGoals(List<String> goals) async {
    try {
      await _repository.saveUserGoals(goals);
      _userGoals = goals;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    final modeString = mode == ThemeMode.light 
        ? 'light' 
        : mode == ThemeMode.dark 
            ? 'dark' 
            : 'system';
    await _repository.setThemeMode(modeString);
    _themeMode = mode;
    notifyListeners();
  }

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _repository.setNotificationsEnabled(enabled);
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  /// Set quiet hours enabled
  Future<void> setQuietHoursEnabled(bool enabled) async {
    await _repository.setQuietHoursEnabled(enabled);
    _quietHoursEnabled = enabled;
    notifyListeners();
  }

  /// Set quiet hours start time
  Future<void> setQuietHoursStart(String time) async {
    await _repository.setQuietHoursStart(time);
    _quietHoursStart = time;
    notifyListeners();
  }

  /// Set quiet hours end time
  Future<void> setQuietHoursEnd(String time) async {
    await _repository.setQuietHoursEnd(time);
    _quietHoursEnd = time;
    notifyListeners();
  }

  /// Set daily summary enabled
  Future<void> setDailySummaryEnabled(bool enabled) async {
    await _repository.setDailySummaryEnabled(enabled);
    _dailySummaryEnabled = enabled;
    notifyListeners();
  }

  /// Set daily summary time
  Future<void> setDailySummaryTime(String time) async {
    await _repository.setDailySummaryTime(time);
    _dailySummaryTime = time;
    notifyListeners();
  }

  /// Set missed dose delay
  Future<void> setMissedDoseDelay(int minutes) async {
    await _repository.setMissedDoseDelay(minutes);
    _missedDoseDelay = minutes;
    notifyListeners();
  }

  /// Set calendar sync enabled
  Future<void> setCalendarSyncEnabled(bool enabled) async {
    await _repository.setCalendarSyncEnabled(enabled);
    _calendarSyncEnabled = enabled;
    notifyListeners();
  }

  /// Set default calendar ID
  Future<void> setDefaultCalendarId(String? id) async {
    await _repository.setDefaultCalendarId(id);
    _defaultCalendarId = id;
    notifyListeners();
  }

  /// Export all data
  Future<Map<String, dynamic>> exportData() async {
    return _repository.exportAllData();
  }

  /// Delete all data
  Future<void> deleteAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteAllData();
      _userProfile = null;
      _userGoals = [];
      _themeMode = ThemeMode.system;
      _notificationsEnabled = false;
      _quietHoursEnabled = false;
      _dailySummaryEnabled = false;
      _calendarSyncEnabled = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set dose reminders enabled
  void setDoseReminders(bool enabled) {
    _doseRemindersEnabled = enabled;
    notifyListeners();
  }

  /// Set reminder minutes before
  void setReminderMinutes(int minutes) {
    _reminderMinutesBefore = minutes;
    notifyListeners();
  }

  /// Set do not disturb enabled
  void setDoNotDisturb(bool enabled) {
    _doNotDisturbEnabled = enabled;
    notifyListeners();
  }

  /// Set DND start time
  void setDndStartTime(TimeOfDay time) {
    _dndStartTime = time;
    notifyListeners();
  }

  /// Set DND end time
  void setDndEndTime(TimeOfDay time) {
    _dndEndTime = time;
    notifyListeners();
  }

  /// Set calendar sync
  void setCalendarSync(bool enabled) {
    _calendarSyncEnabled = enabled;
    notifyListeners();
  }

  /// Set use metric units
  void setUseMetricUnits(bool useMetric) {
    _useMetricUnits = useMetric;
    notifyListeners();
  }

  /// Set user name
  void setUserName(String? name) {
    _userName = name;
    notifyListeners();
  }

  /// Set user weight
  void setUserWeight(double? weight) {
    _userWeight = weight;
    notifyListeners();
  }
}

