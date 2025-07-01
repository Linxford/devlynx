import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

enum ThemeMode { system, light, dark, custom }

enum AccentColor {
  blue(Color(0xFF6366F1), 'Blue'),
  purple(Color(0xFF8B5CF6), 'Purple'),
  green(Color(0xFF10B981), 'Green'),
  orange(Color(0xFFF59E0B), 'Orange'),
  red(Color(0xFFEF4444), 'Red'),
  pink(Color(0xFFEC4899), 'Pink'),
  indigo(Color(0xFF6366F1), 'Indigo'),
  teal(Color(0xFF14B8A6), 'Teal');

  const AccentColor(this.color, this.name);
  final Color color;
  final String name;
}

class DevLynxSettings {
  final ThemeMode themeMode;
  final AccentColor accentColor;
  final List<String> projectDirectories;
  final bool enableVoiceCommands;
  final bool enableAIInsights;
  final bool enableAnalytics;
  final bool showWelcomeMessage;
  final String preferredTerminal;
  final String preferredEditor;
  final Map<String, String> customCommands;
  final bool enableSystemTray;
  final bool autoStartWithSystem;
  final double uiScale;
  final String language;
  final bool enableSounds;
  final bool enableNotifications;
  final List<String> recentProjects;
  final Map<String, dynamic> advanced;

  const DevLynxSettings({
    this.themeMode = ThemeMode.system,
    this.accentColor = AccentColor.blue,
    this.projectDirectories = const [],
    this.enableVoiceCommands = true,
    this.enableAIInsights = true,
    this.enableAnalytics = true,
    this.showWelcomeMessage = true,
    this.preferredTerminal = '',
    this.preferredEditor = '',
    this.customCommands = const {},
    this.enableSystemTray = false,
    this.autoStartWithSystem = false,
    this.uiScale = 1.0,
    this.language = 'en',
    this.enableSounds = true,
    this.enableNotifications = true,
    this.recentProjects = const [],
    this.advanced = const {},
  });

  DevLynxSettings copyWith({
    ThemeMode? themeMode,
    AccentColor? accentColor,
    List<String>? projectDirectories,
    bool? enableVoiceCommands,
    bool? enableAIInsights,
    bool? enableAnalytics,
    bool? showWelcomeMessage,
    String? preferredTerminal,
    String? preferredEditor,
    Map<String, String>? customCommands,
    bool? enableSystemTray,
    bool? autoStartWithSystem,
    double? uiScale,
    String? language,
    bool? enableSounds,
    bool? enableNotifications,
    List<String>? recentProjects,
    Map<String, dynamic>? advanced,
  }) {
    return DevLynxSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      projectDirectories: projectDirectories ?? this.projectDirectories,
      enableVoiceCommands: enableVoiceCommands ?? this.enableVoiceCommands,
      enableAIInsights: enableAIInsights ?? this.enableAIInsights,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      showWelcomeMessage: showWelcomeMessage ?? this.showWelcomeMessage,
      preferredTerminal: preferredTerminal ?? this.preferredTerminal,
      preferredEditor: preferredEditor ?? this.preferredEditor,
      customCommands: customCommands ?? this.customCommands,
      enableSystemTray: enableSystemTray ?? this.enableSystemTray,
      autoStartWithSystem: autoStartWithSystem ?? this.autoStartWithSystem,
      uiScale: uiScale ?? this.uiScale,
      language: language ?? this.language,
      enableSounds: enableSounds ?? this.enableSounds,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      recentProjects: recentProjects ?? this.recentProjects,
      advanced: advanced ?? this.advanced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'accentColor': accentColor.name,
      'projectDirectories': projectDirectories,
      'enableVoiceCommands': enableVoiceCommands,
      'enableAIInsights': enableAIInsights,
      'enableAnalytics': enableAnalytics,
      'showWelcomeMessage': showWelcomeMessage,
      'preferredTerminal': preferredTerminal,
      'preferredEditor': preferredEditor,
      'customCommands': customCommands,
      'enableSystemTray': enableSystemTray,
      'autoStartWithSystem': autoStartWithSystem,
      'uiScale': uiScale,
      'language': language,
      'enableSounds': enableSounds,
      'enableNotifications': enableNotifications,
      'recentProjects': recentProjects,
      'advanced': advanced,
    };
  }

  static DevLynxSettings fromJson(Map<String, dynamic> json) {
    return DevLynxSettings(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      accentColor: AccentColor.values.firstWhere(
        (e) => e.name == json['accentColor'],
        orElse: () => AccentColor.blue,
      ),
      projectDirectories: List<String>.from(json['projectDirectories'] ?? []),
      enableVoiceCommands: json['enableVoiceCommands'] ?? true,
      enableAIInsights: json['enableAIInsights'] ?? true,
      enableAnalytics: json['enableAnalytics'] ?? true,
      showWelcomeMessage: json['showWelcomeMessage'] ?? true,
      preferredTerminal: json['preferredTerminal'] ?? '',
      preferredEditor: json['preferredEditor'] ?? '',
      customCommands: Map<String, String>.from(json['customCommands'] ?? {}),
      enableSystemTray: json['enableSystemTray'] ?? false,
      autoStartWithSystem: json['autoStartWithSystem'] ?? false,
      uiScale: json['uiScale']?.toDouble() ?? 1.0,
      language: json['language'] ?? 'en',
      enableSounds: json['enableSounds'] ?? true,
      enableNotifications: json['enableNotifications'] ?? true,
      recentProjects: List<String>.from(json['recentProjects'] ?? []),
      advanced: Map<String, dynamic>.from(json['advanced'] ?? {}),
    );
  }
}

