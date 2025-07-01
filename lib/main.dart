import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/startup_screen.dart';
import 'data/project_scanner.dart';
import 'data/tool_detector.dart';
import 'data/session_storage.dart';
import 'services/launcher_service.dart';
import 'utils/error_logger.dart';
import 'ui/widgets/error_toast.dart';
import 'services/voice_service.dart';
import 'services/ai_service.dart';
import 'data/analytics_manager.dart';
import 'data/settings_manager.dart' as settings_manager;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorLogger.setupGlobalHandlers();

  // Initialize settings first
  await settings_manager.SettingsManager.initialize();

  // Get project directories from settings
  final projectDirectories = settings_manager.SettingsManager.settings.projectDirectories;

  // Scan projects and detect tools in parallel
  final projectsFuture = scanProjects(projectDirectories);
  final toolsFuture = detectDetailedTools();
  final sessionFuture = SessionStorage().loadSession();

  // Initialize services
  final servicesFuture = Future.wait([
    AIService.initialize(),
    VoiceService.initialize(),
    AnalyticsManager.startSession(),
  ]);

  // Wait for all operations to complete
  final results = await Future.wait([
    projectsFuture,
    toolsFuture,
    sessionFuture,
    servicesFuture,
  ]);

  final projects = results[0] as List<Project>;
  final detailedTools = results[1] as List<DetectedTool>;
  final session = results[2] as SessionData?;

  // Extract simple tool names for backward compatibility
  final tools = detailedTools.map((tool) => tool.name).toList();

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

class DevLynxApp extends StatefulWidget {
  const DevLynxApp({super.key});

  @override
  State<DevLynxApp> createState() => _DevLynxAppState();
}

class _DevLynxAppState extends State<DevLynxApp> {
  @override
  void initState() {
    super.initState();
    settings_manager.SettingsManager.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    settings_manager.SettingsManager.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = settings_manager.SettingsManager.settings;
    final lightColorScheme = settings_manager.SettingsManager.getLightColorScheme();
    final darkColorScheme = settings_manager.SettingsManager.getDarkColorScheme();

    return MaterialApp(
      title: 'DevLynx Assistant',
      debugShowCheckedModeBanner: false,
      themeMode: _getFlutterThemeMode(settings.themeMode),
      theme: _buildThemeData(lightColorScheme, settings.uiScale),
      darkTheme: _buildThemeData(darkColorScheme, settings.uiScale),
      home: const StartupScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.uiScale),
          ),
          child: Stack(
            children: [child ?? const SizedBox.shrink(), const ErrorToast()],
          ),
        );
      },
    );
  }

  ThemeData _buildThemeData(ColorScheme colorScheme, double uiScale) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'Inter',
      visualDensity: VisualDensity(
        horizontal: (uiScale - 1.0) * 2,
        vertical: (uiScale - 1.0) * 2,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
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
          padding: EdgeInsets.symmetric(
            horizontal: 24 * uiScale,
            vertical: 12 * uiScale,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24 * uiScale,
            vertical: 12 * uiScale,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * uiScale,
          vertical: 12 * uiScale,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colorScheme.primary, width: 3),
        ),
      ),
    );
  }

  ThemeMode _getFlutterThemeMode(settings_manager.ThemeMode themeMode) {
    switch (themeMode) {
      case settings_manager.ThemeMode.light:
        return ThemeMode.light;
      case settings_manager.ThemeMode.dark:
        return ThemeMode.dark;
      case settings_manager.ThemeMode.system:
      case settings_manager.ThemeMode.custom:
        return ThemeMode.system;
    }
  }
}
