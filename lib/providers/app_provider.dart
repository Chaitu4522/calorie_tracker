import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Main application state provider.
class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final SecureStorageService _secureStorage = SecureStorageService();

  User? _user;
  List<Entry> _todayEntries = [];
  int _todayCalories = 0;
  bool _isLoading = true;
  bool _isFirstLaunch = true;

  // Getters
  User? get user => _user;
  List<Entry> get todayEntries => _todayEntries;
  int get todayCalories => _todayCalories;
  bool get isLoading => _isLoading;
  bool get isFirstLaunch => _isFirstLaunch;
  int get dailyGoal => _user?.dailyCalorieGoal ?? 2000;
  String get userName => _user?.name ?? 'User';

  double get progressPercentage {
    if (dailyGoal <= 0) return 0;
    return (_todayCalories / dailyGoal).clamp(0.0, 1.5);
  }

  bool get isOverGoal => _todayCalories > dailyGoal;

  /// Initialize the app state.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isFirstLaunch = !(await _db.userExists());

      if (!_isFirstLaunch) {
        _user = await _db.getUser();
        await _loadTodayEntries();
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Complete initial setup.
  Future<bool> completeSetup({
    required String name,
    required int dailyGoal,
    required String apiKey,
  }) async {
    try {
      // Save API key securely
      await _secureStorage.saveApiKey(apiKey);

      // Create user
      _user = User(
        name: name,
        dailyCalorieGoal: dailyGoal,
        createdAt: DateTime.now(),
      );
      await _db.saveUser(_user!);

      _isFirstLaunch = false;
      await _loadTodayEntries();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error completing setup: $e');
      return false;
    }
  }

  /// Update user profile.
  Future<bool> updateProfile({
    String? name,
    int? dailyGoal,
    String? apiKey,
  }) async {
    if (_user == null) return false;

    try {
      if (apiKey != null && apiKey.isNotEmpty) {
        await _secureStorage.saveApiKey(apiKey);
      }

      _user = _user!.copyWith(
        name: name ?? _user!.name,
        dailyCalorieGoal: dailyGoal ?? _user!.dailyCalorieGoal,
      );
      await _db.updateUser(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  /// Get the API key.
  Future<String?> getApiKey() async {
    return await _secureStorage.getApiKey();
  }

  /// Load today's entries.
  Future<void> _loadTodayEntries() async {
    final today = DateTime.now();
    _todayEntries = await _db.getEntriesForDate(today);
    _todayCalories = _todayEntries.fold(0, (sum, e) => sum + e.calories);
  }

  /// Refresh today's data.
  Future<void> refreshToday() async {
    await _loadTodayEntries();
    notifyListeners();
  }

  /// Add a new entry.
  Future<bool> addEntry({
    required String description,
    required int calories,
  }) async {
    try {
      final entry = Entry(
        description: description,
        calories: calories,
        timestamp: DateTime.now(),
      );
      await _db.addEntry(entry);
      await _loadTodayEntries();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding entry: $e');
      return false;
    }
  }

  /// Update an existing entry.
  Future<bool> updateEntry(Entry entry) async {
    try {
      await _db.updateEntry(entry);
      await _loadTodayEntries();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating entry: $e');
      return false;
    }
  }

  /// Delete an entry.
  Future<bool> deleteEntry(int id) async {
    try {
      await _db.deleteEntry(id);
      await _loadTodayEntries();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting entry: $e');
      return false;
    }
  }

  /// Get entries for a specific date.
  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    return await _db.getEntriesForDate(date);
  }

  /// Get daily totals for a week.
  Future<Map<DateTime, int>> getWeeklyTotals(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return await _db.getDailyTotalsForRange(weekStart, weekEnd);
  }

  /// Get all-time statistics.
  Future<Map<String, dynamic>> getStatistics() async {
    final totalEntries = await _db.getTotalEntryCount();
    final totalCalories = await _db.getTotalCalories();
    final firstDate = await _db.getFirstEntryDate();
    final entryDates = await _db.getAllEntryDates();

    // Calculate streaks
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    if (entryDates.isNotEmpty) {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Check if there's an entry today or yesterday for current streak
      DateTime? lastStreakDate;
      for (final date in entryDates) {
        final entryDate = DateTime(date.year, date.month, date.day);
        final diff = todayDate.difference(entryDate).inDays;

        if (diff == 0 || diff == 1) {
          if (lastStreakDate == null) {
            currentStreak = 1;
            lastStreakDate = entryDate;
          } else {
            final streakDiff = lastStreakDate.difference(entryDate).inDays;
            if (streakDiff == 1) {
              currentStreak++;
              lastStreakDate = entryDate;
            } else {
              break;
            }
          }
        } else if (lastStreakDate == null) {
          break;
        }
      }

      // Calculate longest streak
      DateTime? prevDate;
      for (final date in entryDates.reversed) {
        final entryDate = DateTime(date.year, date.month, date.day);
        if (prevDate == null) {
          tempStreak = 1;
        } else {
          final diff = entryDate.difference(prevDate).inDays;
          if (diff == 1) {
            tempStreak++;
          } else {
            longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
            tempStreak = 1;
          }
        }
        prevDate = entryDate;
      }
      longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
    }

    // Calculate average daily calories
    int avgDailyCalories = 0;
    if (firstDate != null && totalCalories > 0) {
      final daysSinceFirst =
          DateTime.now().difference(firstDate).inDays + 1;
      avgDailyCalories = (totalCalories / daysSinceFirst).round();
    }

    return {
      'totalEntries': totalEntries,
      'totalCalories': totalCalories,
      'avgDailyCalories': avgDailyCalories,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  /// Export all data as CSV string.
  Future<String> exportData() async {
    final entries = await _db.exportEntries();
    final buffer = StringBuffer();

    // CSV header
    buffer.writeln('Date,Time,Description,Calories');

    // CSV rows
    for (final entry in entries) {
      final timestamp = DateTime.parse(entry['timestamp'] as String);
      final date =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      final time =
          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
      final description =
          '"${(entry['description'] as String).replaceAll('"', '""')}"';
      final calories = entry['calories'];

      buffer.writeln('$date,$time,$description,$calories');
    }

    return buffer.toString();
  }

  /// Clear all data.
  Future<void> clearAllData() async {
    await _db.clearAllData();
    await _secureStorage.deleteAll();
    _user = null;
    _todayEntries = [];
    _todayCalories = 0;
    _isFirstLaunch = true;
    notifyListeners();
  }

  /// Import data from CSV string.
  /// Returns the number of entries imported, or -1 on error.
  Future<int> importData(String csvContent) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.isEmpty) return 0;

      int imported = 0;
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parsed = _parseCsvLine(line);
        if (parsed == null) continue;

        final date = parsed['date']!;
        final time = parsed['time']!;
        final description = parsed['description']!;
        final calories = int.tryParse(parsed['calories']!);

        if (calories == null || calories <= 0) continue;

        final dateParts = date.split('-');
        final timeParts = time.split(':');
        if (dateParts.length != 3 || timeParts.length != 2) continue;

        final timestamp = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        final entry = Entry(
          description: description,
          calories: calories,
          timestamp: timestamp,
        );

        await _db.addEntry(entry);
        imported++;
      }

      await _loadTodayEntries();
      notifyListeners();
      return imported;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return -1;
    }
  }

  /// Parse a CSV line handling quoted fields.
  Map<String, String>? _parseCsvLine(String line) {
    try {
      final values = <String>[];
      bool inQuotes = false;
      StringBuffer current = StringBuffer();

      for (int i = 0; i < line.length; i++) {
        final char = line[i];
        if (char == '"') {
          if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (char == ',' && !inQuotes) {
          values.add(current.toString());
          current = StringBuffer();
        } else {
          current.write(char);
        }
      }
      values.add(current.toString());

      if (values.length < 4) return null;

      return {
        'date': values[0],
        'time': values[1],
        'description': values[2],
        'calories': values[3],
      };
    } catch (e) {
      return null;
    }
  }
}
