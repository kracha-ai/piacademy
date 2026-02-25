// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/data_models.dart';

class DatabaseService {

  // --- LOCAL DATABASE (SQFLITE) SETUP ---
  static Database? _database;
  static const String _unfinishedTestTable = 'unfinished_tests';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = await getDatabasesPath();
    String dbPath = join(path, 'pi_academy_local.db');
    return await openDatabase(
      dbPath,
      version: 1, // <--- IMPORTANT: Increment version if schema changes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade to handle schema changes
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_unfinishedTestTable(
        id INTEGER PRIMARY KEY,
        testId TEXT,
        testName TEXT,
        currentQuestionIndex INTEGER,
        selectedAnswers TEXT,      -- <--- CHANGED: Renamed from 'selectedAnswers' to reflect model better, or kept for consistency
        timeSpentSeconds INTEGER
      )
    ''');
  }

  // --- ADDED: onUpgrade method to handle schema changes for existing users ---
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) { // If upgrading from a version older than 1 (e.g., initial creation)
      // This case is already handled by _onCreate for version 1
    }
    // Add migration steps for future versions here
    // Example: if (oldVersion < 2) { await db.execute("ALTER TABLE $_unfinishedTestTable ADD COLUMN newColumn TEXT"); }
  }

  // --- REAL LOCAL DB METHODS FOR RESUME LOGIC ---

  Future<void> saveUnfinishedTest(UnfinishedTest test) async {
    final db = await database;
    // Always delete existing unfinished test to ensure only one is saved
    await db.delete(_unfinishedTestTable);
    await db.insert(_unfinishedTestTable, test.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    print("LocalDB: Unfinished test saved: ${test.testName}");
  }

  Future<UnfinishedTest?> getUnfinishedTest() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_unfinishedTestTable);
    if (maps.isNotEmpty) {
      return UnfinishedTest.fromMap(maps.first);
    }
    return null;
  }

  Future<void> clearUnfinishedTest() async {
    final db = await database;
    await db.delete(_unfinishedTestTable);
    print("LocalDB: Unfinished test progress cleared.");
  }

  // --- MOCKED METHODS TO FIX YOUR ERRORS ---

  // getUserStats method that your HomeScreen needs
  Future<UserStats> getUserStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return UserStats(
      id: 1,
      testsTaken: 37,
      avgScore: 0.81,
      timeSpentSeconds: const Duration(hours: 21, minutes: 45).inSeconds, // Return Duration
    );
  }

  // saveTestResult method that your MockTestScreen needs
  Future<void> saveTestResult({
    required String testId,
    required String testName,
    required int score,
    required int totalQuestions,
    required Duration timeTaken,
    required List<int?> userAnswers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    print("--- Test Result Saved (Simulated) ---");
    print("Test ID: $testId");
    print("Test Name: $testName");
    print("Score: $score / $totalQuestions");
    print("Time Taken: ${timeTaken.inMinutes}m ${timeTaken.inSeconds.remainder(60)}s");
    print("---------------------------------------");
  }
}