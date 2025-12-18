import 'package:flutter/foundation.dart';
import '../../../core/models/calculation.dart';

/// Provider for dose calculator state management
class CalculatorProvider extends ChangeNotifier {
  // Input values
  String? _selectedPeptideId;
  String _peptideName = '';
  double? _vialQuantity;
  String _vialUnit = 'mg';
  double? _waterVolume;
  String _syringeType = SyringeType.insulin100;
  double? _desiredDose;
  String _desiredDoseUnit = 'mcg';

  // Results
  double? _concentration;
  double? _dosePerUnit;
  double? _volumeNeeded;
  int? _totalDoses;
  
  // History
  final List<Calculation> _history = [];

  // Getters
  String? get selectedPeptideId => _selectedPeptideId;
  String get peptideName => _peptideName;
  double? get vialQuantity => _vialQuantity;
  String get vialUnit => _vialUnit;
  double? get waterVolume => _waterVolume;
  String get syringeType => _syringeType;
  double? get desiredDose => _desiredDose;
  String get desiredDoseUnit => _desiredDoseUnit;
  
  double? get concentration => _concentration;
  double? get dosePerUnit => _dosePerUnit;
  double? get volumeNeeded => _volumeNeeded;
  int? get totalDoses => _totalDoses;
  
  List<Calculation> get history => _history;
  bool get hasResults => _concentration != null;
  bool get canCalculate => 
      _vialQuantity != null && 
      _vialQuantity! > 0 && 
      _waterVolume != null && 
      _waterVolume! > 0 && 
      _desiredDose != null && 
      _desiredDose! > 0;

  /// Set selected peptide
  void setSelectedPeptide(String? id, String name) {
    _selectedPeptideId = id;
    _peptideName = name;
    notifyListeners();
  }

  /// Set vial quantity
  void setVialQuantity(double? value) {
    _vialQuantity = value;
    _clearResults();
    notifyListeners();
  }

  /// Set vial unit
  void setVialUnit(String unit) {
    _vialUnit = unit;
    _clearResults();
    notifyListeners();
  }

  /// Set water volume
  void setWaterVolume(double? value) {
    _waterVolume = value;
    _clearResults();
    notifyListeners();
  }

  /// Set syringe type
  void setSyringeType(String type) {
    _syringeType = type;
    _clearResults();
    notifyListeners();
  }

  /// Set desired dose
  void setDesiredDose(double? value) {
    _desiredDose = value;
    _clearResults();
    notifyListeners();
  }

  /// Set desired dose unit
  void setDesiredDoseUnit(String unit) {
    _desiredDoseUnit = unit;
    _clearResults();
    notifyListeners();
  }

  /// Calculate dose
  void calculate() {
    if (!canCalculate) return;

    // Calculate concentration (mg/mL)
    _concentration = DoseCalculator.calculateConcentration(
      vialQuantity: _vialQuantity!,
      vialUnit: _vialUnit,
      waterVolume: _waterVolume!,
    );

    // Calculate dose per unit (for insulin syringes)
    if (SyringeType.isInsulinSyringe(_syringeType)) {
      _dosePerUnit = DoseCalculator.calculateDosePerUnit(
        concentration: _concentration!,
      );
    } else {
      _dosePerUnit = null;
    }

    // Calculate volume needed
    _volumeNeeded = DoseCalculator.calculateVolumeNeeded(
      desiredDose: _desiredDose!,
      desiredDoseUnit: _desiredDoseUnit,
      concentration: _concentration!,
    );

    // Calculate total doses
    _totalDoses = DoseCalculator.calculateTotalDoses(
      vialQuantity: _vialQuantity!,
      vialUnit: _vialUnit,
      desiredDose: _desiredDose!,
      desiredDoseUnit: _desiredDoseUnit,
    );

    notifyListeners();
  }

  /// Reset all values
  void reset() {
    _selectedPeptideId = null;
    _peptideName = '';
    _vialQuantity = null;
    _vialUnit = 'mg';
    _waterVolume = null;
    _syringeType = SyringeType.insulin100;
    _desiredDose = null;
    _desiredDoseUnit = 'mcg';
    _clearResults();
    notifyListeners();
  }

  /// Clear results only
  void _clearResults() {
    _concentration = null;
    _dosePerUnit = null;
    _volumeNeeded = null;
    _totalDoses = null;
  }

  /// Save calculation to history
  Calculation saveToHistory({String? notes}) {
    if (!hasResults) {
      throw Exception('No results to save');
    }

    final calculation = Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      peptideId: _selectedPeptideId,
      peptideName: _peptideName.isEmpty ? 'Custom' : _peptideName,
      vialQuantity: _vialQuantity!,
      vialUnit: _vialUnit,
      waterVolume: _waterVolume!,
      syringeType: _syringeType,
      desiredDose: _desiredDose!,
      desiredDoseUnit: _desiredDoseUnit,
      concentration: _concentration!,
      dosePerUnit: _dosePerUnit,
      volumeNeeded: _volumeNeeded!,
      totalDoses: _totalDoses!,
      notes: notes,
      createdAt: DateTime.now(),
    );

    _history.insert(0, calculation);
    
    // Keep only last 50 calculations
    if (_history.length > 50) {
      _history.removeLast();
    }

    notifyListeners();
    return calculation;
  }

  /// Load calculation from history
  void loadFromHistory(Calculation calculation) {
    _selectedPeptideId = calculation.peptideId;
    _peptideName = calculation.peptideName;
    _vialQuantity = calculation.vialQuantity;
    _vialUnit = calculation.vialUnit;
    _waterVolume = calculation.waterVolume;
    _syringeType = calculation.syringeType;
    _desiredDose = calculation.desiredDose;
    _desiredDoseUnit = calculation.desiredDoseUnit;
    _concentration = calculation.concentration;
    _dosePerUnit = calculation.dosePerUnit;
    _volumeNeeded = calculation.volumeNeeded;
    _totalDoses = calculation.totalDoses;
    notifyListeners();
  }

  /// Delete from history
  void deleteFromHistory(String id) {
    _history.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Clear history
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// Get formatted result string for sharing
  String getShareableResults() {
    if (!hasResults) return '';

    final buffer = StringBuffer();
    buffer.writeln('pep.io Dose Calculator Results');
    buffer.writeln('');
    if (_peptideName.isNotEmpty) {
      buffer.writeln('Peptide: $_peptideName');
    }
    buffer.writeln('Vial: $_vialQuantity $_vialUnit');
    buffer.writeln('Water: $_waterVolume mL');
    buffer.writeln('Desired Dose: $_desiredDose $_desiredDoseUnit');
    buffer.writeln('');
    buffer.writeln('Results:');
    buffer.writeln('- Concentration: ${_concentration!.toStringAsFixed(2)} mg/mL');
    if (_dosePerUnit != null) {
      buffer.writeln('- Dose per Unit: ${_dosePerUnit!.toStringAsFixed(2)} mcg/unit');
    }
    buffer.writeln('- Volume needed: ${_volumeNeeded!.toStringAsFixed(2)} mL');
    if (SyringeType.isInsulinSyringe(_syringeType)) {
      buffer.writeln('  (${(_volumeNeeded! * 100).round()} units)');
    }
    buffer.writeln('- Total doses: $_totalDoses');
    buffer.writeln('');
    buffer.writeln('For educational purposes only.');

    return buffer.toString();
  }
}

