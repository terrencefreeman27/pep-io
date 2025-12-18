/// User profile model for storing user information
class UserProfile {
  final int id;
  final String? name;
  final double? weight;
  final String? weightUnit; // 'lbs' or 'kg'
  final String? primaryGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.name,
    this.weight,
    this.weightUnit,
    this.primaryGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int,
      name: map['name'] as String?,
      weight: map['weight'] as double?,
      weightUnit: map['weight_unit'] as String?,
      primaryGoal: map['primary_goal'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'weight_unit': weightUnit,
      'primary_goal': primaryGoal,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    double? weight,
    String? weightUnit,
    String? primaryGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Create a default empty profile
  factory UserProfile.empty() {
    final now = DateTime.now();
    return UserProfile(
      id: 0,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// User goal model for selected wellness goals
class UserGoal {
  final int id;
  final String goalCategory;
  final DateTime createdAt;

  UserGoal({
    required this.id,
    required this.goalCategory,
    required this.createdAt,
  });

  factory UserGoal.fromMap(Map<String, dynamic> map) {
    return UserGoal(
      id: map['id'] as int,
      goalCategory: map['goal_category'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_category': goalCategory,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

