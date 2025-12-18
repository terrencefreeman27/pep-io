/// Dose status enum
enum DoseStatus {
  scheduled,
  taken,
  missed,
  skipped;

  String get displayName {
    switch (this) {
      case DoseStatus.scheduled:
        return 'Scheduled';
      case DoseStatus.taken:
        return 'Taken';
      case DoseStatus.missed:
        return 'Missed';
      case DoseStatus.skipped:
        return 'Skipped';
    }
  }

  static DoseStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'scheduled':
        return DoseStatus.scheduled;
      case 'taken':
        return DoseStatus.taken;
      case 'missed':
        return DoseStatus.missed;
      case 'skipped':
        return DoseStatus.skipped;
      default:
        return DoseStatus.scheduled;
    }
  }
}

/// Dose model for individual dose instances
class Dose {
  final String id;
  final String protocolId;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String? actualTime;
  final DoseStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Dose({
    required this.id,
    required this.protocolId,
    required this.scheduledDate,
    required this.scheduledTime,
    this.actualTime,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dose.fromMap(Map<String, dynamic> map) {
    return Dose(
      id: map['id'] as String,
      protocolId: map['protocol_id'] as String,
      scheduledDate: DateTime.parse(map['scheduled_date'] as String),
      scheduledTime: map['scheduled_time'] as String,
      actualTime: map['actual_time'] as String?,
      status: DoseStatus.fromString(map['status'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'protocol_id': protocolId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime,
      'actual_time': actualTime,
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Dose copyWith({
    String? id,
    String? protocolId,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? actualTime,
    DoseStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dose(
      id: id ?? this.id,
      protocolId: protocolId ?? this.protocolId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Parse scheduled time to DateTime
  DateTime get scheduledDateTime {
    final parts = scheduledTime.split(':');
    int hour = int.parse(parts[0]);
    final minutePart = parts[1].split(' ');
    int minute = int.parse(minutePart[0]);
    
    // Handle AM/PM if present
    if (minutePart.length > 1) {
      final period = minutePart[1].toUpperCase();
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
    }
    
    return DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      minute,
    );
  }

  /// Check if dose is overdue
  bool get isOverdue {
    if (status != DoseStatus.scheduled) return false;
    return DateTime.now().isAfter(scheduledDateTime);
  }

  /// Check if dose is due soon (within 30 minutes)
  bool get isDueSoon {
    if (status != DoseStatus.scheduled) return false;
    final now = DateTime.now();
    final diff = scheduledDateTime.difference(now);
    return diff.inMinutes >= 0 && diff.inMinutes <= 30;
  }

  /// Check if dose is upcoming (today, in the future)
  bool get isUpcoming {
    if (status != DoseStatus.scheduled) return false;
    return scheduledDateTime.isAfter(DateTime.now());
  }
}

