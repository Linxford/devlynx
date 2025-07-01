import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/ai_service.dart';
import '../../data/project_scanner.dart';
import '../screens/ai_configuration_screen.dart';

class AIAssistantPanel extends StatefulWidget {
  final List<Project> projects;
  
  const AIAssistantPanel({
    super.key,
    required this.projects,
  });

  @override
  State<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends State<AIAssistantPanel>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _queryController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  final String _currentSuggestion = '';
  List<String> _quickSuggestions = [];

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _initializeAssistant();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _initializeAssistant() async {
    // Check if AI is configured
    if (!AIService.isConfigured) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Welcome! I'm your DevLynx AI assistant, but I need to be configured first. Please set up your AI provider to start getting intelligent insights and suggestions.",
          isUser: false,
          timestamp: DateTime.now(),
          needsConfiguration: true,
        ));
      });
      return;
    }
    
    // Generate initial suggestions
    await _generateSuggestions();
    
    // Add welcome message
    setState(() {
      _messages.add(ChatMessage(
        text: "Hello! I'm your DevLynx AI assistant. I can help you with project insights, suggestions, and development tasks. What would you like to work on today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _generateSuggestions() async {
    if (widget.projects.isEmpty) return;
    
    try {
      final suggestions = await AIService.generateWorkflowSuggestions(widget.projects);
      if (mounted) {
        setState(() {
          _quickSuggestions = suggestions;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
    });

    _queryController.clear();

    try {
      final response = await AIService.processQuery(message, widget.projects);
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "I apologize, but I encountered an error processing your request. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isMobile = screenSize.width < 600;

    return Container(
      height: isMobile ? screenSize.height * 0.8 : screenSize.height * 0.7,
      constraints: BoxConstraints(
        maxWidth: isTablet ? 800 : double.infinity,
        minHeight: 400,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withValues(alpha: 0.95),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              _buildHeader(colorScheme),
              if (!isMobile) _buildQuickSuggestions(colorScheme),
              Expanded(child: _buildChatArea(colorScheme)),
              _buildInputArea(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primaryContainer.withOpacity(0.2),
          ],
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.8),
                        colorScheme.primary.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text('🤖', style: TextStyle(fontSize: 20)),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Your intelligent development companion',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions(ColorScheme colorScheme) {
    if (_quickSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Suggestions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.take(3).map((suggestion) {
              return Tooltip(
                message: 'Send: $suggestion',
                child: ActionChip(
                  avatar: const Text('💡', style: TextStyle(fontSize: 12)),
                  label: Text(
                    suggestion,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () => _sendMessage(suggestion),
                  backgroundColor: colorScheme.primaryContainer.withOpacity(0.4),
                  side: BorderSide(
                    color: colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                  elevation: 2,
                  shadowColor: colorScheme.primary.withOpacity(0.2),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageBubble(message, colorScheme);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ColorScheme colorScheme) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🤖',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser 
                    ? colorScheme.primary 
                    : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (message.needsConfiguration) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AIConfigurationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Configure AI'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '👤',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Ask me anything about your projects...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: _isProcessing ? 'Processing...' : 'Send message',
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FloatingActionButton.small(
                heroTag: "ai_send_fab",
                onPressed: _isProcessing 
                    ? null 
                    : () => _sendMessage(_queryController.text),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: _isProcessing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '🚀',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool needsConfiguration;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.needsConfiguration = false,
  });
}
