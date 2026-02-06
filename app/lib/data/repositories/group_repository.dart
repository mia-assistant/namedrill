import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/group_model.dart';

class GroupRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<GroupModel>> getAllGroups() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableGroups,
      orderBy: 'sortOrder ASC, createdAt DESC',
    );
    return maps.map((map) => GroupModel.fromMap(map)).toList();
  }

  Future<GroupModel?> getGroupById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableGroups,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return GroupModel.fromMap(maps.first);
  }

  Future<int> getGroupCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableGroups}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> insertGroup(GroupModel group) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableGroups,
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateGroup(GroupModel group) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableGroups,
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> deleteGroup(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableGroups,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateGroupOrder(List<String> groupIds) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (int i = 0; i < groupIds.length; i++) {
      batch.update(
        DatabaseHelper.tableGroups,
        {'sortOrder': i},
        where: 'id = ?',
        whereArgs: [groupIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }
}
