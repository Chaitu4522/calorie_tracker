import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// Service for all SQLite database operations.
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'calorie_tracker.db';
  static const int _dbVersion = 1;

  /// Get or create the database instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Create database tables.
  Future<void> _onCreate(Database db, int version) async {
    // User table (single row)
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        daily_calorie_goal INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Entries table
    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        calories INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Create index for faster date queries
    await db.execute('''
      CREATE INDEX idx_entries_timestamp ON entries(timestamp)
    ''');
  }

  // ============ User Operations ============

  /// Check if user exists (first launch check).
  Future<bool> userExists() async {
    final db = await database;
    final result = await db.query('user', where: 'id = ?', whereArgs: [1]);
    return result.isNotEmpty;
  }

  /// Get the user profile.
  Future<User?> getUser() async {
    final db = await database;
    final result = await db.query('user', where: 'id = ?', whereArgs: [1]);
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  /// Create or update user profile.
  Future<void> saveUser(User user) async {
    final db = await database;
    await db.insert(
      'user',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update user profile.
  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'user',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ============ Entry Operations ============

  /// Add a new entry.
  Future<int> addEntry(Entry entry) async {
    final db = await database;
    return await db.insert('entries', entry.toMap());
  }

  /// Add multiple entries in a single transaction.
  Future<void> addEntries(List<Entry> entries) async {
    if (entries.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in entries) {
        batch.insert('entries', entry.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  /// Update an existing entry.
  Future<void> updateEntry(Entry entry) async {
    final db = await database;
    await db.update(
      'entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Delete an entry.
  Future<void> deleteEntry(int id) async {
    final db = await database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all entries for a specific date.
  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.query(
      'entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => Entry.fromMap(map)).toList();
  }

  /// Get total calories for a specific date.
  Future<int> getTotalCaloriesForDate(DateTime date) async {
    final entries = await getEntriesForDate(date);
    int total = 0;
    for (final entry in entries) {
      total += entry.calories;
    }
    return total;
  }

  /// Get entries for a date range.
  Future<List<Entry>> getEntriesForRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'entries',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return result.map((map) => Entry.fromMap(map)).toList();
  }

  /// Get daily calorie totals for a date range.
  Future<Map<DateTime, int>> getDailyTotalsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final entries = await getEntriesForRange(start, end);
    final Map<DateTime, int> totals = {};

    for (final entry in entries) {
      final date = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      totals[date] = (totals[date] ?? 0) + entry.calories;
    }

    return totals;
  }

  // ============ Statistics Operations ============

  /// Get total number of entries.
  Future<int> getTotalEntryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM entries');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total calories logged (all time).
  Future<int> getTotalCalories() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(calories) as total FROM entries',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get all unique dates with entries (for streak calculation).
  Future<List<DateTime>> getAllEntryDates() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT DATE(timestamp) as date FROM entries 
      ORDER BY date DESC
    ''');

    return result.map((row) {
      final dateStr = row['date'] as String;
      return DateTime.parse(dateStr);
    }).toList();
  }

  /// Get first entry date.
  Future<DateTime?> getFirstEntryDate() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MIN(timestamp) as first_date FROM entries',
    );
    if (result.isEmpty || result.first['first_date'] == null) return null;
    return DateTime.parse(result.first['first_date'] as String);
  }

  // ============ Data Management ============

  /// Clear all entries.
  Future<void> clearAllEntries() async {
    final db = await database;
    await db.delete('entries');
  }

  /// Clear all data (entries and user).
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('entries');
    await db.delete('user');
  }

  /// Export all entries as list of maps (for CSV export).
  Future<List<Map<String, dynamic>>> exportEntries() async {
    final db = await database;
    return await db.query('entries', orderBy: 'timestamp ASC');
  }

  /// Close the database.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
