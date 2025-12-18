import 'package:flutter/foundation.dart';
import '../../../core/models/peptide.dart';
import '../data/peptide_repository.dart';

/// Provider for peptide library state management
class PeptideProvider extends ChangeNotifier {
  final PeptideRepository _repository;

  List<Peptide> _peptides = [];
  List<Peptide> _filteredPeptides = [];
  List<Peptide> _favorites = [];
  List<Peptide> _recentlyViewed = [];
  Map<String, int> _categoryCounts = {};
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  PeptideProvider(this._repository);

  // Getters
  List<Peptide> get peptides => _peptides;
  List<Peptide> get filteredPeptides => _filteredPeptides;
  List<Peptide> get favorites => _favorites;
  List<Peptide> get recentlyViewed => _recentlyViewed;
  Map<String, int> get categoryCounts => _categoryCounts;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all peptides
  Future<void> loadPeptides() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _peptides = await _repository.getAllPeptides();
      _filteredPeptides = _peptides;
      _categoryCounts = await _repository.getCategoryCounts();
      await loadFavorites();
      await loadRecentlyViewed();
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load favorite peptides
  Future<void> loadFavorites() async {
    _favorites = await _repository.getFavoritePeptides();
  }

  /// Load recently viewed peptides
  Future<void> loadRecentlyViewed() async {
    _recentlyViewed = await _repository.getRecentlyViewedPeptides();
  }

  /// Search peptides
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _filteredPeptides = _peptides;
    notifyListeners();
  }

  /// Apply current filters
  void _applyFilters() {
    var results = _peptides;

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      results = results.where((p) => p.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.alternativeNames.any((name) => name.toLowerCase().contains(query)) ||
            p.benefits.any((b) => b.toLowerCase().contains(query)) ||
            p.description.toLowerCase().contains(query);
      }).toList();
    }

    _filteredPeptides = results;
  }

  /// Get peptide by ID
  Peptide? getPeptideById(String id) {
    try {
      return _peptides.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get peptides by category
  List<Peptide> getPeptidesByCategory(String category) {
    return _peptides.where((p) => p.category == category).toList();
  }

  /// Get grouped peptides by category
  Map<String, List<Peptide>> getGroupedPeptides() {
    final grouped = <String, List<Peptide>>{};
    for (final peptide in _filteredPeptides) {
      grouped.putIfAbsent(peptide.category, () => []);
      grouped[peptide.category]!.add(peptide);
    }
    return grouped;
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    try {
      await _repository.toggleFavorite(id);
      
      // Update local state
      final index = _peptides.indexWhere((p) => p.id == id);
      if (index != -1) {
        _peptides[index] = _peptides[index].copyWith(
          isFavorite: !_peptides[index].isFavorite,
        );
      }
      
      await loadFavorites();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark peptide as viewed
  Future<void> markAsViewed(String id) async {
    try {
      await _repository.updatePeptideViewed(id);
      
      // Update local state
      final index = _peptides.indexWhere((p) => p.id == id);
      if (index != -1) {
        _peptides[index] = _peptides[index].copyWith(
          viewCount: _peptides[index].viewCount + 1,
          lastViewed: DateTime.now(),
        );
      }
      
      await loadRecentlyViewed();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Update user notes
  Future<void> updateUserNotes(String id, String? notes) async {
    try {
      await _repository.updateUserNotes(id, notes);
      
      // Update local state
      final index = _peptides.indexWhere((p) => p.id == id);
      if (index != -1) {
        _peptides[index] = _peptides[index].copyWith(userNotes: notes);
      }
      
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get stacking peptides for a peptide
  Future<List<Peptide>> getStackingPeptides(String peptideId) async {
    return _repository.getStackingPeptides(peptideId);
  }

  /// Get related peptides (same category)
  Future<List<Peptide>> getRelatedPeptides(String peptideId) async {
    return _repository.getRelatedPeptides(peptideId);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

