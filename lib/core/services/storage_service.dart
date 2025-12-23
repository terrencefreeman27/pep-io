import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for simple key-value storage
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Keys
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyTosAccepted = 'tos_accepted';
  static const String keyTosAcceptedAt = 'tos_accepted_at';
  static const String keyPrivacyViewed = 'privacy_viewed';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyCalendarSyncEnabled = 'calendar_sync_enabled';
  static const String keyDefaultCalendarId = 'default_calendar_id';
  static const String keyQuietHoursEnabled = 'quiet_hours_enabled';
  static const String keyQuietHoursStart = 'quiet_hours_start';
  static const String keyQuietHoursEnd = 'quiet_hours_end';
  static const String keyDailySummaryEnabled = 'daily_summary_enabled';
  static const String keyDailySummaryTime = 'daily_summary_time';
  static const String keyMissedDoseDelay = 'missed_dose_delay';
  static const String keyLastReviewPrompt = 'last_review_prompt';
  static const String keyReviewPromptCount = 'review_prompt_count';
  static const String keyDraftProtocol = 'draft_protocol';
  static const String keyDraftProtocolTimestamp = 'draft_protocol_timestamp';

  // String operations
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Int operations
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Bool operations
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Double operations
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  // Remove key
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // Clear all
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  // Onboarding
  bool get isOnboardingCompleted => getBool(keyOnboardingCompleted) ?? false;
  Future<void> setOnboardingCompleted(bool value) => setBool(keyOnboardingCompleted, value);

  // TOS
  bool get isTosAccepted => getBool(keyTosAccepted) ?? false;
  Future<void> setTosAccepted(bool value) async {
    await setBool(keyTosAccepted, value);
    if (value) {
      await setInt(keyTosAcceptedAt, DateTime.now().millisecondsSinceEpoch);
    }
  }
  DateTime? get tosAcceptedAt {
    final timestamp = getInt(keyTosAcceptedAt);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // Privacy
  bool get isPrivacyViewed => getBool(keyPrivacyViewed) ?? false;
  Future<void> setPrivacyViewed(bool value) => setBool(keyPrivacyViewed, value);

  // Theme
  String get themeMode => getString(keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String value) => setString(keyThemeMode, value);

  // Notifications
  bool get notificationsEnabled => getBool(keyNotificationsEnabled) ?? false;
  Future<void> setNotificationsEnabled(bool value) => setBool(keyNotificationsEnabled, value);

  // Calendar Sync
  bool get calendarSyncEnabled => getBool(keyCalendarSyncEnabled) ?? false;
  Future<void> setCalendarSyncEnabled(bool value) => setBool(keyCalendarSyncEnabled, value);

  String? get defaultCalendarId => getString(keyDefaultCalendarId);
  Future<void> setDefaultCalendarId(String? value) async {
    if (value != null) {
      await setString(keyDefaultCalendarId, value);
    } else {
      await remove(keyDefaultCalendarId);
    }
  }

  // Quiet Hours
  bool get quietHoursEnabled => getBool(keyQuietHoursEnabled) ?? false;
  Future<void> setQuietHoursEnabled(bool value) => setBool(keyQuietHoursEnabled, value);

  String get quietHoursStart => getString(keyQuietHoursStart) ?? '22:00';
  Future<void> setQuietHoursStart(String value) => setString(keyQuietHoursStart, value);

  String get quietHoursEnd => getString(keyQuietHoursEnd) ?? '07:00';
  Future<void> setQuietHoursEnd(String value) => setString(keyQuietHoursEnd, value);

  // Daily Summary
  bool get dailySummaryEnabled => getBool(keyDailySummaryEnabled) ?? false;
  Future<void> setDailySummaryEnabled(bool value) => setBool(keyDailySummaryEnabled, value);

  String get dailySummaryTime => getString(keyDailySummaryTime) ?? '08:00';
  Future<void> setDailySummaryTime(String value) => setString(keyDailySummaryTime, value);

  // Missed Dose Delay (in minutes)
  int get missedDoseDelay => getInt(keyMissedDoseDelay) ?? 30;
  Future<void> setMissedDoseDelay(int value) => setInt(keyMissedDoseDelay, value);

  // Review Prompts
  DateTime? get lastReviewPrompt {
    final timestamp = getInt(keyLastReviewPrompt);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  Future<void> setLastReviewPrompt(DateTime value) => setInt(keyLastReviewPrompt, value.millisecondsSinceEpoch);

  int get reviewPromptCount => getInt(keyReviewPromptCount) ?? 0;
  Future<void> incrementReviewPromptCount() => setInt(keyReviewPromptCount, reviewPromptCount + 1);

  // Draft Protocol
  String? get draftProtocol => getString(keyDraftProtocol);
  Future<void> setDraftProtocol(String? value) async {
    if (value != null) {
      await setString(keyDraftProtocol, value);
      await setInt(keyDraftProtocolTimestamp, DateTime.now().millisecondsSinceEpoch);
    } else {
      await remove(keyDraftProtocol);
      await remove(keyDraftProtocolTimestamp);
    }
  }

  DateTime? get draftProtocolTimestamp {
    final timestamp = getInt(keyDraftProtocolTimestamp);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  bool get hasDraftProtocol => draftProtocol != null;

  Future<void> clearDraftProtocol() async {
    await remove(keyDraftProtocol);
    await remove(keyDraftProtocolTimestamp);
  }
}

