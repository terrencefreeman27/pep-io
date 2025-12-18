import 'dart:convert';

/// Protocol model for peptide protocol definitions
class Protocol {
  final String id;
  final String peptideId;
  final String peptideName;
  final double dosageAmount;
  final String dosageUnit; // 'mcg' or 'mg'
  final String frequency;
  final List<String>? daysOfWeek;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool syncToCalendar;
  final String? calendarId;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Protocol({
    required this.id,
    required this.peptideId,
    required this.peptideName,
    required this.dosageAmount,
    required this.dosageUnit,
    required this.frequency,
    this.daysOfWeek,
    required this.times,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.syncToCalendar,
    this.calendarId,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Protocol.fromMap(Map<String, dynamic> map) {
    return Protocol(
      id: map['id'] as String,
      peptideId: map['peptide_id'] as String,
      peptideName: map['peptide_name'] as String,
      dosageAmount: (map['dosage_amount'] as num).toDouble(),
      dosageUnit: map['dosage_unit'] as String,
      frequency: map['frequency'] as String,
      daysOfWeek: map['days_of_week'] != null
          ? List<String>.from(jsonDecode(map['days_of_week'] as String))
          : null,
      times: List<String>.from(jsonDecode(map['times'] as String)),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      notes: map['notes'] as String?,
      syncToCalendar: (map['sync_to_calendar'] as int) == 1,
      calendarId: map['calendar_id'] as String?,
      active: (map['active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peptide_id': peptideId,
      'peptide_name': peptideName,
      'dosage_amount': dosageAmount,
      'dosage_unit': dosageUnit,
      'frequency': frequency,
      'days_of_week': daysOfWeek != null ? jsonEncode(daysOfWeek) : null,
      'times': jsonEncode(times),
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'notes': notes,
      'sync_to_calendar': syncToCalendar ? 1 : 0,
      'calendar_id': calendarId,
      'active': active ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Protocol copyWith({
    String? id,
    String? peptideId,
    String? peptideName,
    double? dosageAmount,
    String? dosageUnit,
    String? frequency,
    List<String>? daysOfWeek,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    bool? syncToCalendar,
    String? calendarId,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Protocol(
      id: id ?? this.id,
      peptideId: peptideId ?? this.peptideId,
      peptideName: peptideName ?? this.peptideName,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      syncToCalendar: syncToCalendar ?? this.syncToCalendar,
      calendarId: calendarId ?? this.calendarId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted dosage string
  String get formattedDosage => '$dosageAmount $dosageUnit';

  /// Get formatted frequency string
  String get formattedFrequency {
    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      return '$frequency (${daysOfWeek!.join(', ')})';
    }
    return frequency;
  }

  /// Get formatted time(s) string
  String get formattedTimes => times.join(', ');

  /// Check if protocol is ongoing (no end date)
  bool get isOngoing => endDate == null;

  /// Get remaining days if end date is set
  int? get remainingDays {
    if (endDate == null) return null;
    return endDate!.difference(DateTime.now()).inDays;
  }
}

/// Frequency options for protocols
class ProtocolFrequency {
  static const String daily = 'Daily';
  static const String everyOtherDay = 'Every Other Day';
  static const String twiceWeekly = 'Twice Weekly';
  static const String weekly = 'Weekly';
  static const String biWeekly = 'Bi-Weekly';
  static const String monthly = 'Monthly';
  static const String custom = 'Custom';

  static const List<String> all = [
    daily,
    everyOtherDay,
    twiceWeekly,
    weekly,
    biWeekly,
    monthly,
    custom,
  ];
}

/// Days of the week
class DaysOfWeek {
  static const String sunday = 'Sunday';
  static const String monday = 'Monday';
  static const String tuesday = 'Tuesday';
  static const String wednesday = 'Wednesday';
  static const String thursday = 'Thursday';
  static const String friday = 'Friday';
  static const String saturday = 'Saturday';

  static const List<String> all = [
    sunday,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
  ];

  static const List<String> weekdays = [
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
  ];
}

