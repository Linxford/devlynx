import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class AnalyticsManager {
  static const String _analyticsFile = 'analytics.json';
  static const String _sessionsFile = 'sessions.json';

  static Future<String> get _configDir async {
    final homeDir = Platform.environment['HOME'] ?? '';
    final configPath = path.join(homeDir, '.config', 'devlynx');
    await Directory(configPath).create(recursive: true);
    return configPath;
  }

  // Track project launch
  static Future<void> trackProjectLaunch(
    String projectPath,
    String projectType,
  ) async {
    final analytics = await _loadAnalytics();
    final today = DateTime.now().toIso8601String().split('T')[0];

    analytics['project_launches'] ??= {};
    analytics['project_launches'][today] ??= {};
    analytics['project_launches'][today][projectPath] = {
      'type': projectType,
      'timestamp': DateTime.now().toIso8601String(),
      'count':
          (analytics['project_launches'][today][projectPath]?['count'] ?? 0) +
          1,
    };

    await _saveAnalytics(analytics);
  }

  // Track session start
  static Future<void> startSession() async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final session = {
      'id': sessionId,
      'start_time': DateTime.now().toIso8601String(),
      'projects_opened': [],
      'tools_used': [],
      'commands_executed': [],
    };

    final sessions = await _loadSessions();
    sessions[sessionId] = session;
    await _saveSessions(sessions);
  }

  // Track tool usage
  static Future<void> trackToolUsage(String toolName, String version) async {
    final analytics = await _loadAnalytics();
    final today = DateTime.now().toIso8601String().split('T')[0];

    analytics['tool_usage'] ??= {};
    analytics['tool_usage'][today] ??= {};
    analytics['tool_usage'][today][toolName] = {
      'version': version,
      'count': (analytics['tool_usage'][today][toolName]?['count'] ?? 0) + 1,
      'last_used': DateTime.now().toIso8601String(),
    };

    await _saveAnalytics(analytics);
  }

  // Track command execution
  static Future<void> trackCommand(String command, String projectPath) async {
    final analytics = await _loadAnalytics();
    final today = DateTime.now().toIso8601String().split('T')[0];

    analytics['commands'] ??= {};
    analytics['commands'][today] ??= [];
    analytics['commands'][today].add({
      'command': command,
      'project': projectPath,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _saveAnalytics(analytics);
  }

  // Get productivity stats
  static Future<ProductivityStats> getProductivityStats() async {
    final analytics = await _loadAnalytics();
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    final yesterday = now
        .subtract(Duration(days: 1))
        .toIso8601String()
        .split('T')[0];
    final weekAgo = now
        .subtract(Duration(days: 7))
        .toIso8601String()
        .split('T')[0];

    // Calculate daily stats
    final todayLaunches = _countLaunches(analytics, today);
    final yesterdayLaunches = _countLaunches(analytics, yesterday);
    final weeklyLaunches = _countLaunchesInRange(analytics, weekAgo, today);

    // Calculate tool usage
    final toolStats = _getToolStats(analytics);

    // Calculate project stats
    final projectStats = _getProjectStats(analytics);

    // Calculate streaks
    final streak = _calculateStreak(analytics);

    return ProductivityStats(
      dailyLaunches: todayLaunches,
      weeklyLaunches: weeklyLaunches,
      launchTrend: todayLaunches - yesterdayLaunches,
      mostUsedTools: toolStats,
      favoriteProjects: projectStats,
      currentStreak: streak,
      totalProjects: projectStats.length,
      avgSessionTime: await _getAverageSessionTime(),
    );
  }

  // Get time-based analytics
  static Future<Map<String, dynamic>> getTimeAnalytics() async {
    final analytics = await _loadAnalytics();
    final sessions = await _loadSessions();

    return {
      'daily_activity': _getDailyActivity(analytics),
      'weekly_summary': _getWeeklySummary(analytics),
      'session_duration': _getSessionDurations(sessions),
      'peak_hours': _getPeakHours(analytics),
    };
  }

  // Helper methods
  static Future<Map<String, dynamic>> _loadAnalytics() async {
    try {
      final configDir = await _configDir;
      final file = File(path.join(configDir, _analyticsFile));
      if (await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content);
      }
    } catch (e) {
      print('Error loading analytics: $e');
    }
    return {};
  }

  static Future<void> _saveAnalytics(Map<String, dynamic> analytics) async {
    try {
      final configDir = await _configDir;
      final file = File(path.join(configDir, _analyticsFile));
      await file.writeAsString(json.encode(analytics));
    } catch (e) {
      print('Error saving analytics: $e');
    }
  }

  static Future<Map<String, dynamic>> _loadSessions() async {
    try {
      final configDir = await _configDir;
      final file = File(path.join(configDir, _sessionsFile));
      if (await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content);
      }
    } catch (e) {
      print('Error loading sessions: $e');
    }
    return {};
  }

  static Future<void> _saveSessions(Map<String, dynamic> sessions) async {
    try {
      final configDir = await _configDir;
      final file = File(path.join(configDir, _sessionsFile));
      await file.writeAsString(json.encode(sessions));
    } catch (e) {
      print('Error saving sessions: $e');
    }
  }

  static int _countLaunches(Map<String, dynamic> analytics, String date) {
    final launches = analytics['project_launches']?[date] ?? {};
    return launches.values.fold(
      0,
      (sum, project) => sum + (project['count'] ?? 0),
    );
  }

  static int _countLaunchesInRange(
    Map<String, dynamic> analytics,
    String startDate,
    String endDate,
  ) {
    final launches = analytics['project_launches'] ?? {};
    int total = 0;

    for (String date in launches.keys) {
      if (date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0) {
        total += _countLaunches(analytics, date);
      }
    }

    return total;
  }

  static List<ToolStat> _getToolStats(Map<String, dynamic> analytics) {
    final toolUsage = analytics['tool_usage'] ?? {};
    final Map<String, int> toolCounts = {};

    for (var dayData in toolUsage.values) {
      for (var entry in dayData.entries) {
        toolCounts[entry.key] =
            (toolCounts[entry.key] ?? 0) + ((entry.value['count'] ?? 0) as int);
      }
    }

    final sortedTools = toolCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTools
        .take(5)
        .map(
          (e) => ToolStat(
            name: e.key,
            usage: e.value,
            trend: _getToolTrend(analytics, e.key),
          ),
        )
        .toList();
  }

  static List<ProjectStat> _getProjectStats(Map<String, dynamic> analytics) {
    final projectLaunches = analytics['project_launches'] ?? {};
    final Map<String, int> projectCounts = {};

    for (var dayData in projectLaunches.values) {
      for (var entry in dayData.entries) {
        projectCounts[entry.key] =
            (projectCounts[entry.key] ?? 0) +
            ((entry.value['count'] ?? 0) as int);
      }
    }

    final sortedProjects = projectCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedProjects
        .take(5)
        .map(
          (e) => ProjectStat(
            path: e.key,
            launches: e.value,
            name: path.basename(e.key),
          ),
        )
        .toList();
  }

  static int _calculateStreak(Map<String, dynamic> analytics) {
    final launches = analytics['project_launches'] ?? {};
    final sortedDates = launches.keys.toList()..sort();

    if (sortedDates.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now().toIso8601String().split('T')[0];
    DateTime currentDate = DateTime.parse(today);

    while (true) {
      final dateStr = currentDate.toIso8601String().split('T')[0];
      if (launches.containsKey(dateStr) &&
          _countLaunches(analytics, dateStr) > 0) {
        streak++;
        currentDate = currentDate.subtract(Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  static Future<double> _getAverageSessionTime() async {
    final sessions = await _loadSessions();
    if (sessions.isEmpty) return 0.0;

    double totalMinutes = 0;
    int completedSessions = 0;

    for (var session in sessions.values) {
      if (session['end_time'] != null) {
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);
        totalMinutes += end.difference(start).inMinutes.toDouble();
        completedSessions++;
      }
    }

    return completedSessions > 0 ? totalMinutes / completedSessions : 0.0;
  }

  static double _getToolTrend(Map<String, dynamic> analytics, String toolName) {
    final toolUsage = analytics['tool_usage'] ?? {};
    final dates = toolUsage.keys.toList()..sort();

    if (dates.length < 2) return 0.0;

    final recent = dates.takeLast(7);
    final previous = dates.length > 7
        ? dates.skip(dates.length - 14).take(7)
        : [];

    double recentUsage = 0;
    double previousUsage = 0;

    for (String date in recent) {
      recentUsage += (toolUsage[date]?[toolName]?['count'] ?? 0).toDouble();
    }

    for (String date in previous) {
      previousUsage += (toolUsage[date]?[toolName]?['count'] ?? 0).toDouble();
    }

    if (previousUsage == 0) return recentUsage > 0 ? 100.0 : 0.0;
    return ((recentUsage - previousUsage) / previousUsage) * 100;
  }

  static Map<String, int> _getDailyActivity(Map<String, dynamic> analytics) {
    final launches = analytics['project_launches'] ?? {};
    final Map<String, int> dailyActivity = {};

    for (var entry in launches.entries) {
      dailyActivity[entry.key] = _countLaunches(analytics, entry.key);
    }

    return dailyActivity;
  }

  static Map<String, dynamic> _getWeeklySummary(
    Map<String, dynamic> analytics,
  ) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    int totalLaunches = 0;
    int activeDays = 0;

    for (int i = 0; i < 7; i++) {
      final date = weekStart
          .add(Duration(days: i))
          .toIso8601String()
          .split('T')[0];
      final launches = _countLaunches(analytics, date);
      totalLaunches += launches;
      if (launches > 0) activeDays++;
    }

    return {
      'total_launches': totalLaunches,
      'active_days': activeDays,
      'avg_daily_launches': activeDays > 0 ? totalLaunches / activeDays : 0.0,
    };
  }

  static Map<String, double> _getSessionDurations(
    Map<String, dynamic> sessions,
  ) {
    final Map<String, List<double>> dailyDurations = {};

    for (var session in sessions.values) {
      if (session['end_time'] != null) {
        final start = DateTime.parse(session['start_time']);
        final end = DateTime.parse(session['end_time']);
        final date = start.toIso8601String().split('T')[0];
        final duration = end.difference(start).inMinutes.toDouble();

        dailyDurations[date] ??= [];
        dailyDurations[date]!.add(duration);
      }
    }

    final Map<String, double> avgDurations = {};
    for (var entry in dailyDurations.entries) {
      avgDurations[entry.key] =
          entry.value.reduce((a, b) => a + b) / entry.value.length;
    }

    return avgDurations;
  }

  static Map<int, int> _getPeakHours(Map<String, dynamic> analytics) {
    final launches = analytics['project_launches'] ?? {};
    final Map<int, int> hourCounts = {};

    for (var dayData in launches.values) {
      for (var projectData in dayData.values) {
        final timestamp = DateTime.parse(projectData['timestamp']);
        final hour = timestamp.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }

    return hourCounts;
  }

  static Future<Map<String, dynamic>> getProjectAnalytics(
    String projectPath,
  ) async {
    final analytics = await _loadAnalytics();
    final projectLaunches =
        analytics['project_launches'] as Map<String, dynamic>? ?? {};

    int recentLaunches = 0;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    for (var entry in projectLaunches.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date != null && date.isAfter(weekAgo)) {
        final dayData = entry.value as Map<String, dynamic>? ?? {};
        for (var projectEntry in dayData.entries) {
          if (projectEntry.key == projectPath) {
            recentLaunches += ((projectEntry.value['count'] ?? 0) as int);
          }
        }
      }
    }

    return {'recent_launches': recentLaunches, 'project_path': projectPath};
  }

  static Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final analytics = await _loadAnalytics();
    final sessions = await _loadSessions();

    // Calculate totals
    final projectLaunches =
        analytics['project_launches'] as Map<String, dynamic>? ?? {};
    final toolUsage = analytics['tool_usage'] as Map<String, dynamic>? ?? {};
    final commands = analytics['commands'] as Map<String, dynamic>? ?? {};

    int totalProjects = 0;
    int totalCommands = 0;
    final projectCounts = <String, int>{};
    final toolCounts = <String, int>{};

    // Count project launches
    for (var dayData in projectLaunches.values) {
      if (dayData is Map<String, dynamic>) {
        for (var entry in dayData.entries) {
          projectCounts[entry.key] =
              (projectCounts[entry.key] ?? 0) +
              ((entry.value['count'] ?? 0) as int);
        }
      }
    }
    totalProjects = projectCounts.length;

    // Count tool usage
    for (var dayData in toolUsage.values) {
      if (dayData is Map<String, dynamic>) {
        for (var entry in dayData.entries) {
          toolCounts[entry.key] =
              (toolCounts[entry.key] ?? 0) +
              ((entry.value['count'] ?? 0) as int);
        }
      }
    }

    // Count commands
    for (var dayData in commands.values) {
      if (dayData is Map<String, dynamic>) {
        totalCommands += dayData.length;
      }
    }

    // Calculate session metrics
    int totalSessions = sessions.length;
    double avgSessionTime = 0;
    int sessionsToday = 0;
    int commandsToday = 0;

    final today = DateTime.now().toIso8601String().split('T')[0];

    if (sessions.isNotEmpty) {
      double totalMinutes = 0;
      int completedSessions = 0;

      for (var session in sessions.values) {
        final start = DateTime.parse(session['start_time']);
        final endTime = session['end_time'];

        if (endTime != null) {
          final end = DateTime.parse(endTime);
          totalMinutes += end.difference(start).inMinutes.toDouble();
          completedSessions++;
        }

        // Count today's sessions
        if (start.toIso8601String().split('T')[0] == today) {
          sessionsToday++;
        }
      }

      if (completedSessions > 0) {
        avgSessionTime =
            totalMinutes / completedSessions / 60; // Convert to hours
      }
    }

    // Count today's commands
    final todayCommands = commands[today] as Map<String, dynamic>? ?? {};
    commandsToday = todayCommands.length;

    // Generate daily activity data for chart
    final dailyActivity = <String, int>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now
          .subtract(Duration(days: i))
          .toIso8601String()
          .split('T')[0];
      int dayActivity = 0;

      // Count project launches for the day
      final dayProjects = projectLaunches[date] as Map<String, dynamic>? ?? {};
      for (var project in dayProjects.values) {
        if (project is Map<String, dynamic>) {
          dayActivity += (project['count'] ?? 0) as int;
        }
      }

      // Count tool usage for the day
      final dayTools = toolUsage[date] as Map<String, dynamic>? ?? {};
      for (var tool in dayTools.values) {
        if (tool is Map<String, dynamic>) {
          dayActivity += (tool['count'] ?? 0) as int;
        }
      }

      dailyActivity[date] = dayActivity;
    }

    // Generate AI insights
    final insights = <String>[];

    if (totalProjects > 0) {
      final topProject = projectCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      insights.add(
        'Your most active project is ${topProject.key} with ${topProject.value} launches',
      );
    }

    if (toolCounts.isNotEmpty) {
      final topTool = toolCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      insights.add(
        '${topTool.key} is your most used tool with ${topTool.value} uses',
      );
    }

    if (avgSessionTime > 0) {
      if (avgSessionTime > 4) {
        insights.add(
          'You have long coding sessions averaging ${avgSessionTime.toStringAsFixed(1)} hours',
        );
      } else if (avgSessionTime < 1) {
        insights.add(
          'You prefer short focused sessions averaging ${(avgSessionTime * 60).toStringAsFixed(0)} minutes',
        );
      }
    }

    if (sessionsToday > 5) {
      insights.add(
        'High activity day! You\'ve had $sessionsToday coding sessions today',
      );
    }

    return {
      'total_projects': totalProjects,
      'total_sessions': totalSessions,
      'avg_session_time': avgSessionTime,
      'total_commands': totalCommands,
      'sessions_today': sessionsToday,
      'commands_today': commandsToday,
      'projects_growth': 0, // Could calculate week-over-week growth
      'daily_activity': dailyActivity,
      'insights': insights,
      'top_projects': projectCounts,
      'top_tools': toolCounts,
    };
  }
}

class ProductivityStats {
  final int dailyLaunches;
  final int weeklyLaunches;
  final int launchTrend;
  final List<ToolStat> mostUsedTools;
  final List<ProjectStat> favoriteProjects;
  final int currentStreak;
  final int totalProjects;
  final double avgSessionTime;

  ProductivityStats({
    required this.dailyLaunches,
    required this.weeklyLaunches,
    required this.launchTrend,
    required this.mostUsedTools,
    required this.favoriteProjects,
    required this.currentStreak,
    required this.totalProjects,
    required this.avgSessionTime,
  });
}

class ToolStat {
  final String name;
  final int usage;
  final double trend;

  ToolStat({required this.name, required this.usage, required this.trend});
}

class ProjectStat {
  final String path;
  final String name;
  final int launches;

  ProjectStat({required this.path, required this.name, required this.launches});
}
