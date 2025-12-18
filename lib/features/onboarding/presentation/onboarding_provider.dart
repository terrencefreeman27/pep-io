import 'package:flutter/foundation.dart';
import '../data/onboarding_repository.dart';

/// Provider for onboarding state management
class OnboardingProvider extends ChangeNotifier {
  final OnboardingRepository _repository;

  bool _tosAccepted = false;
  bool _privacyViewed = false;
  bool _onboardingCompleted = false;
  int _currentStep = 0;
  
  // Survey data
  List<String> _selectedIntentions = [];
  String? _userName;
  double? _userWeight;
  String _weightUnit = 'lbs';
  String? _primaryGoal;
  bool _hasExperience = false;
  List<String> _selectedPeptides = [];
  bool _wantsToLearn = true;

  OnboardingProvider(this._repository) {
    _loadState();
  }

  // Getters
  bool get tosAccepted => _tosAccepted;
  bool get privacyViewed => _privacyViewed;
  bool get onboardingCompleted => _onboardingCompleted;
  int get currentStep => _currentStep;
  List<String> get selectedIntentions => _selectedIntentions;
  String? get userName => _userName;
  double? get userWeight => _userWeight;
  String get weightUnit => _weightUnit;
  String? get primaryGoal => _primaryGoal;
  bool get hasExperience => _hasExperience;
  List<String> get selectedPeptides => _selectedPeptides;
  bool get wantsToLearn => _wantsToLearn;

  /// Load initial state
  Future<void> _loadState() async {
    _tosAccepted = _repository.isTosAccepted;
    _privacyViewed = _repository.isPrivacyViewed;
    _onboardingCompleted = _repository.isOnboardingCompleted;
    notifyListeners();
  }

  /// Accept Terms of Service
  Future<void> acceptTos() async {
    await _repository.acceptTos();
    _tosAccepted = true;
    notifyListeners();
  }

  /// Mark privacy notice as viewed
  Future<void> markPrivacyViewed() async {
    await _repository.markPrivacyViewed();
    _privacyViewed = true;
    notifyListeners();
  }

  /// Set current survey step
  void setCurrentStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  /// Next step
  void nextStep() {
    _currentStep++;
    notifyListeners();
  }

  /// Previous step
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  /// Toggle intention selection
  void toggleIntention(String intention) {
    if (_selectedIntentions.contains(intention)) {
      _selectedIntentions.remove(intention);
    } else {
      _selectedIntentions.add(intention);
    }
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

  /// Set weight unit
  void setWeightUnit(String unit) {
    _weightUnit = unit;
    notifyListeners();
  }

  /// Set primary goal
  void setPrimaryGoal(String? goal) {
    _primaryGoal = goal;
    notifyListeners();
  }

  /// Set experience status
  void setHasExperience(bool hasExp) {
    _hasExperience = hasExp;
    notifyListeners();
  }

  /// Toggle peptide selection
  void togglePeptide(String peptide) {
    if (_selectedPeptides.contains(peptide)) {
      _selectedPeptides.remove(peptide);
    } else {
      _selectedPeptides.add(peptide);
    }
    notifyListeners();
  }

  /// Set wants to learn
  void setWantsToLearn(bool wants) {
    _wantsToLearn = wants;
    notifyListeners();
  }

  /// Save survey data
  Future<void> saveSurveyData() async {
    await _repository.saveSurveyData(
      intentions: _selectedIntentions,
      experienceLevel: _hasExperience ? 'experienced' : 'beginner',
      peptidesUsed: _selectedPeptides,
    );
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    await saveSurveyData();
    await _repository.completeOnboarding();
    _onboardingCompleted = true;
    notifyListeners();
  }

  /// Skip onboarding (complete without saving survey data)
  Future<void> skipOnboarding() async {
    await _repository.completeOnboarding();
    _onboardingCompleted = true;
    notifyListeners();
  }

  /// Reset onboarding
  Future<void> resetOnboarding() async {
    await _repository.resetOnboarding();
    _tosAccepted = false;
    _privacyViewed = false;
    _onboardingCompleted = false;
    _currentStep = 0;
    _selectedIntentions = [];
    _userName = null;
    _userWeight = null;
    _weightUnit = 'lbs';
    _primaryGoal = null;
    _hasExperience = false;
    _selectedPeptides = [];
    _wantsToLearn = true;
    notifyListeners();
  }
}

/// Available intentions for onboarding
class OnboardingIntentions {
  static const String trackPeptides = 'Track peptides';
  static const String calculateDoses = 'Calculate doses';
  static const String setGoals = 'Set health goals';
  static const String visualizeProgress = 'Visualize progress';
  static const String learnPeptides = 'Learn about peptides';

  static const List<String> all = [
    trackPeptides,
    calculateDoses,
    setGoals,
    visualizeProgress,
    learnPeptides,
  ];
}

/// Primary goal options
class PrimaryGoals {
  static const String muscleGain = 'Muscle Gain';
  static const String fatLoss = 'Fat Loss';
  static const String wellness = 'Wellness & Longevity';
  static const String cognitive = 'Cognitive Enhancement';
  static const String beauty = 'Skin & Beauty';
  static const String performance = 'Athletic Performance';
  static const String recovery = 'Recovery & Healing';
  static const String custom = 'Custom';

  static const List<String> all = [
    muscleGain,
    fatLoss,
    wellness,
    cognitive,
    beauty,
    performance,
    recovery,
    custom,
  ];
}

