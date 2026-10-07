import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String profileBoxName = 'user_profile';
  static const String settingsBoxName = 'app_settings';
  static const String historyBoxName = 'conversation_history';
  static const String progressBoxName = 'progress_metrics';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(profileBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox(historyBoxName);
    await Hive.openBox(progressBoxName);
  }

  // --- Profile Box Operations ---
  static Box get _profileBox => Hive.box(profileBoxName);

  static String? getUserName() {
    return _profileBox.get('name') as String?;
  }

  static Future<void> saveUserName(String name) async {
    await _profileBox.put('name', name);
    await _profileBox.put('join_date', DateTime.now().toIso8601String());
    await _profileBox.put('streak', 1);
    await _profileBox.put('last_active', DateTime.now().toIso8601String());
    await _profileBox.put('total_sessions', 0);
  }

  static int getStreak() {
    return _profileBox.get('streak', defaultValue: 0) as int;
  }

  static Future<void> updateStreakAndActivity() async {
    final now = DateTime.now();
    final lastActiveStr = _profileBox.get('last_active') as String?;
    if (lastActiveStr == null) {
      await _profileBox.put('streak', 1);
      await _profileBox.put('last_active', now.toIso8601String());
      return;
    }

    final lastActive = DateTime.parse(lastActiveStr);
    final today = DateTime(now.year, now.month, now.day);
    final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
    final difference = today.difference(lastActiveDay).inDays;

    if (difference == 1) {
      final currentStreak = getStreak();
      await _profileBox.put('streak', currentStreak + 1);
    } else if (difference > 1) {
      await _profileBox.put('streak', 1);
    }
    await _profileBox.put('last_active', now.toIso8601String());
  }

  static int getTotalSessions() {
    return _profileBox.get('total_sessions', defaultValue: 0) as int;
  }

  static Future<void> incrementTotalSessions() async {
    final current = getTotalSessions();
    await _profileBox.put('total_sessions', current + 1);
  }

  // --- Settings Box (Limit & Reminders) ---
  static Box get _settingsBox => Hive.box(settingsBoxName);

  static int getUsedTurnsToday() {
    _checkDailyLimitReset();
    return _settingsBox.get('turns_used_today', defaultValue: 0) as int;
  }

  static Future<void> incrementUsedTurns() async {
    final current = getUsedTurnsToday();
    await _settingsBox.put('turns_used_today', current + 1);
    await _settingsBox.put('last_turn_timestamp', DateTime.now().toIso8601String());
  }

  static String getReminderTime() {
    return _settingsBox.get('reminder_time', defaultValue: '20:00') as String;
  }

  static Future<void> saveReminderTime(String time) async {
    await _settingsBox.put('reminder_time', time);
  }

  static String getDifficultyLevel() {
    return _settingsBox.get('difficulty_level', defaultValue: 'Beginner') as String;
  }

  static Future<void> saveDifficultyLevel(String level) async {
    await _settingsBox.put('difficulty_level', level);
  }

  static void _checkDailyLimitReset() {
    final lastTurnStr = _settingsBox.get('last_turn_timestamp') as String?;
    if (lastTurnStr == null) return;

    final lastTurn = DateTime.parse(lastTurnStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastTurnDay = DateTime(lastTurn.year, lastTurn.month, lastTurn.day);

    if (today.difference(lastTurnDay).inDays >= 1) {
      _settingsBox.put('turns_used_today', 0);
    }
  }

  // --- History Box Operations ---
  static Box get _historyBox => Hive.box(historyBoxName);

  static List<Map<dynamic, dynamic>> getSessionsList() {
    final list = _historyBox.get('sessions', defaultValue: []) as List;
    return list.cast<Map<dynamic, dynamic>>();
  }

  static Future<void> saveSession(String topic, List<Map<String, dynamic>> turns) async {
    final sessions = getSessionsList();
    final newSession = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'topic': topic,
      'date': DateTime.now().toIso8601String(),
      'turns': turns,
    };
    sessions.insert(0, newSession);
    await _historyBox.put('sessions', sessions);
    await incrementTotalSessions();
  }

  // --- Progress Box Operations ---
  static Box get _progressBox => Hive.box(progressBoxName);

  static List<Map<dynamic, dynamic>> getProgressMetrics() {
    final list = _progressBox.get('daily_scores', defaultValue: []) as List;
    return list.cast<Map<dynamic, dynamic>>();
  }

  static Future<void> saveDailyMetric(double grammar, double fluency, double confidence) async {
    final metrics = getProgressMetrics();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd

    int existingIndex = metrics.indexWhere((m) => m['date'] == todayStr);

    if (existingIndex != -1) {
      final existing = metrics[existingIndex];
      final count = (existing['count'] ?? 1) as int;
      metrics[existingIndex] = {
        'date': todayStr,
        'grammar': ((existing['grammar'] * count) + grammar) / (count + 1),
        'fluency': ((existing['fluency'] * count) + fluency) / (count + 1),
        'confidence': ((existing['confidence'] * count) + confidence) / (count + 1),
        'count': count + 1,
      };
    } else {
      metrics.add({
        'date': todayStr,
        'grammar': grammar,
        'fluency': fluency,
        'confidence': confidence,
        'count': 1,
      });
    }
    await _progressBox.put('daily_scores', metrics);
  }

  // --- Clear Data ---
  static Future<void> clearAll() async {
    await _profileBox.clear();
    await _settingsBox.clear();
    await _historyBox.clear();
    await _progressBox.clear();
  }

  static Future<void> clearAllExceptTurns() async {
    final turnsUsed = _settingsBox.get('turns_used_today');
    final lastTurn = _settingsBox.get('last_turn_timestamp');

    await _profileBox.clear();
    await _settingsBox.clear();
    await _historyBox.clear();
    await _progressBox.clear();

    if (turnsUsed != null) {
      await _settingsBox.put('turns_used_today', turnsUsed);
    }
    if (lastTurn != null) {
      await _settingsBox.put('last_turn_timestamp', lastTurn);
    }
  }
}
