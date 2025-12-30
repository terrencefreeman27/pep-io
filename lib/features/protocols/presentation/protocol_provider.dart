import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/models/protocol.dart';
import '../../../core/models/dose.dart';
import '../../../core/services/calendar_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/widget_service.dart';
import '../data/protocol_repository.dart';

/// Provider for protocol state management
class ProtocolProvider extends ChangeNotifier {
  final ProtocolRepository _repository;
  final NotificationService _notificationService;
  final CalendarService _calendarService;
  final WidgetService _widgetService = WidgetService();

  List<Protocol> _protocols = [];
  List<Dose> _todaysDoses = [];
  List<Dose> _allDoses = [];
  bool _isLoading = false;
  String? _error;
  int _activeCount = 0;
  double _adherenceRate = 0.0;
  int _currentStreak = 0;
  
  // Store calendar event IDs for each protocol
  final Map<String, List<String>> _protocolCalendarEvents = {};

  ProtocolProvider(this._repository, this._notificationService, this._calendarService) {
    _widgetService.initialize();
  }

  // Getters
  List<Protocol> get protocols => _protocols;
  List<Protocol> get activeProtocols => _protocols.where((p) => p.active).toList();
  List<Dose> get todaysDoses => _todaysDoses;
  List<Dose> get allDoses => _allDoses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get activeCount => _activeCount;
  double get adherenceRate => _adherenceRate;
  int get currentStreak => _currentStreak;

  /// Load all protocols
  Future<void> loadProtocols() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _protocols = await _repository.getAllProtocols();
      _activeCount = _protocols.where((p) => p.active).length;
      await _loadTodaysDoses();
      await _loadAllDoses();
      await _calculateStats();
      await _updateWidget(); // Update iOS widget with latest data
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load today's doses
  Future<void> _loadTodaysDoses() async {
    _todaysDoses = await _repository.getTodaysDoses();
  }

  /// Load all doses
  Future<void> _loadAllDoses() async {
    _allDoses = await _repository.getAllDoses();
  }

  /// Get doses for a specific protocol
  List<Dose> getDosesForProtocol(String protocolId) {
    return _allDoses.where((d) => d.protocolId == protocolId).toList();
  }

