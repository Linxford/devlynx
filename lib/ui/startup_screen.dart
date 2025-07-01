import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/project_scanner.dart';
import '../data/tool_detector.dart';
import '../data/session_storage.dart';
import '../services/launcher_service.dart';
import '../data/project_notes.dart';
import '../data/analytics_manager.dart';
import 'widgets/tools_panel.dart';
import 'widgets/project_notes_dialog.dart';
import 'widgets/modern_project_card.dart';
import 'widgets/analytics_dashboard.dart';
import 'widgets/ai_assistant_panel.dart';
import 'widgets/voice_control_widget.dart';
import 'screens/ai_configuration_screen.dart';
import 'screens/settings_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with TickerProviderStateMixin {
  Project? selected;
  bool isLaunching = false;
  String? launchMessage;
  String searchQuery = '';
  String selectedFilter = 'all';
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedIndex = 0;
  String _greetingMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _initializeAssistant();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeAssistant() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _slideController.forward();
    
    // Generate greeting message
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    
    setState(() {
      _greetingMessage = '$timeGreeting, Linxford! Ready to build something amazing today?';
    });
  }

  Future<void> _launch(Project project) async {
    // Use post-frame callback to prevent setState during frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isLaunching = true;
          launchMessage = '🚀 Launching "${project.name}"...';
        });
      }
    });
    
    // Track project launch
    AnalyticsManager.trackProjectLaunch(project.path, project.type);

    final launcher = context.read<LauncherService>();
    await launcher.launchProject(project);

    // Use post-frame callback for completion state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isLaunching = false;
          launchMessage = '✅ Launched "${project.name}"';
        });
      }
    });

    await SessionStorage().saveSession(
      SessionData(
        lastProject: project.name,
        lastTools: context.read<List<String>>(),
        lastOpened: DateTime.now(),
      ),
    );
  }

  Future<void> _quickAction(Project project, String action) async {
    final launcher = context.read<LauncherService>();
    await launcher.runQuickAction(project, action);

    // Use post-frame callback to prevent setState during frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          launchMessage = '⚡ Executed "$action" for "${project.name}"';
        });
      }
    });
  }

  Future<void> _showNotesDialog(Project project) async {
    await showDialog(
      context: context,
      builder: (context) => ProjectNotesDialog(project: project),
    );
  }

  List<Project> _getFilteredProjects(List<Project> projects) {
    var filtered = projects;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                p.type.toLowerCase().contains(searchQuery.toLowerCase()) ||
                (p.description?.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    // Apply type filter
    if (selectedFilter != 'all') {
      filtered = filtered.where((p) => p.type == selectedFilter).toList();
    }

    return filtered;
  }

  Set<String> _getProjectTypes(List<Project> projects) {
    return projects.map((p) => p.type).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<List<Project>>();
    final session = context.watch<SessionData?>();
    final tools = context.watch<List<String>>();
    final detailedTools = context.watch<List<DetectedTool>>();

    final filteredProjects = _getFilteredProjects(projects);
    final projectTypes = _getProjectTypes(projects);
    final lastProject = _getLastProject(projects, session?.lastProject);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.3),
              colorScheme.primaryContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(context, projects, tools, lastProject),
              _buildNavigationBar(context),
              Expanded(
                child: _buildContent(context, filteredProjects, projectTypes, detailedTools),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Project? _getLastProject(List<Project> projects, String? name) {
    try {
      return projects.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  Widget _buildModernHeader(BuildContext context, List<Project> projects, List<String> tools, Project? lastProject) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main greeting section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.8),
                        colorScheme.primary.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lightbulb, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DevLynx Assistant',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _greetingMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AIConfigurationScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.psychology, color: colorScheme.onSurfaceVariant),
                      tooltip: 'AI Configuration',
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.settings, color: colorScheme.onSurfaceVariant),
                      tooltip: 'Settings',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Stats row
            Row(
              children: [
                _buildStatCard(colorScheme, 'Projects', projects.length.toString(), Icons.folder_outlined),
                const SizedBox(width: 12),
                _buildStatCard(colorScheme, 'Tools', tools.length.toString(), Icons.build_outlined),
                const SizedBox(width: 12),
                _buildStatCard(colorScheme, 'Session', 'Active', Icons.timer_outlined),
              ],
            ),
            
            // Continue last project button
            if (lastProject != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLaunching ? null : () => _launch(lastProject),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Continue "${lastProject.displayName}"'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ColorScheme colorScheme, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
              colorScheme.surface.withOpacity(0.8),
            ],
          ),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildNavButton(colorScheme, 'Projects', Icons.folder_outlined, 0),
          _buildNavButton(colorScheme, 'Tools', Icons.build_outlined, 1),
          _buildNavButton(colorScheme, 'Analytics', Icons.analytics_outlined, 2),
          _buildNavButton(colorScheme, 'AI Chat', Icons.psychology_outlined, 3),
        ],
      ),
    );
  }

  Widget _buildNavButton(ColorScheme colorScheme, String label, IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? colorScheme.primary : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Project> filteredProjects, Set<String> projectTypes, List<DetectedTool> detailedTools) {
    switch (_selectedIndex) {
      case 0:
        return _buildProjectsTab(context, filteredProjects, projectTypes);
      case 1:
        return ToolsPanel(tools: detailedTools);
      case 2:
        return const AnalyticsDashboard();
      case 3:
        return AIAssistantPanel(projects: filteredProjects);
      default:
        return _buildProjectsTab(context, filteredProjects, projectTypes);
    }
  }

  Widget _buildProjectsTab(BuildContext context, List<Project> filteredProjects, Set<String> projectTypes) {
    return Column(
      children: [
        // Search and filter section
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                onChanged: (value) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => searchQuery = value);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: selectedFilter == 'all',
                      onSelected: (_) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => selectedFilter = 'all');
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ...projectTypes.map((type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.toUpperCase()),
                        selected: selectedFilter == type,
                        onSelected: (_) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => selectedFilter = type);
                            }
                          });
                        },
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Projects grid
        Expanded(
          child: filteredProjects.isEmpty
              ? _buildEmptyState(context)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount;
                    double childAspectRatio;
                    
                    if (width > 1200) {
                      crossAxisCount = 4;
                      childAspectRatio = 2.2;
                    } else if (width > 800) {
                      crossAxisCount = 3;
                      childAspectRatio = 2.0;
                    } else if (width > 600) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.8;
                    } else {
                      crossAxisCount = 1;
                      childAspectRatio = 2.5;
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = filteredProjects[index];
                          return ModernProjectCard(
                            project: project,
                            onTap: () => _launch(project),
                            onNotesPressed: () => _showNotesDialog(project),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'No projects match your search'
                : 'No projects found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Projects are scanned from ~/Projects and ~/Desktop/Projects',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          if (launchMessage != null) ...[
            Expanded(
              child: Text(
                launchMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ] else ...[
            Text(
              'Ready to start your development session',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          const VoiceControlWidget(),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final Project project;
  final bool isSelected;
  final bool isLaunching;
  final VoidCallback onTap;
  final VoidCallback onLaunch;
  final Function(String) onQuickAction;

  const _ProjectCard({
    required this.project,
    required this.isSelected,
    required this.isLaunching,
    required this.onTap,
    required this.onLaunch,
    required this.onQuickAction,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  ProjectNote? _note;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final notesManager = ProjectNotesManager();
    final note = await notesManager.loadNote(widget.project.path);
    if (mounted) {
      setState(() {
        _note = note;
      });
    }
  }

  Future<void> _showNotesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          ProjectNotesDialog(project: widget.project, existingNote: _note),
    );

    if (result == true) {
      // Reload note after saving/deleting
      _loadNote();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.isSelected;

    return Card(
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and type
              Row(
                children: [
                  Text(
                    widget.project.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.project.type.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Project name
              Text(
                widget.project.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Description or path
              Text(
                widget.project.description ?? widget.project.path,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Technologies
              if (widget.project.technologies.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.project.technologies
                      .take(3)
                      .map(
                        (tech) => Chip(
                          label: Text(tech),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],

              const Spacer(),

              // Action buttons
              Row(
                children: [
                  // Notes button
                  IconButton(
                    onPressed: _showNotesDialog,
                    icon: Icon(
                      _note != null ? Icons.note : Icons.note_add,
                      color: _note != null ? theme.colorScheme.primary : null,
                    ),
                    tooltip: _note != null ? 'Edit notes' : 'Add notes',
                    visualDensity: VisualDensity.compact,
                  ),

                  // Quick actions
                  PopupMenuButton<String>(
                    onSelected: widget.onQuickAction,
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Quick actions',
                    itemBuilder: (context) =>
                        _getQuickActions(widget.project.type),
                  ),

                  const Spacer(),

                  // Launch button
                  FilledButton.icon(
                    onPressed: widget.isLaunching ? null : widget.onLaunch,
                    icon: widget.isLaunching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(widget.isLaunching ? 'Launching...' : 'Launch'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _getQuickActions(String projectType) {
    switch (projectType) {
      case 'flutter':
        return [
          const PopupMenuItem(value: 'clean', child: Text('Flutter Clean')),
          const PopupMenuItem(value: 'pub_get', child: Text('Pub Get')),
          const PopupMenuItem(value: 'build', child: Text('Build')),
          const PopupMenuItem(value: 'test', child: Text('Run Tests')),
        ];
      case 'react':
      case 'nextjs':
      case 'node':
        return [
          const PopupMenuItem(value: 'install', child: Text('npm install')),
          const PopupMenuItem(value: 'build', child: Text('Build')),
          const PopupMenuItem(value: 'test', child: Text('Run Tests')),
          const PopupMenuItem(value: 'lint', child: Text('Lint')),
        ];
      case 'python':
        return [
          const PopupMenuItem(value: 'install', child: Text('pip install')),
          const PopupMenuItem(value: 'test', child: Text('Run Tests')),
          const PopupMenuItem(value: 'lint', child: Text('Lint')),
        ];
      default:
        return [
          const PopupMenuItem(value: 'terminal', child: Text('Open Terminal')),
          const PopupMenuItem(value: 'editor', child: Text('Open in Editor')),
        ];
    }
  }
}
