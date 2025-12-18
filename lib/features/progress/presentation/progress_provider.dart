import 'package:flutter/foundation.dart';
import '../../../core/models/dose.dart';
import '../../../core/models/protocol.dart';
import '../../protocols/data/protocol_repository.dart';

/// Provider for progress tracking state management
class ProgressProvider extends ChangeNotifier {
  final ProtocolRepository _repository;

  List<Dose> _doses = [];
  List<Protocol> _protocols = [];
  DateRange _dateRange = DateRange.last30Days;
  String? _selectedProtocolId;
  bool _isLoading = false;
  String? _error;

  // Calculated metrics
  double _overallAdherence = 0.0;
  int _totalDosesTaken = 0;
  int _totalDosesMissed = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  Map<String, double> _protocolAdherence = {};
  Map<DateTime, int> _dailyDoseCounts = {};
  Map<int, int> _hourlyDistribution = {};

  ProgressProvider(this._repository);

  // Getters
  List<Dose> get doses => _doses;
  List<Protocol> get protocols => _protocols;
  DateRange get dateRange => _dateRange;
  String? get selectedProtocolId => _selectedProtocolId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get overallAdherence => _overallAdherence;
  int get totalDosesTaken => _totalDosesTaken;
  int get totalDosesMissed => _totalDosesMissed;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  Map<String, double> get protocolAdherence => _protocolAdherence;
  Map<DateTime, int> get dailyDoseCounts => _dailyDoseCounts;
  Map<int, int> get hourlyDistribution => _hourlyDistribution;

  /// Load progress data
  Future<void> loadProgress() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _protocols = await _repository.getActiveProtocols();
      
      final dates = _dateRange.getDateRange();
      _doses = await _repository.getDosesInRange(dates.start, dates.end);
      
      // Apply protocol filter if selected
      if (_selectedProtocolId != null) {
        _doses = _doses.where((d) => d.protocolId == _selectedProtocolId).toList();
      }
      
      await _calculateMetrics();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate all metrics
  Future<void> _calculateMetrics() async {
    // Basic counts
    _totalDosesTaken = _doses.where((d) => d.status == DoseStatus.taken).length;
    _totalDosesMissed = _doses.where((d) => d.status == DoseStatus.missed).length;
    final totalScheduled = _doses.length;
    
    // Overall adherence
    if (totalScheduled > 0) {
      _overallAdherence = (_totalDosesTaken / totalScheduled) * 100;
    } else {
      _overallAdherence = 0.0;
    }
    
    // Per-protocol adherence
    _protocolAdherence = {};
    for (final protocol in _protocols) {
      final protocolDoses = _doses.where((d) => d.protocolId == protocol.id).toList();
      if (protocolDoses.isNotEmpty) {
        final taken = protocolDoses.where((d) => d.status == DoseStatus.taken).length;
        _protocolAdherence[protocol.id] = (taken / protocolDoses.length) * 100;
      }
    }
    
    // Daily dose counts (for heatmap)
    _dailyDoseCounts = {};
    for (final dose in _doses.where((d) => d.status == DoseStatus.taken)) {
      final date = DateTime(
        dose.scheduledDate.year,
        dose.scheduledDate.month,
        dose.scheduledDate.day,
      );
      _dailyDoseCounts[date] = (_dailyDoseCounts[date] ?? 0) + 1;
    }
    
    // Hourly distribution (for time-of-day chart)
    _hourlyDistribution = {};
    for (final dose in _doses.where((d) => d.status == DoseStatus.taken && d.actualTime != null)) {
      final hour = _parseHour(dose.actualTime!);
      _hourlyDistribution[hour] = (_hourlyDistribution[hour] ?? 0) + 1;
    }
    
    // Streaks
    _currentStreak = await _repository.calculateCurrentStreak();
    _longestStreak = _calculateLongestStreak();
  }

  /// Parse hour from time string
  int _parseHour(String time) {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    if (time.toLowerCase().contains('pm') && hour != 12) {
      hour += 12;
    } else if (time.toLowerCase().contains('am') && hour == 12) {
      hour = 0;
    }
    return hour;
  }

  /// Calculate longest streak from history
  int _calculateLongestStreak() {
    if (_doses.isEmpty) return 0;
    
    // Group doses by date
    final dosesByDate = <DateTime, List<Dose>>{};
    for (final dose in _doses) {
      final date = DateTime(
        dose.scheduledDate.year,
        dose.scheduledDate.month,
        dose.scheduledDate.day,
      );
      dosesByDate.putIfAbsent(date, () => []);
      dosesByDate[date]!.add(dose);
    }
    
    // Sort dates
    final dates = dosesByDate.keys.toList()..sort();
    
    int longestStreak = 0;
    int currentStreak = 0;
    
    for (final date in dates) {
      final dayDoses = dosesByDate[date]!;
      final allTaken = dayDoses.every((d) => 
        d.status == DoseStatus.taken || d.status == DoseStatus.skipped
      );
      
      if (allTaken && dayDoses.isNotEmpty) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }
    
    return longestStreak;
  }

