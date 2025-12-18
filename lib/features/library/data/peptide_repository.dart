import '../../../core/models/peptide.dart';
import '../../../core/services/database_service.dart';

/// Repository for peptide library data operations
class PeptideRepository {
  final DatabaseService _databaseService;

  PeptideRepository(this._databaseService);

  /// Get all peptides
  Future<List<Peptide>> getAllPeptides() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peptides',
      orderBy: 'name ASC',
    );
    return maps.map((map) => Peptide.fromMap(map)).toList();
  }

  /// Get peptides by category
  Future<List<Peptide>> getPeptidesByCategory(String category) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peptides',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Peptide.fromMap(map)).toList();
  }

  /// Get peptide by ID
  Future<Peptide?> getPeptideById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peptides',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Peptide.fromMap(maps.first);
  }

  /// Get peptide by name
  Future<Peptide?> getPeptideByName(String name) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peptides',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
    );
    if (maps.isEmpty) return null;
    return Peptide.fromMap(maps.first);
  }

  /// Search peptides by name or alternative names
  Future<List<Peptide>> searchPeptides(String query) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peptides',
      where: 'LOWER(name) LIKE ? OR LOWER(alternative_names) LIKE ? OR LOWER(benefits) LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%', '%${query.toLowerCase()}%', '%${query.toLowerCase()}%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Peptide.fromMap(map)).toList();
  }

  /// Get favorite peptides
  Future<List<Peptide>> getFavoritePeptides() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peptides',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Peptide.fromMap(map)).toList();
  }

  /// Get recently viewed peptides
  Future<List<Peptide>> getRecentlyViewedPeptides({int limit = 10}) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peptides',
      where: 'last_viewed IS NOT NULL',
      orderBy: 'last_viewed DESC',
      limit: limit,
    );
    return maps.map((map) => Peptide.fromMap(map)).toList();
  }

  /// Toggle peptide favorite status
  Future<void> toggleFavorite(String id) async {
    final peptide = await getPeptideById(id);
    if (peptide == null) return;

    final db = await _databaseService.database;
    await db.update(
      'peptides',
      {
        'is_favorite': peptide.isFavorite ? 0 : 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update peptide view count and last viewed
  Future<void> updatePeptideViewed(String id) async {
    final peptide = await getPeptideById(id);
    if (peptide == null) return;

    final db = await _databaseService.database;
    await db.update(
      'peptides',
      {
        'view_count': peptide.viewCount + 1,
        'last_viewed': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update user notes for a peptide
  Future<void> updateUserNotes(String id, String? notes) async {
    final db = await _databaseService.database;
    await db.update(
      'peptides',
      {
        'user_notes': notes,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all categories with peptide counts
  Future<Map<String, int>> getCategoryCounts() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM peptides GROUP BY category ORDER BY category',
    );
    return Map.fromEntries(
      result.map((row) => MapEntry(row['category'] as String, row['count'] as int)),
    );
  }

  /// Get peptides that stack well with a given peptide
  Future<List<Peptide>> getStackingPeptides(String peptideId) async {
    final peptide = await getPeptideById(peptideId);
    if (peptide == null || peptide.stacksWellWith.isEmpty) return [];

    final peptides = <Peptide>[];
    for (final stackId in peptide.stacksWellWith) {
      final stackPeptide = await getPeptideById(stackId);
      if (stackPeptide != null) {
        peptides.add(stackPeptide);
      }
    }
    return peptides;
  }

  /// Get peptides in the same category
  Future<List<Peptide>> getRelatedPeptides(String peptideId, {int limit = 5}) async {
    final peptide = await getPeptideById(peptideId);
    if (peptide == null) return [];

    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'peptides',
      where: 'category = ? AND id != ?',
      whereArgs: [peptide.category, peptideId],
      orderBy: 'view_count DESC',
      limit: limit,
    );
    return maps.map((map) => Peptide.fromMap(map)).toList();
  }
}

