import 'package:uuid/uuid.dart';
import '../../../core/models/protocol.dart';
import '../../../core/models/dose.dart';
import '../../../core/services/database_service.dart';

/// Repository for protocol data operations
class ProtocolRepository {
  final DatabaseService _databaseService;
  final _uuid = const Uuid();

  ProtocolRepository(this._databaseService);

  /// Get all protocols
  Future<List<Protocol>> getAllProtocols() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'protocols',
      orderBy: 'start_date DESC',
    );
    return maps.map((map) => Protocol.fromMap(map)).toList();
  }

  /// Get active protocols only
  Future<List<Protocol>> getActiveProtocols() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'protocols',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'start_date DESC',
    );
    return maps.map((map) => Protocol.fromMap(map)).toList();
  }

  /// Get protocol by ID
  Future<Protocol?> getProtocolById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'protocols',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Protocol.fromMap(maps.first);
  }

  /// Get protocols by peptide ID
  Future<List<Protocol>> getProtocolsByPeptideId(String peptideId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'protocols',
      where: 'peptide_id = ?',
      whereArgs: [peptideId],
      orderBy: 'start_date DESC',
    );
    return maps.map((map) => Protocol.fromMap(map)).toList();
  }

  /// Insert a new protocol
  Future<Protocol> insertProtocol(Protocol protocol) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final newProtocol = protocol.copyWith(
      id: protocol.id.isEmpty ? _uuid.v4() : protocol.id,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('protocols', newProtocol.toMap());
    return newProtocol;
  }

  /// Update an existing protocol
  Future<void> updateProtocol(Protocol protocol) async {
    final db = await _databaseService.database;
    final updatedProtocol = protocol.copyWith(updatedAt: DateTime.now());
    await db.update(
      'protocols',
      updatedProtocol.toMap(),
      where: 'id = ?',
      whereArgs: [protocol.id],
    );
  }

  /// Delete a protocol
  Future<void> deleteProtocol(String id) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      // Delete associated doses first
      await txn.delete(
        'doses',
        where: 'protocol_id = ?',
        whereArgs: [id],
      );
      // Delete protocol
      await txn.delete(
        'protocols',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Toggle protocol active status
  Future<void> toggleProtocolActive(String id, bool active) async {
    final db = await _databaseService.database;
    await db.update(
      'protocols',
      {
        'active': active ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get count of active protocols
  Future<int> getActiveProtocolCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM protocols WHERE active = 1',
    );
    return result.first['count'] as int;
  }

  // Dose operations

  /// Get all doses
  Future<List<Dose>> getAllDoses() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'doses',
      orderBy: 'scheduled_date DESC, scheduled_time DESC',
    );
    return maps.map((map) => Dose.fromMap(map)).toList();
  }

  /// Get all doses for a protocol
  Future<List<Dose>> getDosesForProtocol(String protocolId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'doses',
      where: 'protocol_id = ?',
      whereArgs: [protocolId],
      orderBy: 'scheduled_date DESC, scheduled_time DESC',
    );
    return maps.map((map) => Dose.fromMap(map)).toList();
  }

  /// Get doses in date range
  Future<List<Dose>> getDosesInRange(DateTime start, DateTime end, {DoseStatus? status}) async {
    final db = await _databaseService.database;
    String whereClause = 'scheduled_date >= ? AND scheduled_date <= ?';
    List<dynamic> whereArgs = [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ];

    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status.name);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'doses',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'scheduled_date ASC, scheduled_time ASC',
    );
    return maps.map((map) => Dose.fromMap(map)).toList();
  }

  /// Get doses for today
  Future<List<Dose>> getTodaysDoses() async {
    final today = DateTime.now();
    return getDosesInRange(
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day, 23, 59, 59),
    );
  }

  /// Get dose by ID
  Future<Dose?> getDoseById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'doses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Dose.fromMap(maps.first);
  }

  /// Insert a new dose
  Future<Dose> insertDose(Dose dose) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final newDose = dose.copyWith(
      id: dose.id.isEmpty ? _uuid.v4() : dose.id,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('doses', newDose.toMap());
    return newDose;
  }

  /// Update a dose
  Future<void> updateDose(Dose dose) async {
    final db = await _databaseService.database;
    final updatedDose = dose.copyWith(updatedAt: DateTime.now());
    await db.update(
      'doses',
      updatedDose.toMap(),
      where: 'id = ?',
      whereArgs: [dose.id],
    );
  }

  /// Mark dose as taken
  Future<void> markDoseAsTaken(String doseId, {String? actualTime, String? notes}) async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    await db.update(
      'doses',
      {
        'status': DoseStatus.taken.name,
        'actual_time': actualTime ?? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        if (notes != null) 'notes': notes,
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [doseId],
    );
  }

  /// Mark dose as missed
  Future<void> markDoseAsMissed(String doseId) async {
    final db = await _databaseService.database;
    await db.update(
      'doses',
      {
        'status': DoseStatus.missed.name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [doseId],
    );
  }

  /// Mark dose as skipped
  Future<void> markDoseAsSkipped(String doseId) async {
    final db = await _databaseService.database;
    await db.update(
      'doses',
      {
        'status': DoseStatus.skipped.name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [doseId],
    );
  }

  /// Delete a dose
  Future<void> deleteDose(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'doses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Generate doses for a protocol based on its schedule
  Future<List<Dose>> generateDosesForProtocol(
    Protocol protocol, {
    required DateTime start,
    required DateTime end,
  }) async {
    final doses = <Dose>[];
    var currentDate = start;

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      // Check if current date falls on a scheduled day
      if (_shouldScheduleDose(protocol, currentDate)) {
        for (final time in protocol.times) {
          final dose = Dose(
            id: _uuid.v4(),
            protocolId: protocol.id,
            scheduledDate: currentDate,
            scheduledTime: time,
            status: DoseStatus.scheduled,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          doses.add(dose);
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return doses;
  }

  /// Check if a dose should be scheduled on a given date
  bool _shouldScheduleDose(Protocol protocol, DateTime date) {
    // Check if date is within protocol period
    if (date.isBefore(protocol.startDate)) return false;
    if (protocol.endDate != null && date.isAfter(protocol.endDate!)) return false;

    switch (protocol.frequency) {
      case ProtocolFrequency.daily:
        return true;
      
      case ProtocolFrequency.everyOtherDay:
        final daysDiff = date.difference(protocol.startDate).inDays;
        return daysDiff % 2 == 0;
      
      case ProtocolFrequency.twiceWeekly:
      case ProtocolFrequency.weekly:
        if (protocol.daysOfWeek == null || protocol.daysOfWeek!.isEmpty) {
          return false;
        }
        final dayName = DaysOfWeek.all[date.weekday % 7];
        return protocol.daysOfWeek!.contains(dayName);
      
      case ProtocolFrequency.biWeekly:
        final weeksDiff = date.difference(protocol.startDate).inDays ~/ 7;
        if (weeksDiff % 2 != 0) return false;
        if (protocol.daysOfWeek == null || protocol.daysOfWeek!.isEmpty) {
          return date.weekday == protocol.startDate.weekday;
        }
        final dayName = DaysOfWeek.all[date.weekday % 7];
        return protocol.daysOfWeek!.contains(dayName);
      
      case ProtocolFrequency.monthly:
        return date.day == protocol.startDate.day;
      
      default:
        return true;
    }
  }

  /// Calculate adherence rate for a protocol
  Future<double> calculateAdherenceRate(String protocolId, {int days = 30}) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    
    final doses = await getDosesInRange(start, end);
    final protocolDoses = doses.where((d) => d.protocolId == protocolId).toList();
    
    if (protocolDoses.isEmpty) return 0.0;
    
    final takenCount = protocolDoses.where((d) => d.status == DoseStatus.taken).length;
    return (takenCount / protocolDoses.length) * 100;
  }

  /// Calculate overall adherence rate
  Future<double> calculateOverallAdherence({int days = 30}) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    
    final doses = await getDosesInRange(start, end);
    if (doses.isEmpty) return 0.0;
    
    final takenCount = doses.where((d) => d.status == DoseStatus.taken).length;
    return (takenCount / doses.length) * 100;
  }

  /// Calculate current streak
  Future<int> calculateCurrentStreak() async {
    var streak = 0;
    var checkDate = DateTime.now();
    
    while (true) {
      final dayDoses = await getDosesInRange(
        DateTime(checkDate.year, checkDate.month, checkDate.day),
        DateTime(checkDate.year, checkDate.month, checkDate.day, 23, 59, 59),
      );
      
      if (dayDoses.isEmpty) {
        // No doses scheduled, continue streak
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }
      
      final allTaken = dayDoses.every((d) => d.status == DoseStatus.taken || d.status == DoseStatus.skipped);
      
      if (allTaken) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
      
      // Limit check to 365 days
      if (streak >= 365) break;
    }
    
    return streak;
  }
}

