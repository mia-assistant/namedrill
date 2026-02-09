import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PersonModel {
  final String id;
  final String groupId;
  final String name;
  final String photoPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Cached documents directory for resolving relative paths.
  static String? _docsDir;

  /// Initialize the documents directory path. Call once at app startup.
  static Future<void> initPhotoResolver() async {
    final dir = await getApplicationDocumentsDirectory();
    _docsDir = dir.path;
  }

  /// Resolve the stored photoPath to an absolute path.
  /// Handles both legacy absolute paths and new relative paths.
  String get resolvedPhotoPath {
    if (p.isAbsolute(photoPath)) return photoPath;
    if (_docsDir == null) return photoPath;
    return p.join(_docsDir!, photoPath);
  }

  /// Get the photo as a File with the resolved path.
  File get photoFile => File(resolvedPhotoPath);

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
