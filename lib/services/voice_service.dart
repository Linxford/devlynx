import 'dart:async';
import 'dart:io';
import 'ai_service.dart';

class VoiceService {
  static bool _isListening = false;
  static bool _isInitialized = false;
  static StreamController<String>? _speechController;
  static StreamController<VoiceCommand>? _commandController;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Always use fallback initialization for Linux
      await _initializeFallback();
    } catch (e) {
      print('Voice service initialization error: $e');
      _isInitialized = false;
    }
  }

  static Future<void> _initializeFallback() async {
    try {
      // Initialize controllers for basic functionality
      _speechController = StreamController<String>.broadcast();
      _commandController = StreamController<VoiceCommand>.broadcast();
      
      // Check if TTS is available on Linux
      if (Platform.isLinux) {
        try {
          // Check for espeak-ng or speech-dispatcher
          final result = await Process.run('which', ['espeak-ng']);
          if (result.exitCode == 0) {
            _isInitialized = true;
            print('Voice service initialized with espeak-ng fallback');
            return;
          }
          
          final result2 = await Process.run('which', ['espeak']);
          if (result2.exitCode == 0) {
            _isInitialized = true;
            print('Voice service initialized with espeak fallback');
            return;
          }
          
          final result3 = await Process.run('which', ['spd-say']);
          if (result3.exitCode == 0) {
            _isInitialized = true;
            print('Voice service initialized with speech-dispatcher fallback');
            return;
          }
        } catch (e) {
          print('TTS not available: $e');
        }
      }
      
      // Basic initialization without TTS
      _isInitialized = true;
      print('Voice service initialized in limited mode (no TTS available)');
    } catch (e) {
      print('Fallback voice service initialization failed: $e');
      _isInitialized = false;
    }
  }

  static Future<bool> startListening() async {
    if (!_isInitialized || _isListening) return false;

    // For Linux, we don't have speech recognition yet
    // This is a placeholder for future implementation
    print('Voice recognition not available on Linux yet');
    return false;
  }

  static Future<bool> stopListening() async {
    if (!_isInitialized || !_isListening) return false;

    _isListening = false;
    return true;
  }

  static Future<bool> speak(String text) async {
    if (!_isInitialized) return false;

    try {
      // Use espeak-ng on Linux
      if (Platform.isLinux) {
        try {
          final result = await Process.run('espeak-ng', [text]);
          return result.exitCode == 0;
        } catch (e) {
          // Try espeak as fallback
          try {
            final result = await Process.run('espeak', [text]);
            return result.exitCode == 0;
          } catch (e2) {
            // Try speech-dispatcher as final fallback
            try {
              final result = await Process.run('spd-say', [text]);
              return result.exitCode == 0;
            } catch (e3) {
              print('TTS not available: espeak-ng, espeak, and spd-say not found');
            }
          }
        }
      }
      print('Text-to-speech not available for this platform');
      return false;
    } catch (e) {
      print('Text-to-speech error: $e');
      return false;
    }
  }

  // Method to manually trigger voice commands for testing
  static Future<void> simulateVoiceCommand(String text) async {
    if (!_isInitialized) return;
    
    _speechController?.add(text);
    await _processVoiceCommand(text);
  }

  static Stream<String> get speechStream =>
      _speechController?.stream ?? Stream.empty();
  static Stream<VoiceCommand> get commandStream =>
      _commandController?.stream ?? Stream.empty();
  static bool get isListening => _isListening;
  static bool get isInitialized => _isInitialized;

  static Future<void> _processVoiceCommand(String text) async {
    final command = _parseVoiceCommand(text.toLowerCase());
    if (command != null) {
      _commandController?.add(command);
      await _executeVoiceCommand(command);
    }
  }

  static VoiceCommand? _parseVoiceCommand(String text) {
    // Remove common wake words
    text = text.replaceAll(RegExp(r'\b(hey|hi|devlynx|okay|ok)\b'), '').trim();

    // Project commands
    if (text.contains('open') || text.contains('launch')) {
      final projectMatch = RegExp(
        r'(?:open|launch)\s+(.+?)(?:\s+project)?$',
      ).firstMatch(text);
      if (projectMatch != null) {
        return VoiceCommand(
          type: VoiceCommandType.openProject,
          parameter: projectMatch.group(1)?.trim(),
          originalText: text,
        );
      }
    }

    // Tool commands
    if (text.contains('run') || text.contains('execute')) {
      final commandMatch = RegExp(r'(?:run|execute)\s+(.+)$').firstMatch(text);
      if (commandMatch != null) {
        return VoiceCommand(
          type: VoiceCommandType.runCommand,
          parameter: commandMatch.group(1)?.trim(),
          originalText: text,
        );
      }
    }

    // Information commands
    if (text.contains('show') ||
        text.contains('display') ||
        text.contains('list')) {
      if (text.contains('project')) {
        return VoiceCommand(
          type: VoiceCommandType.showProjects,
          originalText: text,
        );
      }
      if (text.contains('tool')) {
        return VoiceCommand(
          type: VoiceCommandType.showTools,
          originalText: text,
        );
      }
      if (text.contains('stat') || text.contains('analytic')) {
        return VoiceCommand(
          type: VoiceCommandType.showStats,
          originalText: text,
        );
      }
    }

    // AI commands
    if (text.contains('suggest') ||
        text.contains('recommend') ||
        text.contains('what should')) {
      return VoiceCommand(
        type: VoiceCommandType.getSuggestion,
        originalText: text,
      );
    }

    // Navigation commands
    if (text.contains('go to') ||
        text.contains('switch to') ||
        text.contains('navigate')) {
      if (text.contains('project')) {
        return VoiceCommand(
          type: VoiceCommandType.showProjects,
          originalText: text,
        );
      }
      if (text.contains('tool')) {
        return VoiceCommand(
          type: VoiceCommandType.showTools,
          originalText: text,
        );
      }
    }

    // Help commands
    if (text.contains('help') ||
        text.contains('how to') ||
        text.contains('what can')) {
      return VoiceCommand(type: VoiceCommandType.help, originalText: text);
    }

    return null;
  }

  static Future<void> _executeVoiceCommand(VoiceCommand command) async {
    try {
      switch (command.type) {
        case VoiceCommandType.openProject:
          await _handleOpenProject(command.parameter);
          break;
        case VoiceCommandType.runCommand:
          await _handleRunCommand(command.parameter);
          break;
        case VoiceCommandType.getSuggestion:
          await _handleGetSuggestion();
          break;
        case VoiceCommandType.help:
          await _handleHelp();
          break;
        default:
          await speak(
            "I understood '${command.originalText}' but I'm not sure how to help with that yet.",
          );
      }
    } catch (e) {
      print('Error executing voice command: $e');
      await speak(
        "Sorry, I encountered an error while processing your request.",
      );
    }
  }

  static Future<void> _handleOpenProject(String? projectName) async {
    if (projectName == null) {
      await speak("Which project would you like me to open?");
      return;
    }

    // This would need to be connected to the main app state
    await speak("Opening $projectName project");
  }

  static Future<void> _handleRunCommand(String? command) async {
    if (command == null) {
      await speak("What command would you like me to run?");
      return;
    }

    await speak("Running $command");
    // Execute the command
    try {
      await Process.run('bash', ['-c', command]);
      await speak("Command completed successfully");
    } catch (e) {
      await speak("Command failed to execute");
    }
  }

  static Future<void> _handleGetSuggestion() async {
    await speak("Let me think about what you should work on today");

    try {
      final suggestions = await AIService.generateDailyRecommendations();
      if (suggestions.isNotEmpty) {
        await speak(suggestions.first);
      }
    } catch (e) {
      await speak(
        "I suggest continuing work on your most recent project. You're doing great!",
      );
    }
  }

  static Future<void> _handleHelp() async {
    const helpText = '''
I can help you with several commands:
- "Open [project name]" to launch a project
- "Run [command]" to execute terminal commands
- "Show projects" to see your projects
- "Show tools" to see available tools
- "Get suggestion" for AI recommendations
- "Show stats" for productivity analytics
    ''';

    await speak(helpText);
  }

  static List<String> getAvailableCommands() {
    return [
      "Open [project name]",
      "Launch [project name]",
      "Run [command]",
      "Execute [command]",
      "Show projects",
      "List projects",
      "Show tools",
      "Display tools",
      "Show stats",
      "Get suggestion",
      "What should I work on?",
      "Help",
      "What can you do?",
    ];
  }

  static void dispose() {
    _speechController?.close();
    _commandController?.close();
    _speechController = null;
    _commandController = null;
    _isInitialized = false;
    _isListening = false;
  }
}

enum VoiceCommandType {
  openProject,
  runCommand,
  showProjects,
  showTools,
  showStats,
  getSuggestion,
  help,
}

class VoiceCommand {
  final VoiceCommandType type;
  final String? parameter;
  final String originalText;

  VoiceCommand({
    required this.type,
    this.parameter,
    required this.originalText,
  });

  @override
  String toString() {
    return 'VoiceCommand(type: $type, parameter: $parameter, originalText: $originalText)';
  }
}