  /// Log dose status (completed/skipped)
  Future<void> logDose(String doseId, DoseStatus status) async {
    try {
      if (status == DoseStatus.taken) {
        await markDoseAsTaken(doseId);
      } else if (status == DoseStatus.skipped) {
        await markDoseAsSkipped(doseId);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Calculate adherence and streak
  Future<void> _calculateStats() async {
    _adherenceRate = await _repository.calculateOverallAdherence();
    _currentStreak = await _repository.calculateCurrentStreak();
  }

  /// Update iOS home screen widget with current data for ALL protocols
  Future<void> _updateWidget() async {
    if (!Platform.isIOS) return;
    
    if (_protocols.isEmpty) {
      await _widgetService.clearWidget();
      return;
    }

    // Build protocol data for each protocol
    final List<Map<String, dynamic>> protocolDataList = [];
    
    for (final protocol in _protocols.where((p) => p.active)) {
      // Get doses for this specific protocol
      final protocolDoses = _todaysDoses.where(
        (d) => d.protocolId == protocol.id,
      ).toList();
      
      final completedToday = protocolDoses.where((d) => d.status == DoseStatus.taken).length;
      
      // Get next scheduled dose time for this protocol
      String nextDoseTime = '--';
      final scheduledDoses = protocolDoses.where(
        (d) => d.status == DoseStatus.scheduled,
      ).toList();
      
      if (scheduledDoses.isNotEmpty) {
        scheduledDoses.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        nextDoseTime = scheduledDoses.first.scheduledTime;
      }

      protocolDataList.add({
        'id': protocol.id,
        'name': protocol.peptideName,
        'next_dose_time': nextDoseTime,
        'doses_today': completedToday,
        'total_doses_today': protocolDoses.length,
        'category': 'Regenerative', // Could fetch from peptide if needed
      });
    }

    await _widgetService.updateWidgetWithProtocols(
      protocolData: protocolDataList,
      overallStreak: _currentStreak,
      overallAdherence: _adherenceRate.round(),
    );
  }

  /// Get protocol by ID
  Protocol? getProtocolById(String id) {
    try {
      return _protocols.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add a new protocol
  Future<Protocol> addProtocol(Protocol protocol) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newProtocol = await _repository.insertProtocol(protocol);
      
      // Generate doses for the next 30 days
      final doses = await _repository.generateDosesForProtocol(
        newProtocol,
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 30)),
      );
      
      // Insert doses and collect inserted doses
      final insertedDoses = <Dose>[];
      for (final dose in doses) {
        final insertedDose = await _repository.insertDose(dose);
        insertedDoses.add(insertedDose);
        
        // Schedule notifications
        await _notificationService.scheduleDoseReminder(
          dose: insertedDose,
          protocol: newProtocol,
        );
      }
      
      // Sync to Apple Calendar if enabled
      if (newProtocol.syncToCalendar && newProtocol.calendarId != null) {
        await _syncProtocolToCalendar(newProtocol, insertedDoses);
      }
      
      // Schedule protocol ending notification if has end date
      if (newProtocol.endDate != null) {
        await _notificationService.scheduleProtocolEndingSoon(protocol: newProtocol);
      }
      
      await loadProtocols();
      return newProtocol;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Sync protocol doses to Apple Calendar
  Future<void> _syncProtocolToCalendar(Protocol protocol, List<Dose> doses) async {
    try {
      if (protocol.calendarId == null) return;
      
      final eventIds = await _calendarService.syncProtocolToCalendar(
        protocol: protocol,
        doses: doses,
        calendarId: protocol.calendarId!,
      );
      
      if (eventIds.isNotEmpty) {
        _protocolCalendarEvents[protocol.id] = eventIds;
        debugPrint('Synced ${eventIds.length} events to calendar for protocol ${protocol.id}');
      }
    } catch (e) {
      debugPrint('Error syncing to calendar: $e');
      // Don't fail the whole operation if calendar sync fails
    }
  }
  
  /// Remove calendar events for a protocol
  Future<void> _removeCalendarEvents(Protocol protocol) async {
    try {
      if (protocol.calendarId == null) return;
      
      final eventIds = _protocolCalendarEvents[protocol.id];
      if (eventIds != null && eventIds.isNotEmpty) {
        await _calendarService.deleteProtocolEvents(
          calendarId: protocol.calendarId!,
          eventIds: eventIds,
        );
        _protocolCalendarEvents.remove(protocol.id);
        debugPrint('Removed calendar events for protocol ${protocol.id}');
      }
    } catch (e) {
      debugPrint('Error removing calendar events: $e');
    }
  }

  /// Update a protocol
  Future<void> updateProtocol(Protocol protocol) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get the old protocol to check for calendar changes
      final oldProtocol = await _repository.getProtocolById(protocol.id);
      
      await _repository.updateProtocol(protocol);
      
      // Cancel existing notifications and reschedule
      await _notificationService.cancelProtocolNotifications(protocol.id);
      
      // Regenerate doses if schedule changed
      // For simplicity, we'll regenerate all future doses
      final doses = await _repository.generateDosesForProtocol(
        protocol,
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 30)),
      );
      
      final insertedDoses = <Dose>[];
      for (final dose in doses) {
        insertedDoses.add(dose);
        await _notificationService.scheduleDoseReminder(
          dose: dose,
          protocol: protocol,
        );
      }
      
      // Handle calendar sync changes
      if (oldProtocol != null && oldProtocol.syncToCalendar && !protocol.syncToCalendar) {
        // Calendar sync was disabled, remove events
        await _removeCalendarEvents(oldProtocol);
      } else if (protocol.syncToCalendar && protocol.calendarId != null) {
        // Calendar sync is enabled, update events
        if (oldProtocol != null) {
          await _removeCalendarEvents(oldProtocol);
        }
        await _syncProtocolToCalendar(protocol, insertedDoses);
      }
      
      await loadProtocols();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a protocol
  Future<void> deleteProtocol(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get protocol to check for calendar sync
      final protocol = await _repository.getProtocolById(id);
      
      // Cancel notifications
      await _notificationService.cancelProtocolNotifications(id);
      
      // Get all doses and cancel their notifications
      final doses = await _repository.getDosesForProtocol(id);
      for (final dose in doses) {
        await _notificationService.cancelDoseNotifications(dose.id);
      }
      
      // Remove calendar events if protocol had calendar sync
      if (protocol != null && protocol.syncToCalendar) {
        await _removeCalendarEvents(protocol);
      }
      
      await _repository.deleteProtocol(id);
      await loadProtocols();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle protocol active status
  Future<void> toggleProtocolActive(String id, bool active) async {
    try {
      await _repository.toggleProtocolActive(id, active);
      
      if (!active) {
        // Cancel notifications when deactivating
        await _notificationService.cancelProtocolNotifications(id);
        final doses = await _repository.getDosesForProtocol(id);
        for (final dose in doses) {
          await _notificationService.cancelDoseNotifications(dose.id);
        }
      }
      
      await loadProtocols();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark a dose as taken
  Future<void> markDoseAsTaken(String doseId, {String? actualTime, String? notes}) async {
    try {
      await _repository.markDoseAsTaken(doseId, actualTime: actualTime, notes: notes);
      
      // Cancel missed dose notification
      await _notificationService.cancelDoseNotifications(doseId);
      
      await _loadTodaysDoses();
      await _calculateStats();
      await _updateWidget(); // Update iOS widget
      
      // Check for streak milestones
      if (_currentStreak > 0 && [7, 14, 30, 60, 90, 180, 365].contains(_currentStreak)) {
        await _notificationService.showStreakMilestone(streakDays: _currentStreak);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark a dose as missed
  Future<void> markDoseAsMissed(String doseId) async {
    try {
      await _repository.markDoseAsMissed(doseId);
      await _notificationService.cancelDoseNotifications(doseId);
      await _loadTodaysDoses();
      await _calculateStats();
      await _updateWidget(); // Update iOS widget
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark a dose as skipped
  Future<void> markDoseAsSkipped(String doseId) async {
    try {
      await _repository.markDoseAsSkipped(doseId);
      await _notificationService.cancelDoseNotifications(doseId);
      await _loadTodaysDoses();
      await _calculateStats();
      await _updateWidget(); // Update iOS widget
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get doses for a specific date
  Future<List<Dose>> getDosesForDate(DateTime date) async {
    return _repository.getDosesInRange(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
  }

  /// Get doses for a date range
  Future<List<Dose>> getDosesInRange(DateTime start, DateTime end) async {
    return _repository.getDosesInRange(start, end);
  }

  /// Get adherence rate for a specific protocol
  Future<double> getProtocolAdherence(String protocolId) async {
    return _repository.calculateAdherenceRate(protocolId);
  }

  /// Refresh today's doses
  Future<void> refreshTodaysDoses() async {
    await _loadTodaysDoses();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

