import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/quiz_score_model.dart';

class QuizRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> saveScore(QuizScoreModel score) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableQuizScores,
      score.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> getHighScore(String groupId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT MAX(score) as highScore FROM ${DatabaseHelper.tableQuizScores}
      WHERE groupId = ?
    ''', [groupId]);
    return result.first['highScore'] as int?;
  }

  Future<List<QuizScoreModel>> getRecentScores(String groupId, {int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableQuizScores,
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((map) => QuizScoreModel.fromMap(map)).toList();
  }

  /// Get quiz streak (consecutive days with a quiz) for a group
  Future<int> getQuizStreak(String groupId) async {
    final db = await _dbHelper.database;
    
    // Get distinct dates with quizzes, ordered by date descending
    final maps = await db.rawQuery('''
      SELECT DISTINCT date(date) as quizDate FROM ${DatabaseHelper.tableQuizScores}
      WHERE groupId = ?
      ORDER BY quizDate DESC
    ''', [groupId]);

    if (maps.isEmpty) return 0;

    int streak = 0;
    DateTime? previousDate;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final map in maps) {
      final dateStr = map['quizDate'] as String;
      final date = DateTime.parse(dateStr);

      if (previousDate == null) {
        // First date - check if it's today or yesterday
        final difference = todayDate.difference(date).inDays;
        if (difference > 1) break; // Streak broken
        streak = 1;
        previousDate = date;
      } else {
        final difference = previousDate.difference(date).inDays;
        if (difference == 1) {
          streak++;
          previousDate = date;
        } else {
          break; // Streak broken
        }
      }
    }

    return streak;
  }

  /// Get weekly activity (number of quizzes per day for last 7 days)
  Future<Map<DateTime, int>> getWeeklyActivity(String groupId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final maps = await db.rawQuery('''
      SELECT date(date) as quizDate, COUNT(*) as count FROM ${DatabaseHelper.tableQuizScores}
      WHERE groupId = ? AND date >= ?
      GROUP BY date(date)
    ''', [groupId, weekAgo.toIso8601String()]);

    final result = <DateTime, int>{};
    for (final map in maps) {
      final date = DateTime.parse(map['quizDate'] as String);
      result[date] = map['count'] as int;
    }
    return result;
  }
}
