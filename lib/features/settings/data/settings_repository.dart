import '../../../core/services/storage_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/user_profile.dart';

/// Repository for settings data operations
class SettingsRepository {
  final StorageService _storageService;
  final DatabaseService _databaseService;

  SettingsRepository(this._storageService, this._databaseService);

  // User Profile
  Future<UserProfile?> getUserProfile() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<UserProfile> saveUserProfile(UserProfile profile) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    
    if (profile.id == 0) {
      // Insert new profile
      final id = await db.insert('user_profile', {
        'name': profile.name,
        'weight': profile.weight,
        'weight_unit': profile.weightUnit,
        'primary_goal': profile.primaryGoal,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      return profile.copyWith(id: id, createdAt: now, updatedAt: now);
    } else {
      // Update existing profile
      await db.update(
        'user_profile',
        {
          'name': profile.name,
          'weight': profile.weight,
          'weight_unit': profile.weightUnit,
          'primary_goal': profile.primaryGoal,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [profile.id],
      );
      return profile.copyWith(updatedAt: now);
    }
  }

  // User Goals
  Future<List<String>> getUserGoals() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('user_goals');
    return maps.map((m) => m['goal_category'] as String).toList();
  }

  Future<void> saveUserGoals(List<String> goals) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      // Clear existing goals
      await txn.delete('user_goals');
      
      // Insert new goals
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final goal in goals) {
        await txn.insert('user_goals', {
          'goal_category': goal,
          'created_at': now,
        });
      }
    });
  }

  // Theme
  String get themeMode => _storageService.themeMode;
  Future<void> setThemeMode(String mode) => _storageService.setThemeMode(mode);

  // Notifications
  bool get notificationsEnabled => _storageService.notificationsEnabled;
  Future<void> setNotificationsEnabled(bool enabled) => 
      _storageService.setNotificationsEnabled(enabled);

  bool get quietHoursEnabled => _storageService.quietHoursEnabled;
  Future<void> setQuietHoursEnabled(bool enabled) => 
      _storageService.setQuietHoursEnabled(enabled);

  String get quietHoursStart => _storageService.quietHoursStart;
  Future<void> setQuietHoursStart(String time) => 
      _storageService.setQuietHoursStart(time);

  String get quietHoursEnd => _storageService.quietHoursEnd;
  Future<void> setQuietHoursEnd(String time) => 
      _storageService.setQuietHoursEnd(time);

  bool get dailySummaryEnabled => _storageService.dailySummaryEnabled;
  Future<void> setDailySummaryEnabled(bool enabled) => 
      _storageService.setDailySummaryEnabled(enabled);

  String get dailySummaryTime => _storageService.dailySummaryTime;
  Future<void> setDailySummaryTime(String time) => 
      _storageService.setDailySummaryTime(time);

  int get missedDoseDelay => _storageService.missedDoseDelay;
  Future<void> setMissedDoseDelay(int minutes) => 
      _storageService.setMissedDoseDelay(minutes);

  // Calendar
  bool get calendarSyncEnabled => _storageService.calendarSyncEnabled;
  Future<void> setCalendarSyncEnabled(bool enabled) => 
      _storageService.setCalendarSyncEnabled(enabled);

  String? get defaultCalendarId => _storageService.defaultCalendarId;
  Future<void> setDefaultCalendarId(String? id) => 
      _storageService.setDefaultCalendarId(id);

  // Data Export/Import
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await _databaseService.database;
    
    final userProfile = await getUserProfile();
    final userGoals = await getUserGoals();
    
    final protocols = await db.query('protocols');
    final doses = await db.query('doses');
    final calculations = await db.query('calculations');
    final peptideNotes = await db.query(
      'peptides',
      columns: ['id', 'user_notes', 'is_favorite'],
      where: 'user_notes IS NOT NULL OR is_favorite = 1',
    );
    
    return {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'user_profile': userProfile?.toMap(),
      'user_goals': userGoals,
      'protocols': protocols,
      'doses': doses,
      'calculations': calculations,
      'peptide_customizations': peptideNotes,
      'settings': {
        'theme_mode': themeMode,
        'notifications_enabled': notificationsEnabled,
        'quiet_hours_enabled': quietHoursEnabled,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
        'daily_summary_enabled': dailySummaryEnabled,
        'daily_summary_time': dailySummaryTime,
        'calendar_sync_enabled': calendarSyncEnabled,
      },
    };
  }

  Future<void> deleteAllData() async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      await txn.delete('doses');
      await txn.delete('protocols');
      await txn.delete('calculations');
      await txn.delete('user_goals');
      await txn.delete('user_profile');
      await txn.delete('onboarding_data');
      
      // Reset peptide customizations
      await txn.update('peptides', {
        'user_notes': null,
        'is_favorite': 0,
        'view_count': 0,
        'last_viewed': null,
      });
    });
    
    await _storageService.clear();
  }
}

