import 'dart:convert';

/// Peptide model for peptide library entries
class Peptide {
  final String id;
  final String name;
  final List<String> alternativeNames;
  final String category;
  final String categoryColor;
  final String description;
  final List<String> benefits;
  final ResearchProtocols researchProtocols;
  final ReconstitutionInfo reconstitution;
  final String considerations;
  final String storage;
  final List<String> stacksWellWith;
  final List<ResearchReference> researchReferences;
  final String? userNotes;
  final bool isFavorite;
  final int viewCount;
  final DateTime? lastViewed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Peptide({
    required this.id,
    required this.name,
    required this.alternativeNames,
    required this.category,
    required this.categoryColor,
    required this.description,
    required this.benefits,
    required this.researchProtocols,
    required this.reconstitution,
    required this.considerations,
    required this.storage,
    required this.stacksWellWith,
    required this.researchReferences,
    this.userNotes,
    required this.isFavorite,
    required this.viewCount,
    this.lastViewed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Peptide.fromMap(Map<String, dynamic> map) {
    return Peptide(
      id: map['id'] as String,
      name: map['name'] as String,
      alternativeNames: List<String>.from(
        jsonDecode(map['alternative_names'] as String? ?? '[]'),
      ),
      category: map['category'] as String,
      categoryColor: map['category_color'] as String,
      description: map['description'] as String,
      benefits: List<String>.from(
        jsonDecode(map['benefits'] as String? ?? '[]'),
      ),
      researchProtocols: ResearchProtocols.fromMap(
        jsonDecode(map['research_protocols'] as String? ?? '{}'),
      ),
      reconstitution: ReconstitutionInfo.fromMap(
        jsonDecode(map['reconstitution'] as String? ?? '{}'),
      ),
      considerations: map['considerations'] as String? ?? '',
      storage: map['storage'] as String? ?? '',
      stacksWellWith: List<String>.from(
        jsonDecode(map['stacks_well_with'] as String? ?? '[]'),
      ),
      researchReferences: (jsonDecode(map['research_references'] as String? ?? '[]') as List)
          .map((e) => ResearchReference.fromMap(e))
          .toList(),
      userNotes: map['user_notes'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      viewCount: map['view_count'] as int? ?? 0,
      lastViewed: map['last_viewed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_viewed'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'alternative_names': jsonEncode(alternativeNames),
      'category': category,
      'category_color': categoryColor,
      'description': description,
      'benefits': jsonEncode(benefits),
      'research_protocols': jsonEncode(researchProtocols.toMap()),
      'reconstitution': jsonEncode(reconstitution.toMap()),
      'considerations': considerations,
      'storage': storage,
      'stacks_well_with': jsonEncode(stacksWellWith),
      'research_references': jsonEncode(
        researchReferences.map((e) => e.toMap()).toList(),
      ),
      'user_notes': userNotes,
      'is_favorite': isFavorite ? 1 : 0,
      'view_count': viewCount,
      'last_viewed': lastViewed?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Peptide copyWith({
    String? id,
    String? name,
    List<String>? alternativeNames,
    String? category,
    String? categoryColor,
    String? description,
    List<String>? benefits,
    ResearchProtocols? researchProtocols,
    ReconstitutionInfo? reconstitution,
    String? considerations,
    String? storage,
    List<String>? stacksWellWith,
    List<ResearchReference>? researchReferences,
    String? userNotes,
    bool? isFavorite,
    int? viewCount,
    DateTime? lastViewed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Peptide(
      id: id ?? this.id,
      name: name ?? this.name,
      alternativeNames: alternativeNames ?? this.alternativeNames,
      category: category ?? this.category,
      categoryColor: categoryColor ?? this.categoryColor,
      description: description ?? this.description,
      benefits: benefits ?? this.benefits,
      researchProtocols: researchProtocols ?? this.researchProtocols,
      reconstitution: reconstitution ?? this.reconstitution,
      considerations: considerations ?? this.considerations,
      storage: storage ?? this.storage,
      stacksWellWith: stacksWellWith ?? this.stacksWellWith,
      researchReferences: researchReferences ?? this.researchReferences,
      userNotes: userNotes ?? this.userNotes,
      isFavorite: isFavorite ?? this.isFavorite,
      viewCount: viewCount ?? this.viewCount,
      lastViewed: lastViewed ?? this.lastViewed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Research protocol information
class ResearchProtocols {
  final String dosageRange;
  final String administration;
  final String duration;
  final String frequency;

  ResearchProtocols({
    required this.dosageRange,
    required this.administration,
    required this.duration,
    required this.frequency,
  });

  factory ResearchProtocols.fromMap(Map<String, dynamic> map) {
    return ResearchProtocols(
      dosageRange: map['dosage_range'] as String? ?? '',
      administration: map['administration'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dosage_range': dosageRange,
      'administration': administration,
      'duration': duration,
      'frequency': frequency,
    };
  }
}

/// Reconstitution information
class ReconstitutionInfo {
  final List<double> commonVialSizes;
  final String typicalWaterVolume;
  final String concentrationExample;

  ReconstitutionInfo({
    required this.commonVialSizes,
    required this.typicalWaterVolume,
    required this.concentrationExample,
  });

  factory ReconstitutionInfo.fromMap(Map<String, dynamic> map) {
    return ReconstitutionInfo(
      commonVialSizes: map['common_vial_sizes'] != null
          ? List<double>.from(
              (map['common_vial_sizes'] as List).map((e) => (e as num).toDouble()),
            )
          : [],
      typicalWaterVolume: map['typical_water_volume'] as String? ?? '',
      concentrationExample: map['concentration_example'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'common_vial_sizes': commonVialSizes,
      'typical_water_volume': typicalWaterVolume,
      'concentration_example': concentrationExample,
    };
  }
}

/// Research reference information
class ResearchReference {
  final String pmid;
  final String title;
  final int year;
  final String studyType;
  final String url;

  ResearchReference({
    required this.pmid,
    required this.title,
    required this.year,
    required this.studyType,
    required this.url,
  });

  factory ResearchReference.fromMap(Map<String, dynamic> map) {
    return ResearchReference(
      pmid: map['pmid'] as String? ?? '',
      title: map['title'] as String? ?? '',
      year: map['year'] as int? ?? 0,
      studyType: map['study_type'] as String? ?? '',
      url: map['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pmid': pmid,
      'title': title,
      'year': year,
      'study_type': studyType,
      'url': url,
    };
  }
}

/// Peptide categories
class PeptideCategory {
  static const String ghSecretagogues = 'Growth Hormone Releasing / GH Secretagogues';
  static const String bodyComposition = 'Body Composition / Metabolism';
  static const String regenerative = 'Regenerative / Soft Tissue Support';
  static const String neuroCognitive = 'Neuro / Cognitive Support';
  static const String energyPerformance = 'Energy / Performance / Endurance';
  static const String skinHairBeauty = 'Skin, Hair, Beauty';
  static const String muscleStrength = 'Muscle / Strength / Recovery';
  static const String longevity = 'Longevity / Systemic Peptides';
  static const String gutMetabolic = 'Gut / Metabolic Support';

  static const List<String> all = [
    ghSecretagogues,
    bodyComposition,
    regenerative,
    neuroCognitive,
    energyPerformance,
    skinHairBeauty,
    muscleStrength,
    longevity,
    gutMetabolic,
  ];

  static String getShortName(String category) {
    switch (category) {
      case ghSecretagogues:
        return 'GH Secretagogues';
      case bodyComposition:
        return 'Body Comp';
      case regenerative:
        return 'Regenerative';
      case neuroCognitive:
        return 'Cognitive';
      case energyPerformance:
        return 'Performance';
      case skinHairBeauty:
        return 'Beauty';
      case muscleStrength:
        return 'Muscle';
      case longevity:
        return 'Longevity';
      case gutMetabolic:
        return 'Gut Health';
      default:
        return category;
    }
  }
}

