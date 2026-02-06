import '../database/database_helper.dart';
import '../models/user_stats_model.dart';
import '../models/settings_model.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // User Stats
  Future<UserStatsModel> getUserStats() async {
    final db = await _dbHelper.database;
    final maps = await db.query(DatabaseHelper.tableUserStats, limit: 1);
    
    if (maps.isEmpty) {
      return UserStatsModel();
    }
    return UserStatsModel.fromMap(maps.first);
  }

  Future<void> updateUserStats(UserStatsModel stats) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableUserStats,
      {
        ...stats.toMap(),
        'id': 1,
      },
      where: 'id = 1',
    );
  }

  Future<void> recordActivity() async {
    final currentStats = await getUserStats();
    final updatedStats = currentStats.recordActivity();
    await updateUserStats(updatedStats);
  }

  // Settings
  Future<SettingsModel> getSettings() async {
    final db = await _dbHelper.database;
    final maps = await db.query(DatabaseHelper.tableSettings, limit: 1);
    
    if (maps.isEmpty) {
      return SettingsModel();
    }
    return SettingsModel.fromMap(maps.first);
  }

  Future<void> updateSettings(SettingsModel settings) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableSettings,
      {
        ...settings.toMap(),
        'id': 1,
      },
      where: 'id = 1',
    );
  }

  // Premium status helpers
  Future<bool> isPremium() async {
    final settings = await getSettings();
    return settings.isPremium;
  }

  Future<void> setPremium(bool isPremium, {DateTime? purchaseDate}) async {
    final settings = await getSettings();
    await updateSettings(settings.copyWith(
      isPremium: isPremium,
      premiumPurchaseDate: purchaseDate ?? DateTime.now(),
    ));
  }

  /// Get weekly activity across all groups
  Future<Map<DateTime, int>> getWeeklyActivity() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    // Get learning activity
    final learningMaps = await db.rawQuery('''
      SELECT date(lastReviewedAt) as activityDate, COUNT(*) as count 
      FROM ${DatabaseHelper.tableLearningRecords}
      WHERE lastReviewedAt >= ?
      GROUP BY date(lastReviewedAt)
    ''', [weekAgo.toIso8601String()]);

    // Get quiz activity
    final quizMaps = await db.rawQuery('''
      SELECT date(date) as activityDate, COUNT(*) as count 
      FROM ${DatabaseHelper.tableQuizScores}
      WHERE date >= ?
      GROUP BY date(date)
    ''', [weekAgo.toIso8601String()]);

    final result = <DateTime, int>{};
    
    for (final map in learningMaps) {
      final dateStr = map['activityDate'] as String?;
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        result[date] = (result[date] ?? 0) + (map['count'] as int);
      }
    }

    for (final map in quizMaps) {
      final dateStr = map['activityDate'] as String?;
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        result[date] = (result[date] ?? 0) + (map['count'] as int);
      }
    }

    return result;
  }
}
