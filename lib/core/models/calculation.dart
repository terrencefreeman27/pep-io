/// Calculation model for dose calculator history
class Calculation {
  final String id;
  final String? peptideId;
  final String peptideName;
  final double vialQuantity;
  final String vialUnit; // 'mcg' or 'mg'
  final double waterVolume;
  final String syringeType;
  final double desiredDose;
  final String desiredDoseUnit; // 'mcg' or 'mg'
  final double concentration;
  final double? dosePerUnit;
  final double volumeNeeded;
  final int totalDoses;
  final String? notes;
  final DateTime createdAt;

  Calculation({
    required this.id,
    this.peptideId,
    required this.peptideName,
    required this.vialQuantity,
    required this.vialUnit,
    required this.waterVolume,
    required this.syringeType,
    required this.desiredDose,
    required this.desiredDoseUnit,
    required this.concentration,
    this.dosePerUnit,
    required this.volumeNeeded,
    required this.totalDoses,
    this.notes,
    required this.createdAt,
  });

  factory Calculation.fromMap(Map<String, dynamic> map) {
    return Calculation(
      id: map['id'] as String,
      peptideId: map['peptide_id'] as String?,
      peptideName: map['peptide_name'] as String,
      vialQuantity: (map['vial_quantity'] as num).toDouble(),
      vialUnit: map['vial_unit'] as String,
      waterVolume: (map['water_volume'] as num).toDouble(),
      syringeType: map['syringe_type'] as String,
      desiredDose: (map['desired_dose'] as num).toDouble(),
      desiredDoseUnit: map['desired_dose_unit'] as String,
      concentration: (map['concentration'] as num).toDouble(),
      dosePerUnit: map['dose_per_unit'] != null
          ? (map['dose_per_unit'] as num).toDouble()
          : null,
      volumeNeeded: (map['volume_needed'] as num).toDouble(),
      totalDoses: map['total_doses'] as int,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peptide_id': peptideId,
      'peptide_name': peptideName,
      'vial_quantity': vialQuantity,
      'vial_unit': vialUnit,
      'water_volume': waterVolume,
      'syringe_type': syringeType,
      'desired_dose': desiredDose,
      'desired_dose_unit': desiredDoseUnit,
      'concentration': concentration,
      'dose_per_unit': dosePerUnit,
      'volume_needed': volumeNeeded,
      'total_doses': totalDoses,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Calculation copyWith({
    String? id,
    String? peptideId,
    String? peptideName,
    double? vialQuantity,
    String? vialUnit,
    double? waterVolume,
    String? syringeType,
    double? desiredDose,
    String? desiredDoseUnit,
    double? concentration,
    double? dosePerUnit,
    double? volumeNeeded,
    int? totalDoses,
    String? notes,
    DateTime? createdAt,
  }) {
    return Calculation(
      id: id ?? this.id,
      peptideId: peptideId ?? this.peptideId,
      peptideName: peptideName ?? this.peptideName,
      vialQuantity: vialQuantity ?? this.vialQuantity,
      vialUnit: vialUnit ?? this.vialUnit,
      waterVolume: waterVolume ?? this.waterVolume,
      syringeType: syringeType ?? this.syringeType,
      desiredDose: desiredDose ?? this.desiredDose,
      desiredDoseUnit: desiredDoseUnit ?? this.desiredDoseUnit,
      concentration: concentration ?? this.concentration,
      dosePerUnit: dosePerUnit ?? this.dosePerUnit,
      volumeNeeded: volumeNeeded ?? this.volumeNeeded,
      totalDoses: totalDoses ?? this.totalDoses,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get formatted concentration string
  String get formattedConcentration {
    if (vialUnit == 'mg') {
      return '${concentration.toStringAsFixed(2)} mg/mL';
    }
    return '${(concentration * 1000).toStringAsFixed(0)} mcg/mL';
  }

  /// Get formatted volume needed string
  String get formattedVolumeNeeded {
    if (dosePerUnit != null) {
      final units = (volumeNeeded * 100).round();
      return '${volumeNeeded.toStringAsFixed(2)} mL ($units units)';
    }
    return '${volumeNeeded.toStringAsFixed(2)} mL';
  }
}

/// Syringe types for dose calculator
class SyringeType {
  static const String insulin30 = '0.3 mL U-100 Insulin (30 units)';
  static const String insulin50 = '0.5 mL U-100 Insulin (50 units)';
  static const String insulin100 = '1.0 mL U-100 Insulin (100 units)';
  static const String syringe3ml = '3.0 mL syringe';
  static const String custom = 'Custom';

  static const List<String> all = [
    insulin30,
    insulin50,
    insulin100,
    syringe3ml,
    custom,
  ];

  /// Get max units for syringe type
  static int? getMaxUnits(String type) {
    switch (type) {
      case insulin30:
        return 30;
      case insulin50:
        return 50;
      case insulin100:
        return 100;
      case syringe3ml:
        return null; // mL based, not units
      default:
        return null;
    }
  }

  /// Check if syringe is insulin type
  static bool isInsulinSyringe(String type) {
    return type == insulin30 || type == insulin50 || type == insulin100;
  }
}

/// Dose calculator utility class
class DoseCalculator {
  /// Calculate concentration (mg/mL)
  static double calculateConcentration({
    required double vialQuantity,
    required String vialUnit,
    required double waterVolume,
  }) {
    final vialMg = vialUnit == 'mcg' ? vialQuantity / 1000 : vialQuantity;
    return vialMg / waterVolume;
  }

  /// Calculate dose per insulin unit (mcg/unit)
  static double calculateDosePerUnit({
    required double concentration,
  }) {
    // For U-100 syringe: 1 mL = 100 units
    // Dose per unit = concentration (mg/mL) * 1000 / 100 = concentration * 10 mcg
    return concentration * 10; // mcg per unit
  }

  /// Calculate volume needed for desired dose (mL)
  static double calculateVolumeNeeded({
    required double desiredDose,
    required String desiredDoseUnit,
    required double concentration,
  }) {
    final desiredMg = desiredDoseUnit == 'mcg' ? desiredDose / 1000 : desiredDose;
    return desiredMg / concentration;
  }

  /// Calculate total doses available in vial
  static int calculateTotalDoses({
    required double vialQuantity,
    required String vialUnit,
    required double desiredDose,
    required String desiredDoseUnit,
  }) {
    final vialMcg = vialUnit == 'mg' ? vialQuantity * 1000 : vialQuantity;
    final doseMcg = desiredDoseUnit == 'mg' ? desiredDose * 1000 : desiredDose;
    return (vialMcg / doseMcg).floor();
  }
}

