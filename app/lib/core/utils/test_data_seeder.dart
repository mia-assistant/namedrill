import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/group_model.dart';
import '../../data/models/person_model.dart';

/// Utility class to seed test data for Maestro UI tests.
/// Only use in debug/testing environments.
class TestDataSeeder {
  static const _uuid = Uuid();
  
  static final List<String> _testNames = [
    'Alice Johnson',
    'Bob Smith', 
    'Carol Williams',
    'David Brown',
    'Emma Davis',
    'Frank Miller',
    'Grace Wilson',
    'Henry Moore',
    'Iris Taylor',
    'Jack Anderson',
  ];

  static final List<Color> _avatarColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  /// Seeds a test group with the specified number of people.
  /// Creates simple colored avatar images for each person.
  static Future<GroupModel> seedTestGroup({
    required String groupName,
    int peopleCount = 10,
  }) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    
    // Create group
    final groupId = _uuid.v4();
    final now = DateTime.now();
    final group = GroupModel(
      id: groupId,
      name: groupName,
      color: '#6366F1',
      createdAt: now,
      updatedAt: now,
    );
    
    await db.insert(DatabaseHelper.tableGroups, group.toMap());
    
    // Create people with generated avatar images
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(directory.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    
    for (int i = 0; i < peopleCount && i < _testNames.length; i++) {
      final personId = _uuid.v4();
      final name = _testNames[i];
      final photoPath = p.join(photosDir.path, '$personId.png');
      
      // Generate a simple colored avatar
      await _generateAvatarImage(
        photoPath, 
        name, 
        _avatarColors[i % _avatarColors.length],
      );
      
      final person = PersonModel(
        id: personId,
        groupId: groupId,
        name: name,
        photoPath: photoPath,
        notes: 'Test person $i',
        createdAt: now,
        updatedAt: now,
      );
      
      await db.insert(DatabaseHelper.tablePeople, person.toMap());
    }
    
    return group;
  }

  /// Generates a simple colored avatar image with initials.
  static Future<void> _generateAvatarImage(
    String path,
    String name,
    Color color,
  ) async {
    const size = 256;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
    
    // Draw background circle
    final paint = Paint()..color = color;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );
    
    // Draw initials
    final initials = name.split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 80,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final file = File(path);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
  }

  /// Clears all test data (groups and people).
  static Future<void> clearAllData() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    
    // Delete all people photos
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(directory.path, 'photos'));
    if (await photosDir.exists()) {
      await photosDir.delete(recursive: true);
    }
    
    // Clear database tables
    await db.delete(DatabaseHelper.tablePeople);
    await db.delete(DatabaseHelper.tableGroups);
    await db.delete(DatabaseHelper.tableLearningRecords);
    await db.delete(DatabaseHelper.tableQuizScores);
  }
}
