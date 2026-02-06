class PersonModel {
  final String id;
  final String groupId;
  final String name;
  final String photoPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonModel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.photoPath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'photoPath': photoPath,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PersonModel.fromMap(Map<String, dynamic> map) {
    return PersonModel(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      name: map['name'] as String,
      photoPath: map['photoPath'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  PersonModel copyWith({
    String? id,
    String? groupId,
    String? name,
    String? photoPath,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
