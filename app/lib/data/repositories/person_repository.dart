import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../models/person_model.dart';

class PersonRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<PersonModel>> getPeopleByGroup(String groupId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tablePeople,
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => PersonModel.fromMap(map)).toList();
  }

  Future<PersonModel?> getPersonById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tablePeople,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PersonModel.fromMap(maps.first);
  }

  Future<int> getPersonCountByGroup(String groupId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tablePeople} WHERE groupId = ?',
      [groupId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalPersonCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tablePeople}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<PersonModel>> getPreviewPeopleForGroup(String groupId, {int limit = 6}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tablePeople,
      where: 'groupId = ?',
      whereArgs: [groupId],
      limit: limit,
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => PersonModel.fromMap(map)).toList();
  }

  Future<void> insertPerson(PersonModel person) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tablePeople,
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePerson(PersonModel person) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tablePeople,
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<void> deletePerson(String id) async {
    // First get the person to delete their photo
    final person = await getPersonById(id);
    if (person != null) {
      await _deletePhotoFile(person.photoPath);
    }

    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tablePeople,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> movePerson(String personId, String newGroupId) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tablePeople,
      {
        'groupId': newGroupId,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [personId],
    );
  }

  /// Save photo to app documents directory
  Future<String> savePhoto(String tempPath, String personId) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(directory.path, 'photos'));
    
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final extension = p.extension(tempPath);
    final newPath = p.join(photosDir.path, '$personId$extension');
    
    // Copy the file to the permanent location
    final tempFile = File(tempPath);
    await tempFile.copy(newPath);

    return newPath;
  }

  Future<void> _deletePhotoFile(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors when deleting photo
    }
  }

  /// Get all people across all groups (for stats)
  Future<List<PersonModel>> getAllPeople() async {
    final db = await _dbHelper.database;
    final maps = await db.query(DatabaseHelper.tablePeople);
    return maps.map((map) => PersonModel.fromMap(map)).toList();
  }
}