  /// Set date range
  Future<void> setDateRange(DateRange range) async {
    _dateRange = range;
    await loadProgress();
  }

  /// Set selected protocol filter
  Future<void> setSelectedProtocol(String? protocolId) async {
    _selectedProtocolId = protocolId;
    await loadProgress();
  }

  /// Clear filters
  Future<void> clearFilters() async {
    _selectedProtocolId = null;
    _dateRange = DateRange.last30Days;
    await loadProgress();
  }

  /// Get weekly adherence data for chart
  List<WeeklyAdherence> getWeeklyAdherence() {
    final weekData = <WeeklyAdherence>[];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayDoses = _doses.where((d) =>
        d.scheduledDate.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
        d.scheduledDate.isBefore(dayEnd)
      ).toList();
      
      double adherence = 0.0;
      if (dayDoses.isNotEmpty) {
        final taken = dayDoses.where((d) => d.status == DoseStatus.taken).length;
        adherence = (taken / dayDoses.length) * 100;
      }
      
      weekData.add(WeeklyAdherence(
        date: date,
        adherence: adherence,
        dosesTaken: dayDoses.where((d) => d.status == DoseStatus.taken).length,
        totalDoses: dayDoses.length,
      ));
    }
    
    return weekData;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get insights based on progress data
  List<Map<String, dynamic>> getInsights() {
    final insights = <Map<String, dynamic>>[];
    
    // Streak milestone
    if (_currentStreak >= 7) {
      insights.add({
        'type': 'success',
        'title': '${_currentStreak} Day Streak!',
        'description': 'Great job maintaining consistency with your protocols.',
      });
    }
    
    // High adherence
    if (_overallAdherence >= 90) {
      insights.add({
        'type': 'success',
        'title': 'Excellent Adherence',
        'description': 'You\'re maintaining ${_overallAdherence.toStringAsFixed(0)}% adherence. Keep it up!',
      });
    } else if (_overallAdherence < 70 && _overallAdherence > 0) {
      insights.add({
        'type': 'warning',
        'title': 'Room for Improvement',
        'description': 'Your adherence is at ${_overallAdherence.toStringAsFixed(0)}%. Try setting reminders to stay on track.',
      });
    }
    
    // Missed doses
    if (_totalDosesMissed > 0) {
      insights.add({
        'type': 'info',
        'title': 'Missed Doses',
        'description': 'You\'ve missed $_totalDosesMissed doses in this period. Consider adjusting your schedule.',
      });
    }
    
    // Best time
    if (_hourlyDistribution.isNotEmpty) {
      final bestHour = _hourlyDistribution.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final period = bestHour < 12 ? 'AM' : 'PM';
      final displayHour = bestHour == 0 ? 12 : (bestHour > 12 ? bestHour - 12 : bestHour);
      insights.add({
        'type': 'info',
        'title': 'Optimal Dosing Time',
        'description': 'You\'re most consistent when dosing around $displayHour:00 $period.',
      });
    }
    
    return insights;
  }
}

/// Date range options
enum DateRange {
  last7Days,
  last30Days,
  last90Days,
  allTime,
  custom;

  String get displayName {
    switch (this) {
      case DateRange.last7Days:
        return 'Last 7 Days';
      case DateRange.last30Days:
        return 'Last 30 Days';
      case DateRange.last90Days:
        return 'Last 90 Days';
      case DateRange.allTime:
        return 'All Time';
      case DateRange.custom:
        return 'Custom Range';
    }
  }

  ({DateTime start, DateTime end}) getDateRange() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    switch (this) {
      case DateRange.last7Days:
        return (start: end.subtract(const Duration(days: 7)), end: end);
      case DateRange.last30Days:
        return (start: end.subtract(const Duration(days: 30)), end: end);
      case DateRange.last90Days:
        return (start: end.subtract(const Duration(days: 90)), end: end);
      case DateRange.allTime:
        return (start: DateTime(2020, 1, 1), end: end);
      case DateRange.custom:
        return (start: end.subtract(const Duration(days: 30)), end: end);
    }
  }
}

/// Weekly adherence data
class WeeklyAdherence {
  final DateTime date;
  final double adherence;
  final int dosesTaken;
  final int totalDoses;

  WeeklyAdherence({
    required this.date,
    required this.adherence,
    required this.dosesTaken,
    required this.totalDoses,
  });
}

