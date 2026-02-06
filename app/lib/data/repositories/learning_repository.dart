import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/learning_record_model.dart';

class LearningRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get or create a learning record for a person
  Future<LearningRecordModel> getOrCreateRecord(String personId, String recordId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableLearningRecords,
      where: 'personId = ?',
      whereArgs: [personId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return LearningRecordModel.fromMap(maps.first);
    }

    // Create new record
    final newRecord = LearningRecordModel(
      id: recordId,
      personId: personId,
      nextReviewDate: DateTime.now(),
    );
    await db.insert(
      DatabaseHelper.tableLearningRecords,
      newRecord.toMap(),
    );
    return newRecord;
  }

  Future<LearningRecordModel?> getRecordByPersonId(String personId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableLearningRecords,
      where: 'personId = ?',
      whereArgs: [personId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LearningRecordModel.fromMap(maps.first);
  }

  Future<void> updateRecord(LearningRecordModel record) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableLearningRecords,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Get all cards due for review for a specific group
  Future<List<LearningRecordModel>> getDueCardsForGroup(
    String groupId, {
    int limit = 15,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.rawQuery('''
      SELECT lr.* FROM ${DatabaseHelper.tableLearningRecords} lr
      INNER JOIN ${DatabaseHelper.tablePeople} p ON lr.personId = p.id
      WHERE p.groupId = ? AND lr.nextReviewDate <= ?
      ORDER BY lr.nextReviewDate ASC
      LIMIT ?
    ''', [groupId, now, limit]);

    return maps.map((map) => LearningRecordModel.fromMap(map)).toList();
  }

  /// Get new cards (never reviewed) for a specific group
  Future<List<String>> getNewPersonIdsForGroup(String groupId) async {
    final db = await _dbHelper.database;
    
    final maps = await db.rawQuery('''
      SELECT p.id FROM ${DatabaseHelper.tablePeople} p
      LEFT JOIN ${DatabaseHelper.tableLearningRecords} lr ON p.id = lr.personId
      WHERE p.groupId = ? AND lr.id IS NULL
    ''', [groupId]);

    return maps.map((map) => map['id'] as String).toList();
  }

  /// Get cards for a learn session (due + new)
  Future<List<LearningRecordModel>> getSessionCards(
    String groupId,
    int sessionSize,
    String Function() generateId,
  ) async {
    final dueCards = await getDueCardsForGroup(groupId, limit: sessionSize);
    final remaining = sessionSize - dueCards.length;

    if (remaining > 0) {
      final newPersonIds = await getNewPersonIdsForGroup(groupId);
      final toAdd = newPersonIds.take(remaining);
      
      for (final personId in toAdd) {
        final record = await getOrCreateRecord(personId, generateId());
        dueCards.add(record);
      }
    }

    return dueCards;
  }

  /// Get learning stats for a group
  Future<Map<String, dynamic>> getGroupStats(String groupId) async {
    final db = await _dbHelper.database;
    
    // Count total people in group
    final totalResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseHelper.tablePeople}
      WHERE groupId = ?
    ''', [groupId]);
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    // Count "learned" (interval >= 7 days)
    final learnedResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseHelper.tableLearningRecords} lr
      INNER JOIN ${DatabaseHelper.tablePeople} p ON lr.personId = p.id
      WHERE p.groupId = ? AND lr.interval >= 7
    ''', [groupId]);
    final learned = Sqflite.firstIntValue(learnedResult) ?? 0;

    // Get last practiced date
    final lastPracticedResult = await db.rawQuery('''
      SELECT MAX(lr.lastReviewedAt) as lastPracticed FROM ${DatabaseHelper.tableLearningRecords} lr
      INNER JOIN ${DatabaseHelper.tablePeople} p ON lr.personId = p.id
      WHERE p.groupId = ?
    ''', [groupId]);
    final lastPracticedStr = lastPracticedResult.first['lastPracticed'] as String?;

    return {
      'total': total,
      'learned': learned,
      'percentLearned': total > 0 ? (learned / total * 100).round() : 0,
      'lastPracticed': lastPracticedStr != null ? DateTime.parse(lastPracticedStr) : null,
    };
  }

  /// Get weakest names (lowest retention) for a group
  Future<List<String>> getWeakestPersonIds(String groupId, {int limit = 5}) async {
    final db = await _dbHelper.database;
    
    final maps = await db.rawQuery('''
      SELECT lr.personId FROM ${DatabaseHelper.tableLearningRecords} lr
      INNER JOIN ${DatabaseHelper.tablePeople} p ON lr.personId = p.id
      WHERE p.groupId = ? AND lr.reviewCount > 0
      ORDER BY lr.easeFactor ASC, lr.interval ASC
      LIMIT ?
    ''', [groupId, limit]);

    return maps.map((map) => map['personId'] as String).toList();
  }

  /// Delete all records for a person
  Future<void> deleteRecordsForPerson(String personId) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableLearningRecords,
      where: 'personId = ?',
      whereArgs: [personId],
    );
  }
}
