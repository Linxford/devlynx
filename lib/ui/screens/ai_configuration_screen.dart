import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ai_service.dart';

class AIConfigurationScreen extends StatefulWidget {
  const AIConfigurationScreen({super.key});

  @override
  State<AIConfigurationScreen> createState() => _AIConfigurationScreenState();
}

class _AIConfigurationScreenState extends State<AIConfigurationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Map<AIProvider, TextEditingController> _apiKeyControllers = {};
  final Map<AIProvider, TextEditingController> _modelControllers = {};
  final Map<AIProvider, bool> _isLoading = {};
  final Map<AIProvider, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AIProvider.values.length,
      vsync: this,
    );

    // Initialize controllers
    for (final provider in AIProvider.values) {
      _apiKeyControllers[provider] = TextEditingController();
      _modelControllers[provider] = TextEditingController(
        text: AIConfiguration.defaultConfigs[provider]?.model ?? '',
      );
      _isLoading[provider] = false;
      _errors[provider] = null;
    }

    _loadCurrentConfiguration();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _apiKeyControllers.values) {
      controller.dispose();
    }
    for (final controller in _modelControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCurrentConfiguration() async {
    // Load existing configuration if available
    try {
      // Load configuration from storage - implement this method
      final config = <String, dynamic>{};
      for (final provider in AIProvider.values) {
        final apiKey = config['${provider.name}_api_key'] as String? ?? '';
        final model =
            config['${provider.name}_model'] as String? ??
            AIConfiguration.defaultConfigs[provider]?.model ??
            '';

        _apiKeyControllers[provider]?.text = apiKey;
        _modelControllers[provider]?.text = model;
      }

      if (mounted) setState(() {});
    } catch (e) {
      // Handle configuration loading error
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Configuration'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: AIProvider.values.map((provider) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getProviderIcon(provider),
                  const SizedBox(width: 8),
                  Text(_getProviderDisplayName(provider)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: AIProvider.values.map((provider) {
          return _buildProviderConfiguration(provider, colorScheme);
        }).toList(),
      ),
    );
  }

  Widget _buildProviderConfiguration(
    AIProvider provider,
    ColorScheme colorScheme,
  ) {
    final isAvailable = AIService.providerAvailability[provider] ?? false;
    final isCurrentProvider = AIService.currentProvider == provider;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getProviderColor(provider).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _getProviderIcon(provider, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getProviderDisplayName(provider),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getProviderDescription(provider),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAvailable ? 'Available' : 'Configure',
                        style: TextStyle(
                          color: isAvailable ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (isCurrentProvider) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Configuration Form
          _buildConfigurationForm(provider, colorScheme),

          const SizedBox(height: 24),

          // Test Connection Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading[provider] == true
                  ? null
                  : () => _testConnection(provider),
              icon: _isLoading[provider] == true
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.connect_without_contact),
              label: Text(
                _isLoading[provider] == true
                    ? 'Testing Connection...'
                    : 'Test Connection',
              ),
            ),
          ),

          if (_errors[provider] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errors[provider]!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Provider-specific Information
          _buildProviderInfo(provider, colorScheme),
        ],
      ),
    );
  }

  Widget _buildConfigurationForm(AIProvider provider, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // API Key Field
        if (provider != AIProvider.ollama) ...[
          Text(
            'API Key',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _apiKeyControllers[provider],
            obscureText: true,
            decoration: InputDecoration(
              hintText:
                  'Enter your ${_getProviderDisplayName(provider)} API key',
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _apiKeyControllers[provider]?.text = data!.text!;
                  }
                },
                tooltip: 'Paste from clipboard',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Model Field
        Text(
          'Model',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _modelControllers[provider],
          decoration: InputDecoration(
            hintText:
                'e.g., ${AIConfiguration.defaultConfigs[provider]?.model}',
            prefixIcon: const Icon(Icons.memory),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderInfo(AIProvider provider, ColorScheme colorScheme) {
    final info = _getProviderInfo(provider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Provider Information',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...info.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection(AIProvider provider) async {
    setState(() {
      _isLoading[provider] = true;
      _errors[provider] = null;
    });

    try {
      final apiKey = _apiKeyControllers[provider]?.text ?? '';
      final model = _modelControllers[provider]?.text ?? '';

      if (provider != AIProvider.ollama && apiKey.isEmpty) {
        throw Exception('API key is required');
      }

      if (model.isEmpty) {
        throw Exception('Model is required');
      }

      final config = AIConfiguration(
        provider: provider,
        apiKey: apiKey,
        baseUrl: AIConfiguration.defaultConfigs[provider]?.baseUrl,
        model: model,
      );

      await AIService.saveConfiguration(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Connection successful! ${_getProviderDisplayName(provider)} is now configured.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errors[provider] = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading[provider] = false;
        });
      }
    }
  }

  Widget _getProviderIcon(AIProvider provider, {double size = 24}) {
    switch (provider) {
      case AIProvider.openai:
        return Icon(
          Icons.psychology,
          size: size,
          color: const Color(0xFF00A67E),
        );
      case AIProvider.anthropic:
        return Icon(
          Icons.smart_toy,
          size: size,
          color: const Color(0xFFE97627),
        );
      case AIProvider.ollama:
        return Icon(Icons.computer, size: size, color: const Color(0xFF6366F1));
      case AIProvider.groq:
        return Icon(Icons.flash_on, size: size, color: const Color(0xFFF55036));
      case AIProvider.gemini:
        return Icon(
          Icons.auto_awesome,
          size: size,
          color: const Color(0xFF4285F4),
        );
    }
  }

  Color _getProviderColor(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return const Color(0xFF00A67E);
      case AIProvider.anthropic:
        return const Color(0xFFE97627);
      case AIProvider.ollama:
        return const Color(0xFF6366F1);
      case AIProvider.groq:
        return const Color(0xFFF55036);
      case AIProvider.gemini:
        return const Color(0xFF4285F4);
    }
  }

  String _getProviderDisplayName(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'OpenAI';
      case AIProvider.anthropic:
        return 'Anthropic';
      case AIProvider.ollama:
        return 'Ollama';
      case AIProvider.groq:
        return 'Groq';
      case AIProvider.gemini:
        return 'Google Gemini';
    }
  }

  String _getProviderDescription(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'GPT-4 and GPT-3.5 models for advanced AI assistance';
      case AIProvider.anthropic:
        return 'Claude models for helpful, harmless, and honest AI';
      case AIProvider.ollama:
        return 'Local AI models running on your machine';
      case AIProvider.groq:
        return 'Ultra-fast inference with Llama and Mixtral models';
      case AIProvider.gemini:
        return 'Google\'s multimodal AI for text and code generation';
    }
  }

  List<String> _getProviderInfo(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return [
          'Get your API key from platform.openai.com',
          'Supports GPT-4, GPT-4-turbo, and GPT-3.5-turbo models',
          'Requires active billing account',
          'Best for: General AI assistance and code generation',
        ];
      case AIProvider.anthropic:
        return [
          'Get your API key from console.anthropic.com',
          'Supports Claude-3 models (Haiku, Sonnet, Opus)',
          'Known for safety and helpfulness',
          'Best for: Detailed analysis and thoughtful responses',
        ];
      case AIProvider.ollama:
        return [
          'Install Ollama locally: ollama.com',
          'No API key required - runs entirely offline',
          'Download models with: ollama pull llama3.2',
          'Best for: Privacy and offline development',
        ];
      case AIProvider.groq:
        return [
          'Get your API key from console.groq.com',
          'Ultra-fast inference speeds',
          'Supports Llama, Mixtral, and Gemma models',
          'Best for: Quick responses and real-time assistance',
        ];
      case AIProvider.gemini:
        return [
          'Get your API key from makersuite.google.com',
          'Supports Gemini Pro and Gemini Pro Vision',
          'Free tier available with rate limits',
          'Best for: Multimodal tasks and code understanding',
        ];
    }
  }
}
