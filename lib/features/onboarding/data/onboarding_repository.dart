import '../../../core/services/storage_service.dart';
import '../../../core/services/database_service.dart';

/// Repository for onboarding data operations
class OnboardingRepository {
  final StorageService _storageService;
  final DatabaseService _databaseService;

  OnboardingRepository(this._storageService, this._databaseService);

  /// Check if TOS has been accepted
  bool get isTosAccepted => _storageService.isTosAccepted;

  /// Check if privacy notice has been viewed
  bool get isPrivacyViewed => _storageService.isPrivacyViewed;

  /// Check if onboarding is completed
  bool get isOnboardingCompleted => _storageService.isOnboardingCompleted;

  /// Accept Terms of Service
  Future<void> acceptTos() async {
    await _storageService.setTosAccepted(true);
  }

  /// Mark privacy notice as viewed
  Future<void> markPrivacyViewed() async {
    await _storageService.setPrivacyViewed(true);
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    await _storageService.setOnboardingCompleted(true);
    
    // Also update database
    final db = await _databaseService.database;
    await db.insert('onboarding_data', {
      'completed': 1,
      'completed_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Save onboarding survey data
  Future<void> saveSurveyData({
    List<String>? intentions,
    String? experienceLevel,
    List<String>? peptidesUsed,
  }) async {
    final db = await _databaseService.database;
    
    // Check if record exists
    final existing = await db.query('onboarding_data', limit: 1);
    
    final data = <String, dynamic>{};
    if (intentions != null) {
      data['intentions'] = intentions.join(',');
    }
    if (experienceLevel != null) {
      data['experience_level'] = experienceLevel;
    }
    if (peptidesUsed != null) {
      data['peptides_used'] = peptidesUsed.join(',');
    }
    
    if (existing.isEmpty) {
      await db.insert('onboarding_data', data);
    } else {
      await db.update('onboarding_data', data, where: 'id = ?', whereArgs: [existing.first['id']]);
    }
  }

  /// Get onboarding data
  Future<OnboardingData?> getOnboardingData() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'onboarding_data',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return OnboardingData.fromMap(maps.first);
  }

  /// Reset onboarding (for testing/settings)
  Future<void> resetOnboarding() async {
    await _storageService.setBool(StorageService.keyOnboardingCompleted, false);
    
    final db = await _databaseService.database;
    await db.delete('onboarding_data');
  }
}

/// Onboarding data model
class OnboardingData {
  final int id;
  final List<String> intentions;
  final String? experienceLevel;
  final List<String> peptidesUsed;
  final bool completed;
  final DateTime? completedAt;

  OnboardingData({
    required this.id,
    required this.intentions,
    this.experienceLevel,
    required this.peptidesUsed,
    required this.completed,
    this.completedAt,
  });

  factory OnboardingData.fromMap(Map<String, dynamic> map) {
    return OnboardingData(
      id: map['id'] as int,
      intentions: (map['intentions'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      experienceLevel: map['experience_level'] as String?,
      peptidesUsed: (map['peptides_used'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      completed: (map['completed'] as int?) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
    );
  }
}

