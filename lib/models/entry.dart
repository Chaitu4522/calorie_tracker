/// Data model for a calorie entry.
class Entry {
  final int? id;
  final String description;
  final int calories;
  final DateTime timestamp;

  Entry({
    this.id,
    required this.description,
    required this.calories,
    required this.timestamp,
  });

  /// Create Entry from database map.
  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'] as int?,
      description: map['description'] as String,
      calories: map['calories'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  /// Convert Entry to database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'calories': calories,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  Entry copyWith({
    int? id,
    String? description,
    int? calories,
    DateTime? timestamp,
  }) {
    return Entry(
      id: id ?? this.id,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
