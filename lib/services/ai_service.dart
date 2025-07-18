import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../data/project_scanner.dart';
import '../data/analytics_manager.dart';

enum AIProvider { openai, anthropic, ollama, groq, gemini, openrouter }

class AIConfiguration {
  final AIProvider provider;
  final String apiKey;
  final String? baseUrl;
  final String model;

  const AIConfiguration({
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    required this.model,
  });

  static const Map<AIProvider, AIConfiguration> defaultConfigs = {
    AIProvider.openai: AIConfiguration(
      provider: AIProvider.openai,
      apiKey: '',
      model: 'gpt-4o-mini',
    ),
    AIProvider.anthropic: AIConfiguration(
      provider: AIProvider.anthropic,
      apiKey: '',
      model: 'claude-3-5-haiku-20241022',
    ),
    AIProvider.ollama: AIConfiguration(
      provider: AIProvider.ollama,
      apiKey: '',
      baseUrl: 'http://localhost:11434',
      model: 'llama3.2:latest',
    ),
    AIProvider.groq: AIConfiguration(
      provider: AIProvider.groq,
      apiKey: '',
      baseUrl: 'https://api.groq.com/openai/v1',
      model: 'llama-3.1-8b-instant',
    ),
    AIProvider.gemini: AIConfiguration(
      provider: AIProvider.gemini,
      apiKey: '',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      model: 'gemini-1.5-flash',
    ),
    AIProvider.openrouter: AIConfiguration(
      provider: AIProvider.openrouter,
      apiKey: '',
      baseUrl: 'https://openrouter.ai/api/v1',
      model: 'anthropic/claude-3.5-sonnet',
    ),
  };
}

