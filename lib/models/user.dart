/// Data model for user profile.
class User {
  final int id;
  final String name;
  final int dailyCalorieGoal;
  final DateTime createdAt;

  User({
    this.id = 1,
    required this.name,
    required this.dailyCalorieGoal,
    required this.createdAt,
  });

  /// Create User from database map.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      name: map['name'] as String,
      dailyCalorieGoal: map['daily_calorie_goal'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert User to database map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'daily_calorie_goal': dailyCalorieGoal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  User copyWith({
    int? id,
    String? name,
    int? dailyCalorieGoal,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
