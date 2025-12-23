import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/protocol.dart';
import '../models/dose.dart';

/// Service for Apple Calendar integration
class CalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  
  List<Calendar> _calendars = [];
  bool _hasPermission = false;

  /// Get all available calendars
  List<Calendar> get calendars => _calendars;
  
  /// Check if calendar permission is granted
  bool get hasPermission => _hasPermission;

  /// Request calendar permissions
  Future<bool> requestPermissions() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && (permissionsGranted.data ?? false)) {
        _hasPermission = true;
        return true;
      }

      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      _hasPermission = permissionsGranted.isSuccess && (permissionsGranted.data ?? false);
      return _hasPermission;
    } catch (e) {
      debugPrint('Error requesting calendar permissions: $e');
      _hasPermission = false;
      return false;
    }
  }

  /// Retrieve all calendars from the device
  Future<List<Calendar>> retrieveCalendars() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        return [];
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        // Filter to only writable calendars (excluding birthdays, holidays, etc.)
        _calendars = calendarsResult.data!
            .where((cal) => !(cal.isReadOnly ?? true) && cal.id != null)
            .toList();
        return _calendars;
      }
      return [];
    } catch (e) {
      debugPrint('Error retrieving calendars: $e');
      return [];
    }
  }

  /// Get a calendar by ID
  Calendar? getCalendarById(String calendarId) {
    try {
      return _calendars.firstWhere((cal) => cal.id == calendarId);
    } catch (e) {
      return null;
    }
  }

  /// Get the default calendar for events
  Future<Calendar?> getDefaultCalendar() async {
    if (_calendars.isEmpty) {
      await retrieveCalendars();
    }
    
    // Try to find the default calendar or the first available one
    try {
      return _calendars.firstWhere(
        (cal) => cal.isDefault ?? false,
        orElse: () => _calendars.isNotEmpty ? _calendars.first : throw Exception('No calendars available'),
      );
    } catch (e) {
      return _calendars.isNotEmpty ? _calendars.first : null;
    }
  }

  /// Create calendar events for a protocol's doses
  Future<List<String>> syncProtocolToCalendar({
    required Protocol protocol,
    required List<Dose> doses,
    required String calendarId,
  }) async {
    final createdEventIds = <String>[];
    
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('Calendar permission not granted');
      }

      for (final dose in doses) {
        final eventId = await _createDoseEvent(
          calendarId: calendarId,
          protocol: protocol,
          dose: dose,
        );
        if (eventId != null) {
          createdEventIds.add(eventId);
        }
      }
    } catch (e) {
      debugPrint('Error syncing protocol to calendar: $e');
    }

    return createdEventIds;
  }

  /// Create a single calendar event for a dose
  Future<String?> _createDoseEvent({
    required String calendarId,
    required Protocol protocol,
    required Dose dose,
  }) async {
    try {
      final scheduledDateTime = dose.scheduledDateTime;
      
      // Create TZDateTime from the scheduled date/time
      final startTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
      final endTime = tz.TZDateTime.from(
        scheduledDateTime.add(const Duration(minutes: 15)),
        tz.local,
      );
      
      // Create event with 15 minute duration
      final event = Event(
        calendarId,
        title: '💉 ${protocol.peptideName} - ${protocol.formattedDosage}',
        description: _buildEventDescription(protocol, dose),
        start: startTime,
        end: endTime,
        reminders: [
          Reminder(minutes: 15), // 15 minutes before
          Reminder(minutes: 5),  // 5 minutes before
        ],
      );

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      if (result?.isSuccess ?? false) {
        return result!.data;
      }
    } catch (e) {
      debugPrint('Error creating dose event: $e');
    }
    return null;
  }

  /// Build event description
  String _buildEventDescription(Protocol protocol, Dose dose) {
    final buffer = StringBuffer();
    buffer.writeln('Protocol: ${protocol.peptideName}');
    buffer.writeln('Dosage: ${protocol.formattedDosage}');
    buffer.writeln('Frequency: ${protocol.formattedFrequency}');
    buffer.writeln('Scheduled Time: ${dose.scheduledTime}');
    if (protocol.notes != null && protocol.notes!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Notes: ${protocol.notes}');
    }
    buffer.writeln('');
    buffer.writeln('Tracked in pep.io');
    return buffer.toString();
  }

  /// Delete a calendar event by ID
  Future<bool> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    try {
      final result = await _deviceCalendarPlugin.deleteEvent(calendarId, eventId);
      return result.isSuccess;
    } catch (e) {
      debugPrint('Error deleting calendar event: $e');
      return false;
    }
  }

  /// Delete all calendar events for a protocol
  Future<void> deleteProtocolEvents({
    required String calendarId,
    required List<String> eventIds,
  }) async {
    for (final eventId in eventIds) {
      await deleteEvent(calendarId: calendarId, eventId: eventId);
    }
  }

  /// Update existing calendar events for a protocol
  Future<List<String>> updateProtocolEvents({
    required Protocol protocol,
    required List<Dose> doses,
    required String calendarId,
    required List<String> existingEventIds,
  }) async {
    // Delete existing events
    await deleteProtocolEvents(
      calendarId: calendarId,
      eventIds: existingEventIds,
    );

    // Create new events
    return await syncProtocolToCalendar(
      protocol: protocol,
      doses: doses,
      calendarId: calendarId,
    );
  }

  /// Get events from a calendar within a date range
  Future<List<Event>> getEventsInRange({
    required String calendarId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final result = await _deviceCalendarPlugin.retrieveEvents(
        calendarId,
        RetrieveEventsParams(
          startDate: start,
          endDate: end,
        ),
      );
      
      if (result.isSuccess && result.data != null) {
        return result.data!;
      }
    } catch (e) {
      debugPrint('Error retrieving events: $e');
    }
    return [];
  }

  /// Check if a specific calendar exists
  Future<bool> calendarExists(String calendarId) async {
    if (_calendars.isEmpty) {
      await retrieveCalendars();
    }
    return _calendars.any((cal) => cal.id == calendarId);
  }
}