class SettingsManager {
  static DevLynxSettings _settings = const DevLynxSettings();
  static final List<VoidCallback> _listeners = [];

  static DevLynxSettings get settings => _settings;

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  static Future<void> initialize() async {
    await _loadSettings();
    await _detectProjectDirectories();
    await _detectPreferredApps();
  }

  static Future<void> _loadSettings() async {
    try {
      final configFile = await _getConfigFile();
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _settings = DevLynxSettings.fromJson(json);
      } else {
        // Create default settings
        _settings = _createDefaultSettings();
        await saveSettings();
      }
    } catch (e) {
      print('Error loading settings: $e');
      _settings = _createDefaultSettings();
    }
  }

  static DevLynxSettings _createDefaultSettings() {
    return DevLynxSettings(
      projectDirectories: _getDefaultProjectDirectories(),
      preferredTerminal: _getDefaultTerminal(),
      preferredEditor: _getDefaultEditor(),
    );
  }

  static Future<void> saveSettings() async {
    try {
      final configFile = await _getConfigFile();
      await configFile.parent.create(recursive: true);
      await configFile.writeAsString(jsonEncode(_settings.toJson()));
      _notifyListeners();
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  static Future<void> updateSettings(DevLynxSettings newSettings) async {
    _settings = newSettings;
    await saveSettings();
  }

  static Future<File> _getConfigFile() async {
    final homeDir = _getHomeDirectory();
    final configDir = Directory('$homeDir/.config/devlynx');
    return File('${configDir.path}/settings.json');
  }

  static String _getHomeDirectory() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? Directory.current.path;
    } else {
      return Platform.environment['HOME'] ?? Directory.current.path;
    }
  }

  static List<String> _getDefaultProjectDirectories() {
    final homeDir = _getHomeDirectory();
    final defaultDirs = <String>[];

    // Common project directories across platforms
    final commonDirs = [
      'Projects',
      'Code',
      'Development',
      'Dev',
      'Work',
      'GitHub',
      'Source',
      'Repositories',
      'Desktop/Projects',
      'Documents/Projects',
    ];

    for (final dir in commonDirs) {
      final fullPath = '$homeDir/$dir';
      if (Directory(fullPath).existsSync()) {
        defaultDirs.add(fullPath);
      }
    }

    // Platform-specific directories
    if (Platform.isWindows) {
      // Windows-specific directories
      final windowsDirs = [
        '${Platform.environment['USERPROFILE']}\\Source\\Repos',
        'C:\\Projects',
        'C:\\Code',
      ];
      for (final dir in windowsDirs) {
        if (Directory(dir).existsSync()) {
          defaultDirs.add(dir);
        }
      }
    } else if (Platform.isMacOS) {
      // macOS-specific directories
      final macDirs = [
        '$homeDir/Developer',
        '/Applications/Xcode.app',
      ];
      for (final dir in macDirs) {
        if (Directory(dir).existsSync()) {
          defaultDirs.add(dir);
        }
      }
    } else if (Platform.isLinux) {
      // Linux-specific directories
      final linuxDirs = [
        '/opt/projects',
        '/usr/local/src',
      ];
      for (final dir in linuxDirs) {
        if (Directory(dir).existsSync()) {
          defaultDirs.add(dir);
        }
      }
    }

    return defaultDirs.isNotEmpty ? defaultDirs : ['$homeDir/Projects'];
  }

  static Future<void> _detectProjectDirectories() async {
    if (_settings.projectDirectories.isEmpty) {
      final detected = await _scanForProjectDirectories();
      _settings = _settings.copyWith(projectDirectories: detected);
    }
  }

  static Future<List<String>> _scanForProjectDirectories() async {
    final homeDir = _getHomeDirectory();
    final foundDirs = <String>[];

    // Scan common directories
    final searchDirs = [
      homeDir,
      '$homeDir/Desktop',
      '$homeDir/Documents',
    ];

    for (final searchDir in searchDirs) {
      try {
        final dir = Directory(searchDir);
        if (!await dir.exists()) continue;

        await for (final entity in dir.list(recursive: false)) {
          if (entity is Directory) {
            if (await _containsProjects(entity.path)) {
              foundDirs.add(entity.path);
            }
          }
        }
      } catch (e) {
        // Ignore access errors
      }
    }

    return foundDirs;
  }

  static Future<bool> _containsProjects(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      var projectCount = 0;

      await for (final entity in dir.list(recursive: false)) {
        if (entity is Directory) {
          // Check for common project indicators
          final projectDir = Directory(entity.path);
          final files = <String>[];
          
          await for (final file in projectDir.list(recursive: false)) {
            if (file is File) {
              files.add(file.path.split(Platform.pathSeparator).last);
            }
          }

          // Check for project indicators
          if (files.any((f) => ['package.json', 'pubspec.yaml', 'Cargo.toml', 
                                'go.mod', 'requirements.txt', 'pom.xml', 
                                'build.gradle', '.git'].contains(f))) {
            projectCount++;
            if (projectCount >= 2) return true; // Found multiple projects
          }
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  static String _getDefaultTerminal() {
    if (Platform.isWindows) {
      // Check for Windows Terminal, PowerShell, or cmd
      final terminals = ['wt.exe', 'powershell.exe', 'cmd.exe'];
      for (final terminal in terminals) {
        if (_commandExists(terminal)) return terminal;
      }
      return 'cmd.exe';
    } else if (Platform.isMacOS) {
      return 'Terminal.app';
    } else {
      // Linux - check for common terminals
      final terminals = ['gnome-terminal', 'konsole', 'xterm', 'alacritty', 'kitty'];
      for (final terminal in terminals) {
        if (_commandExists(terminal)) return terminal;
      }
      return 'xterm';
    }
  }

  static String _getDefaultEditor() {
    final editors = ['code', 'cursor', 'subl', 'atom', 'vim', 'nano'];
    for (final editor in editors) {
      if (_commandExists(editor)) return editor;
    }
    return Platform.isWindows ? 'notepad.exe' : 'nano';
  }

  static bool _commandExists(String command) {
    try {
      final result = Process.runSync(
        Platform.isWindows ? 'where' : 'which',
        [command],
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _detectPreferredApps() async {
    if (_settings.preferredTerminal.isEmpty || _settings.preferredEditor.isEmpty) {
      final terminal = _settings.preferredTerminal.isEmpty 
          ? _getDefaultTerminal() 
          : _settings.preferredTerminal;
      final editor = _settings.preferredEditor.isEmpty 
          ? _getDefaultEditor() 
          : _settings.preferredEditor;

      _settings = _settings.copyWith(
        preferredTerminal: terminal,
        preferredEditor: editor,
      );
    }
  }

  // Utility methods for themes
  static ColorScheme getLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: _settings.accentColor.color,
      brightness: Brightness.light,
    );
  }

  static ColorScheme getDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: _settings.accentColor.color,
      brightness: Brightness.dark,
    );
  }

  // Project directory management
  static Future<void> addProjectDirectory(String path) async {
    final dirs = List<String>.from(_settings.projectDirectories);
    if (!dirs.contains(path)) {
      dirs.add(path);
      await updateSettings(_settings.copyWith(projectDirectories: dirs));
    }
  }

  static Future<void> removeProjectDirectory(String path) async {
    final dirs = List<String>.from(_settings.projectDirectories);
    dirs.remove(path);
    await updateSettings(_settings.copyWith(projectDirectories: dirs));
  }

  // Recent projects management
  static Future<void> addRecentProject(String path) async {
    final recent = List<String>.from(_settings.recentProjects);
    recent.remove(path); // Remove if already exists
    recent.insert(0, path); // Add to beginning
    if (recent.length > 10) recent.removeLast(); // Keep only 10 recent

    await updateSettings(_settings.copyWith(recentProjects: recent));
  }
}
