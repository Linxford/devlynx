import 'package:flutter/material.dart';
import 'dart:ui';
import '../../data/project_scanner.dart';
import '../../data/analytics_manager.dart';
import '../../services/ai_service.dart';

class ModernProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onNotesPressed;

  const ModernProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onNotesPressed,
  });

  @override
  State<ModernProjectCard> createState() => _ModernProjectCardState();
}

class _ModernProjectCardState extends State<ModernProjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;
  List<String> _insights = [];
  List<String> _quickActions = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Ensure animations don't produce NaN values
    _animationController.addListener(() {
      if (_animationController.value.isNaN) {
        _animationController.reset();
      }
    });

    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    final insights = await AIService.generateProjectInsights(widget.project);
    final actions = await AIService.generateQuickActions(widget.project);

    if (mounted) {
      setState(() {
        _insights = insights;
        _quickActions = actions;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Tooltip(
          message: 'Open ${widget.project.name} (${_getProjectTypeDisplayName(widget.project.type)})',
          child: Transform.scale(
            scale: _scaleAnimation.value.isNaN ? 1.0 : _scaleAnimation.value,
            child: MouseRegion(
              onEnter: (_) => _onHover(true),
              onExit: (_) => _onHover(false),
              child: GestureDetector(
                onTap: () {
                  AnalyticsManager.trackProjectLaunch(
                    widget.project.path,
                    widget.project.type,
                  );
                  widget.onTap();
                },
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 160,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: _elevationAnimation.value.isNaN ? 2.0 : _elevationAnimation.value,
                        offset: Offset(0, (_elevationAnimation.value.isNaN ? 2.0 : _elevationAnimation.value) / 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.surface.withValues(alpha: 0.9),
                              colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                            ],
                          ),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildCardContent(context, colorScheme),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(colorScheme),
          const SizedBox(height: 6),
          Expanded(
            child: _buildProjectInfo(colorScheme),
          ),
          const SizedBox(height: 6),
          _buildFooter(colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getProjectTypeColor(
                  widget.project.type,
                ).withValues(alpha: 0.8),
                _getProjectTypeColor(
                  widget.project.type,
                ).withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _getProjectTypeColor(
                  widget.project.type,
                ).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getProjectTypeIcon(widget.project.type),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.project.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getProjectTypeDisplayName(widget.project.type),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _buildActionButtons(colorScheme),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onNotesPressed != null)
          Tooltip(
            message: 'Add or edit project notes',
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: widget.onNotesPressed,
                icon: const Text('📝', style: TextStyle(fontSize: 14)),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ),
          ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Quick actions for ${widget.project.name}',
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: PopupMenuButton<String>(
              onSelected: _handleQuickAction,
              icon: const Text('⚙️', style: TextStyle(fontSize: 14)),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: '',
              itemBuilder: (context) => _quickActions.map((action) {
                return PopupMenuItem(
                  value: action,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getActionEmoji(action), style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(action, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectInfo(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.project.description?.isNotEmpty == true)
          Flexible(
            child: Text(
              widget.project.description!,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (_insights.isNotEmpty) ...[
          const SizedBox(height: 4),
          Flexible(
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: _insights.take(2).map((insight) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    insight,
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return Row(
      children: [
        if (widget.project.technologies.isNotEmpty) ...[
          Flexible(
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: widget.project.technologies.take(3).map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tech,
                    style: TextStyle(
                      fontSize: 8,
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const Spacer(),
        Tooltip(
          message: 'Last modified: ${_formatDetailedLastModified(widget.project.lastModified ?? DateTime.now())}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🕒', style: TextStyle(fontSize: 8)),
                const SizedBox(width: 2),
                Text(
                  _formatLastModified(widget.project.lastModified ?? DateTime.now()),
                  style: TextStyle(
                    fontSize: 8,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatLastModified(DateTime lastModified) {
    final now = DateTime.now();
    final difference = now.difference(lastModified);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _formatDetailedLastModified(DateTime lastModified) {
    final now = DateTime.now();
    final difference = now.difference(lastModified);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday at ${_formatTime(lastModified)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${lastModified.day}/${lastModified.month}/${lastModified.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _handleQuickAction(String action) {
    // Track the action
    AnalyticsManager.trackCommand(action, widget.project.path);

    // Handle the action based on the command
    // This would integrate with the launcher service
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getActionEmoji(action), style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('Executing: $action'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getActionEmoji(String action) {
    final actionLower = action.toLowerCase();
    if (actionLower.contains('run') || actionLower.contains('start')) return '▶️';
    if (actionLower.contains('build')) return '🔨';
    if (actionLower.contains('test')) return '🧪';
    if (actionLower.contains('install') || actionLower.contains('get')) return '📦';
    if (actionLower.contains('clean')) return '🧹';
    if (actionLower.contains('format')) return '✨';
    if (actionLower.contains('lint')) return '🔍';
    if (actionLower.contains('deploy')) return '🚀';
    if (actionLower.contains('debug')) return '🐛';
    if (actionLower.contains('reload') || actionLower.contains('refresh')) return '🔄';
    if (actionLower.contains('stop')) return '⏹️';
    if (actionLower.contains('restart')) return '🔁';
    if (actionLower.contains('open') || actionLower.contains('terminal')) return '💻';
    if (actionLower.contains('editor') || actionLower.contains('code')) return '✏️';
    if (actionLower.contains('git')) return '📝';
    if (actionLower.contains('docker')) return '🐳';
    if (actionLower.contains('serve') || actionLower.contains('server')) return '🌐';
    return '⚡';
  }
}

Color _getProjectTypeColor(String type) {
  switch (type) {
    case 'flutter':
      return const Color(0xFF027DFD);
    case 'react':
      return const Color(0xFF61DAFB);
    case 'vue':
      return const Color(0xFF4FC08D);
    case 'angular':
      return const Color(0xFFDD0031);
    case 'node':
    case 'nodejs':
      return const Color(0xFF339933);
    case 'python':
      return const Color(0xFF3776AB);
    case 'rust':
      return const Color(0xFF000000);
    case 'go':
      return const Color(0xFF00ADD8);
    case 'java':
      return const Color(0xFFED8B00);
    case 'cpp':
      return const Color(0xFF00599C);
    case 'docker':
      return const Color(0xFF2496ED);
    default:
      return const Color(0xFF6C757D);
  }
}

String _getProjectTypeDisplayName(String type) {
  switch (type) {
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

String _getProjectTypeIcon(String type) {
  switch (type) {
    case 'flutter':
      return '🦋';
    case 'react':
      return '⚛️';
    case 'vue':
      return '💚';
    case 'angular':
      return '🅰️';
    case 'node':
    case 'nodejs':
      return '🟢';
    case 'python':
      return '🐍';
    case 'rust':
      return '🦀';
    case 'go':
      return '🐹';
    case 'java':
      return '☕';
    case 'docker':
      return '🐳';
    case 'nextjs':
      return '▲';
    case 'svelte':
      return '🧡';
    default:
      return '📁';
  }
}
