import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/startup_screen.dart';
import 'data/project_scanner.dart';
import 'data/tool_detector.dart';
import 'data/session_storage.dart';
import 'services/launcher_service.dart';
import 'dart:io';
import 'utils/error_logger.dart';
import 'ui/widgets/error_toast.dart';
import 'services/voice_service.dart';
import 'services/ai_service.dart';
import 'data/analytics_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorLogger.setupGlobalHandlers(); // ✅ install global error handler

  String getHomeDir() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? Directory.current.path;
    } else {
      // Linux, macOS, others
      return Platform.environment['HOME'] ?? Directory.current.path;
    }
  }

  final homeDir = getHomeDir();

  // Scan projects and detect tools in parallel
  final projectsFuture = scanProjects([
    '$homeDir/Projects',
    '$homeDir/Desktop/Projects',
  ]);

  final toolsFuture = detectDetailedTools();
  final sessionFuture = SessionStorage().loadSession();

  // Wait for all operations to complete
  final results = await Future.wait([
    projectsFuture,
    toolsFuture,
    sessionFuture,
  ]);

  final projects = results[0] as List<Project>;
  final detailedTools = results[1] as List<DetectedTool>;
  final session = results[2] as SessionData?;

  // Extract simple tool names for backward compatibility
  final tools = detailedTools.map((tool) => tool.name).toList();

  // Initialize AI service
  await AIService.initialize();

  // Start analytics session
  await AnalyticsManager.startSession();

  // Initialize voice service
  await VoiceService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<List<Project>>(create: (_) => projects),
        Provider<List<String>>(create: (_) => tools),
        Provider<List<DetectedTool>>(create: (_) => detailedTools),
        Provider<SessionData?>(create: (_) => session),
        Provider<LauncherService>(create: (_) => LauncherService()),
      ],
      child: const DevLynxApp(),
    ),
  );
}

class DevLynxApp extends StatelessWidget {
  const DevLynxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevLynx Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: true,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey[600],
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: Color(0xFF6366F1), width: 3),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const StartupScreen(),
      builder: (context, child) {
        return Stack(
          children: [child ?? const SizedBox.shrink(), const ErrorToast()],
        );
      },
    );
  }
}