class AIService {
  static AIConfiguration? _currentConfig;
  static final Map<AIProvider, bool> _providerAvailability = {};
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _checkProviderAvailability();
    await _loadConfiguration();
    _isInitialized = true;
  }

  static Future<void> _checkProviderAvailability() async {
    // Check Ollama (local)
    _providerAvailability[AIProvider.ollama] = await _checkOllamaAvailability();

    // Check other providers based on API keys
    final config = await loadStoredConfiguration();
    for (final provider in AIProvider.values) {
      if (provider == AIProvider.ollama) continue;

      final apiKey = config['${provider.name}_api_key'] as String?;
      _providerAvailability[provider] = apiKey?.isNotEmpty == true;
      
      // If we have a valid API key, this provider is available
      if (apiKey?.isNotEmpty == true) {
        print('Found API key for ${provider.name}, marking as available');
      }
    }
  }

  static Future<bool> _checkOllamaAvailability() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://localhost:11434/api/tags'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> loadStoredConfiguration() async {
    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      final configFile = File('$homeDir/.config/devlynx/ai_config.json');

      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        return json.decode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      // Ignore errors, use defaults
    }

    return {};
  }

  static Future<void> _loadConfiguration() async {
    final config = await loadStoredConfiguration();

    // Find the first available provider with configuration
    for (final provider in AIProvider.values) {
      final apiKey = config['${provider.name}_api_key'] as String? ?? '';
      final model = config['${provider.name}_model'] as String? ?? 
                   AIConfiguration.defaultConfigs[provider]?.model ?? '';
      
      // For Ollama, we don't need an API key
      // For other providers, we need a valid API key
      bool hasValidConfig = provider == AIProvider.ollama 
          ? _providerAvailability[provider] == true
          : apiKey.isNotEmpty;
      
      if (hasValidConfig && model.isNotEmpty) {
        _currentConfig = AIConfiguration(
          provider: provider,
          apiKey: apiKey,
          baseUrl: AIConfiguration.defaultConfigs[provider]?.baseUrl,
          model: model,
        );
        print('Loaded configuration for ${provider.name} with model: $model');
        break;
      }
    }
    
    if (_currentConfig == null) {
      print('No valid AI configuration found. Please configure an AI provider.');
    }
  }

  static Future<void> saveConfiguration(AIConfiguration config) async {
    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      final configDir = Directory('$homeDir/.config/devlynx');
      await configDir.create(recursive: true);

      final configFile = File('${configDir.path}/ai_config.json');
      final currentConfig = await loadStoredConfiguration();

      currentConfig['${config.provider.name}_api_key'] = config.apiKey;
      currentConfig['${config.provider.name}_model'] = config.model;
      if (config.baseUrl != null) {
        currentConfig['${config.provider.name}_base_url'] = config.baseUrl;
      }

      await configFile.writeAsString(json.encode(currentConfig));
      _currentConfig = config;
      _providerAvailability[config.provider] = config.apiKey.isNotEmpty;
    } catch (e) {
      throw AIException('Failed to save configuration: $e');
    }
  }

  static bool get isConfigured => _currentConfig != null;
  static AIProvider? get currentProvider => _currentConfig?.provider;
  static Map<AIProvider, bool> get providerAvailability =>
      Map.unmodifiable(_providerAvailability);

  static Future<List<String>> generateProjectInsights(Project project) async {
    if (!isConfigured) return ['Configure AI to get insights'];

    try {
      final prompt =
          '''
Analyze this ${_getProjectTypeDisplayName(project.type)} project and provide 2-3 brief insights:

Project: ${project.name}
Type: ${_getProjectTypeDisplayName(project.type)}
Technologies: ${project.technologies.join(', ')}
Last Modified: ${project.lastModified}

Provide insights as a JSON array of strings, each insight should be 5-8 words max.
Focus on: development suggestions, optimization tips, or technology recommendations.

Example format: ["Add unit tests", "Consider TypeScript migration", "Optimize bundle size"]
''';

      final response = await _makeAIRequest(prompt);
      final insights = _parseJsonResponse(response) as List<dynamic>?;

      return insights?.cast<String>().take(3).toList() ??
          _getFallbackInsights(project.type);
    } catch (e) {
      return _getFallbackInsights(project.type);
    }
  }

  static Future<List<String>> generateQuickActions(Project project) async {
    if (!isConfigured) return _getDefaultQuickActions(project.type);

    try {
      final prompt =
          '''
Generate 4-6 quick actions for this ${_getProjectTypeDisplayName(project.type)} project:

Project: ${project.name}
Type: ${_getProjectTypeDisplayName(project.type)}
Technologies: ${project.technologies.join(', ')}

Provide actions as a JSON array of strings. Each action should be:
- 2-4 words max
- Actionable commands
- Relevant to the project type

Example: ["Run Tests", "Build Project", "Install Deps", "Start Dev Server", "Format Code", "Git Status"]
''';

      final response = await _makeAIRequest(prompt);
      final actions = _parseJsonResponse(response) as List<dynamic>?;

      return actions?.cast<String>().take(6).toList() ??
          _getDefaultQuickActions(project.type);
    } catch (e) {
      return _getDefaultQuickActions(project.type);
    }
  }

  static Future<String> generateProjectSummary(Project project) async {
    if (!isConfigured) return 'AI not configured';

    try {
      final analytics = await AnalyticsManager.getProjectAnalytics(
        project.path,
      );

      final prompt =
          '''
Create a brief summary for this developer about their project:

Project: ${project.name}
Type: ${_getProjectTypeDisplayName(project.type)}
Technologies: ${project.technologies.join(', ')}
Last Modified: ${project.lastModified}
Recent Activity: ${analytics['recent_launches'] ?? 0} launches this week

Provide a 1-2 sentence summary that's encouraging and informative.
Focus on recent activity, project potential, or development suggestions.
''';

      final response = await _makeAIRequest(prompt);
      return response.trim();
    } catch (e) {
      return 'This ${_getProjectTypeDisplayName(project.type)} project shows great potential for development.';
    }
  }

  static Future<List<String>> generateDailyRecommendations() async {
    if (!isConfigured) return ['Configure AI for recommendations'];

    try {
      final analytics = await AnalyticsManager.getAnalyticsSummary();

      final prompt =
          '''
Based on this developer's activity, provide 3-4 daily recommendations:

Total Projects: ${analytics['total_projects']}
Sessions Today: ${analytics['sessions_today']}
Commands Today: ${analytics['commands_today']}
Average Session Time: ${analytics['avg_session_time']} hours
Top Tools: ${(analytics['top_tools'] as Map<String, dynamic>).keys.take(3).join(', ')}

Provide recommendations as a JSON array of strings.
Each recommendation should be actionable and encouraging.
Focus on: productivity, learning, project management, or development practices.

Example: ["Review yesterday's code", "Try a new debugging technique", "Update project documentation"]
''';

      final response = await _makeAIRequest(prompt);
      final recommendations = _parseJsonResponse(response) as List<dynamic>?;

      return recommendations?.cast<String>().take(4).toList() ??
          [
            'Start with your most active project',
            'Review recent changes',
            'Update documentation',
            'Plan today\'s coding goals',
          ];
    } catch (e) {
      return [
        'Start with your most active project',
        'Review recent changes',
        'Update documentation',
        'Plan today\'s coding goals',
      ];
    }
  }

  static Future<String> _makeAIRequest(String prompt) async {
    if (_currentConfig == null) {
      throw AIException('AI not configured');
    }

    switch (_currentConfig!.provider) {
      case AIProvider.openai:
        return await _makeOpenAIRequest(prompt);
      case AIProvider.anthropic:
        return await _makeAnthropicRequest(prompt);
      case AIProvider.ollama:
        return await _makeOllamaRequest(prompt);
      case AIProvider.groq:
        return await _makeGroqRequest(prompt);
      case AIProvider.gemini:
        return await _makeGeminiRequest(prompt);
      case AIProvider.openrouter:
        return await _makeOpenRouterRequest(prompt);
    }
  }

  static Future<String> _makeOpenAIRequest(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${_currentConfig!.apiKey}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': _currentConfig!.model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 300,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw AIException('OpenAI API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  static Future<String> _makeAnthropicRequest(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': _currentConfig!.apiKey,
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
      },
      body: json.encode({
        'model': _currentConfig!.model,
        'max_tokens': 300,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw AIException('Anthropic API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return data['content'][0]['text'] as String;
  }

  static Future<String> _makeOllamaRequest(String prompt) async {
    final response = await http.post(
      Uri.parse('${_currentConfig!.baseUrl}/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'model': _currentConfig!.model,
        'prompt': prompt,
        'stream': false,
      }),
    );

    if (response.statusCode != 200) {
      throw AIException('Ollama API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return data['response'] as String;
  }

  static Future<String> _makeGroqRequest(String prompt) async {
    final response = await http.post(
      Uri.parse('${_currentConfig!.baseUrl}/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${_currentConfig!.apiKey}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': _currentConfig!.model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 300,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw AIException('Groq API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  static Future<String> _makeGeminiRequest(String prompt) async {
    final response = await http.post(
      Uri.parse(
        '${_currentConfig!.baseUrl}/models/${_currentConfig!.model}:generateContent?key=${_currentConfig!.apiKey}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw AIException('Gemini API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  static Future<String> _makeOpenRouterRequest(String prompt) async {
    final response = await http.post(
      Uri.parse('${_currentConfig!.baseUrl}/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${_currentConfig!.apiKey}',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://devlynx.dev',
        'X-Title': 'DevLynx AI Assistant',
      },
      body: json.encode({
        'model': _currentConfig!.model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 300,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw AIException('OpenRouter API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  static dynamic _parseJsonResponse(String response) {
    try {
      // Try to extract JSON from the response
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']');

      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = response.substring(jsonStart, jsonEnd + 1);
        return json.decode(jsonStr);
      }

      // Try parsing the entire response as JSON
      return json.decode(response);
    } catch (e) {
      return null;
    }
  }

  static String _getProjectTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'flutter':
        return 'Flutter';
      case 'react':
        return 'React';
      case 'vue':
        return 'Vue.js';
      case 'angular':
        return 'Angular';
      case 'node':
      case 'nodejs':
        return 'Node.js';
      case 'python':
        return 'Python';
      case 'rust':
        return 'Rust';
      case 'go':
        return 'Go';
      case 'java':
        return 'Java';
      case 'cpp':
        return 'C++';
      case 'docker':
        return 'Docker';
      case 'nextjs':
        return 'Next.js';
      case 'svelte':
        return 'Svelte';
      default:
        return type.toUpperCase();
    }
  }

  static List<String> _getFallbackInsights(String type) {
    switch (type.toLowerCase()) {
      case 'flutter':
        return [
          'Add widget tests',
          'Optimize build size',
          'Use state management',
        ];
      case 'react':
        return ['Add prop types', 'Optimize renders', 'Use React hooks'];
      case 'vue':
        return ['Add TypeScript', 'Use composition API', 'Optimize bundle'];
      case 'angular':
        return [
          'Add unit tests',
          'Use lazy loading',
          'Optimize change detection',
        ];
      case 'python':
        return ['Add type hints', 'Use virtual env', 'Add documentation'];
      case 'rust':
        return [
          'Add integration tests',
          'Use clippy lints',
          'Optimize performance',
        ];
      case 'go':
        return ['Add benchmarks', 'Use go modules', 'Add error handling'];
      default:
        return ['Add documentation', 'Improve code structure', 'Add tests'];
    }
  }

  static List<String> _getDefaultQuickActions(String type) {
    switch (type.toLowerCase()) {
      case 'flutter':
        return [
          'Run App',
          'Hot Reload',
          'Build APK',
          'Run Tests',
          'Clean Build',
          'Pub Get',
        ];
      case 'react':
      case 'vue':
      case 'angular':
        return [
          'Start Dev',
          'Build Prod',
          'Run Tests',
          'Install Deps',
          'Lint Code',
          'Format',
        ];
      case 'python':
        return [
          'Run Script',
          'Install Deps',
          'Run Tests',
          'Format Code',
          'Type Check',
          'Lint',
        ];
      case 'rust':
        return [
          'Cargo Run',
          'Cargo Build',
          'Cargo Test',
          'Cargo Check',
          'Format',
          'Clippy',
        ];
      case 'go':
        return ['Go Run', 'Go Build', 'Go Test', 'Go Mod', 'Format', 'Vet'];
      default:
        return [
          'Open Terminal',
          'Open Editor',
          'Git Status',
          'Build',
          'Test',
          'Format',
        ];
    }
  }

  /// Process a query from the user and return an AI response
  static Future<String> processQuery(String query, [List<Project>? projects]) async {
    if (!isConfigured) {
      return 'AI is not configured yet. Please set up your API key in the settings.';
    }

    try {
      final prompt = '''
You are DevLynx, an AI assistant for developers. Answer this query based on the context:

User Query: $query

Available Projects: ${projects?.map((p) => '${p.name} (${p.type})').join(', ') ?? 'None'}

Provide a helpful, concise response (max 2-3 sentences). Be encouraging and actionable.
''';

      final response = await _makeAIRequest(prompt);
      return response.trim();
    } catch (e) {
      // Fallback to rule-based responses
      return _generateFallbackResponse(query, projects);
    }
  }

  /// Generate workflow suggestions based on current projects
  static Future<List<String>> generateWorkflowSuggestions(List<Project> projects) async {
    if (!isConfigured) {
      return _getDefaultWorkflowSuggestions(projects);
    }

    try {
      final prompt = '''
Generate 5 workflow suggestions for a developer with these projects:

${projects.map((p) => '- ${p.name} (${p.type})').join('\n')}

Provide suggestions as a JSON array of strings. Each suggestion should be:
- 3-5 words max
- Actionable
- Relevant to their current projects

Example: ["Continue React project", "Update dependencies", "Write unit tests", "Review code quality", "Plan next features"]
''';

      final response = await _makeAIRequest(prompt);
      final suggestions = _parseJsonResponse(response) as List<dynamic>?;
      
      return suggestions?.cast<String>().take(5).toList() ?? 
          _getDefaultWorkflowSuggestions(projects);
    } catch (e) {
      return _getDefaultWorkflowSuggestions(projects);
    }
  }

  static String _generateFallbackResponse(String query, List<Project>? projects) {
    final queryLower = query.toLowerCase();
    
    if (queryLower.contains('project') || queryLower.contains('work on')) {
      if (projects != null && projects.isNotEmpty) {
        final projectNames = projects.take(3).map((p) => p.name).join(', ');
        return 'Based on your current projects ($projectNames), I\'d suggest focusing on the one with the most recent activity. Would you like me to help you prioritize?';
      }
      return 'You have several interesting projects! Let me help you choose which one to work on today.';
    }
    
    if (queryLower.contains('help') || queryLower.contains('assist')) {
      return 'I\'m here to help with your development workflow! I can suggest projects to work on, help with productivity insights, or provide technical guidance.';
    }
    
    if (queryLower.contains('productivity') || queryLower.contains('workflow')) {
      return 'To boost your productivity, consider: 1) Setting focused work sessions, 2) Using the Pomodoro technique, 3) Regularly committing your progress, and 4) Taking breaks between coding sessions.';
    }
    
    if (queryLower.contains('suggest') || queryLower.contains('recommend')) {
      return 'Based on your development patterns, I recommend: Focus on one project at a time, keep your dependencies updated, and maintain good documentation.';
    }
    
    return 'That\'s a great question! I\'m here to help with your development workflow and project management.';
  }

  static List<String> _getDefaultWorkflowSuggestions(List<Project> projects) {
    if (projects.isEmpty) {
      return [
        'Create your first project',
        'Set up development environment',
        'Explore project templates',
        'Learn a new technology',
        'Plan your coding goals',
      ];
    }
    
    final suggestions = <String>[];
    
    // Add project-specific suggestions
    for (final project in projects.take(2)) {
      suggestions.add('Continue ${project.name}');
    }
    
    // Add general suggestions
    suggestions.addAll([
      'Review recent commits',
      'Update dependencies',
      'Write documentation',
      'Run tests',
      'Backup your work',
    ]);
    
    return suggestions.take(5).toList();
  }
}

class AIException implements Exception {
  final String message;
  const AIException(this.message);

  @override
  String toString() => 'AIException: $message';
}
