import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'namedrill.db';
  static const _databaseVersion = 1;

  // Table names
  static const tableGroups = 'groups';
  static const tablePeople = 'people';
  static const tableLearningRecords = 'learning_records';
  static const tableQuizScores = 'quiz_scores';
  static const tableUserStats = 'user_stats';
  static const tableSettings = 'settings';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Groups table
    await db.execute('''
      CREATE TABLE $tableGroups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        sortOrder INTEGER DEFAULT 0
      )
    ''');

    // People table
    await db.execute('''
      CREATE TABLE $tablePeople (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        name TEXT NOT NULL,
        photoPath TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (groupId) REFERENCES $tableGroups (id) ON DELETE CASCADE
      )
    ''');

    // Learning records table
    await db.execute('''
      CREATE TABLE $tableLearningRecords (
        id TEXT PRIMARY KEY,
        personId TEXT NOT NULL UNIQUE,
        interval INTEGER DEFAULT 0,
        easeFactor REAL DEFAULT 2.5,
        nextReviewDate TEXT NOT NULL,
        reviewCount INTEGER DEFAULT 0,
        lastReviewedAt TEXT,
        FOREIGN KEY (personId) REFERENCES $tablePeople (id) ON DELETE CASCADE
      )
    ''');

    // Quiz scores table
    await db.execute('''
      CREATE TABLE $tableQuizScores (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        score INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (groupId) REFERENCES $tableGroups (id) ON DELETE CASCADE
      )
    ''');

    // User stats table (single row)
    await db.execute('''
      CREATE TABLE $tableUserStats (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        currentStreak INTEGER DEFAULT 0,
        lastActiveDate TEXT,
        longestStreak INTEGER DEFAULT 0
      )
    ''');

    // Settings table (single row)
    await db.execute('''
      CREATE TABLE $tableSettings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        notificationsEnabled INTEGER DEFAULT 0,
        notificationHour INTEGER DEFAULT 8,
        notificationMinute INTEGER DEFAULT 0,
        darkMode INTEGER DEFAULT 0,
        isPremium INTEGER DEFAULT 0,
        premiumPurchaseDate TEXT,
        sessionCardCount INTEGER DEFAULT 15
      )
    ''');

    // Initialize default rows
    await db.insert(tableUserStats, {'id': 1, 'currentStreak': 0, 'longestStreak': 0});
    await db.insert(tableSettings, {'id': 1});

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_people_groupId ON $tablePeople (groupId)');
    await db.execute('CREATE INDEX idx_learning_personId ON $tableLearningRecords (personId)');
    await db.execute('CREATE INDEX idx_learning_nextReviewDate ON $tableLearningRecords (nextReviewDate)');
    await db.execute('CREATE INDEX idx_quiz_groupId ON $tableQuizScores (groupId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }

  /// Delete all data and recreate the database
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    
    await close();
    await deleteDatabase(path);
    _database = await _initDatabase();
  }

  /// Reset only learning progress (keep people and groups)
  Future<void> resetProgress() async {
    final db = await database;
    await db.delete(tableLearningRecords);
    await db.delete(tableQuizScores);
    await db.update(tableUserStats, {
      'currentStreak': 0,
      'lastActiveDate': null,
      'longestStreak': 0,
    });
  }
}
