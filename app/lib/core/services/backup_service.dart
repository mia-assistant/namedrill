import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../data/database/database_helper.dart';

/// Simple JSON-based backup service for NameDrill.
/// Exports all data (groups, people, learning records, etc.) plus photos as base64.
class BackupService {
  static const String _backupVersion = '1.0';
  
  /// Export all data to a JSON file.
  /// Returns the file path on success.
  static Future<String> exportBackup() async {
    final db = await DatabaseHelper.instance.database;
    
    // Fetch all data from database
    final groupsData = await db.query(DatabaseHelper.tableGroups);
    final peopleData = await db.query(DatabaseHelper.tablePeople);
    final learningData = await db.query(DatabaseHelper.tableLearningRecords);
    final quizData = await db.query(DatabaseHelper.tableQuizScores);
    final statsData = await db.query(DatabaseHelper.tableUserStats);
    final settingsData = await db.query(DatabaseHelper.tableSettings);
    
    // Encode photos as base64
    final photosMap = <String, String>{};
    for (final person in peopleData) {
      final photoPath = person['photoPath'] as String?;
      if (photoPath != null && photoPath.isNotEmpty) {
        final photoFile = File(photoPath);
        if (await photoFile.exists()) {
          final bytes = await photoFile.readAsBytes();
          photosMap[photoPath] = base64Encode(bytes);
        }
      }
    }
    
    // Build the backup JSON structure
    final backup = {
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'groups': groupsData,
      'people': peopleData,
      'learningRecords': learningData,
      'quizScores': quizData,
      'userStats': statsData.isNotEmpty ? statsData.first : {},
      'settings': settingsData.isNotEmpty ? settingsData.first : {},
      'photos': photosMap,
    };
    
    // Write to app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final backupFile = File('${appDir.path}/namedrill_backup_$timestamp.json');
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
    await backupFile.writeAsString(jsonString);
    
    return backupFile.path;
  }
  
  /// Import data from a backup JSON file.
  /// This will REPLACE all existing data.
  static Future<void> importBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }
    
    final jsonString = await file.readAsString();
    final backup = json.decode(jsonString) as Map<String, dynamic>;
    
    // Validate version
    final version = backup['version'] as String?;
    if (version == null) {
      throw Exception('Invalid backup file: missing version');
    }
    
    final db = await DatabaseHelper.instance.database;
    
    // Clear existing data (order matters for foreign keys)
    await db.delete(DatabaseHelper.tableQuizScores);
    await db.delete(DatabaseHelper.tableLearningRecords);
    await db.delete(DatabaseHelper.tablePeople);
    await db.delete(DatabaseHelper.tableGroups);
    
    // Get photos map
    final photosMap = (backup['photos'] as Map<String, dynamic>?) ?? {};
    
    // Get app directory for storing photos
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    
    // Track old path -> new path mapping for people
    final photoPathMapping = <String, String>{};
    
    // Restore photos first
    for (final entry in photosMap.entries) {
      final oldPath = entry.key;
      final base64Data = entry.value as String;
      
      // Generate new path based on filename
      final fileName = oldPath.split('/').last;
      final newPath = '${photosDir.path}/$fileName';
      
      final bytes = base64Decode(base64Data);
      final photoFile = File(newPath);
      await photoFile.writeAsBytes(bytes);
      
      photoPathMapping[oldPath] = newPath;
    }
    
    // Restore groups
    final groups = (backup['groups'] as List<dynamic>?) ?? [];
    for (final groupMap in groups) {
      await db.insert(
        DatabaseHelper.tableGroups,
        Map<String, dynamic>.from(groupMap as Map),
      );
    }
    
    // Restore people with updated photo paths
    final people = (backup['people'] as List<dynamic>?) ?? [];
    for (final personMap in people) {
      final person = Map<String, dynamic>.from(personMap as Map);
      final oldPhotoPath = person['photoPath'] as String?;
      if (oldPhotoPath != null && photoPathMapping.containsKey(oldPhotoPath)) {
        person['photoPath'] = photoPathMapping[oldPhotoPath];
      }
      await db.insert(DatabaseHelper.tablePeople, person);
    }
    
    // Restore learning records
    final learningRecords = (backup['learningRecords'] as List<dynamic>?) ?? [];
    for (final recordMap in learningRecords) {
      await db.insert(
        DatabaseHelper.tableLearningRecords,
        Map<String, dynamic>.from(recordMap as Map),
      );
    }
    
    // Restore quiz scores
    final quizScores = (backup['quizScores'] as List<dynamic>?) ?? [];
    for (final scoreMap in quizScores) {
      await db.insert(
        DatabaseHelper.tableQuizScores,
        Map<String, dynamic>.from(scoreMap as Map),
      );
    }
    
    // Restore user stats
    final userStats = backup['userStats'] as Map<String, dynamic>?;
    if (userStats != null && userStats.isNotEmpty) {
      await db.update(
        DatabaseHelper.tableUserStats,
        {
          'currentStreak': userStats['currentStreak'] ?? 0,
          'lastActiveDate': userStats['lastActiveDate'],
          'longestStreak': userStats['longestStreak'] ?? 0,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    }
    
    // Restore settings (but preserve premium status from current device)
    final settings = backup['settings'] as Map<String, dynamic>?;
    if (settings != null && settings.isNotEmpty) {
      // Get current premium status to preserve it
      final currentSettings = await db.query(DatabaseHelper.tableSettings);
      final currentPremium = currentSettings.isNotEmpty 
          ? currentSettings.first['isPremium'] 
          : 0;
      final currentPremiumDate = currentSettings.isNotEmpty 
          ? currentSettings.first['premiumPurchaseDate'] 
          : null;
      
      await db.update(
        DatabaseHelper.tableSettings,
        {
          'notificationsEnabled': settings['notificationsEnabled'] ?? 0,
          'notificationHour': settings['notificationHour'] ?? 8,
          'notificationMinute': settings['notificationMinute'] ?? 0,
          'darkMode': settings['darkMode'] ?? 0,
          'sessionCardCount': settings['sessionCardCount'] ?? 15,
          // Preserve current premium status
          'isPremium': currentPremium,
          'premiumPurchaseDate': currentPremiumDate,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    }
  }
  
  /// Get the backup file info (size, date) for display.
  static Future<Map<String, dynamic>> getBackupInfo(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found');
    }
    
    final stat = await file.stat();
    final jsonString = await file.readAsString();
    final backup = json.decode(jsonString) as Map<String, dynamic>;
    
    final groups = (backup['groups'] as List?)?.length ?? 0;
    final people = (backup['people'] as List?)?.length ?? 0;
    
    return {
      'size': stat.size,
      'modified': stat.modified,
      'exportedAt': backup['exportedAt'],
      'version': backup['version'],
      'groupCount': groups,
      'personCount': people,
    };
  }
}
