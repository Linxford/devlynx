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
import 'screens/ai_configuration_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launch(Project project) async {
    setState(() {
      isLaunching = true;
      launchMessage = '🚀 Launching "${project.name}"...';
      // Track project launch
      AnalyticsManager.trackProjectLaunch(project.path, project.type);
    });

    final launcher = context.read<LauncherService>();
    await launcher.launchProject(project);

    setState(() {
      isLaunching = false;
      launchMessage = '✅ Launched "${project.name}"';
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

    setState(() {
      launchMessage = '⚡ Executed "$action" for "${project.name}"';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('DevLynx Assistant'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIConfigurationScreen(),
                ),
              );
            },
            tooltip: 'AI Configuration',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger a rebuild to refresh projects
              setState(() {});
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.folder), text: 'Projects'),
            Tab(icon: Icon(Icons.build), text: 'Tools'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.waving_hand, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, Linxford!',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${projects.length} projects • ${tools.length} tools detected',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Continue Last Project Button
                if (lastProject != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isLaunching
                          ? null
                          : () => _launch(lastProject),
                      icon: const Icon(Icons.play_arrow),
                      label: Text('Continue "${lastProject.displayName}"'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Projects Tab
                Column(
                  children: [
                    // Search and Filter Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Search Bar
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search projects...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            onChanged: (value) =>
                                setState(() => searchQuery = value),
                          ),
                          const SizedBox(height: 12),

                          // Filter Chips
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                FilterChip(
                                  label: const Text('All'),
                                  selected: selectedFilter == 'all',
                                  onSelected: (_) =>
                                      setState(() => selectedFilter = 'all'),
                                ),
                                const SizedBox(width: 8),
                                ...projectTypes.map(
                                  (type) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(type.toUpperCase()),
                                      selected: selectedFilter == type,
                                      onSelected: (_) =>
                                          setState(() => selectedFilter = type),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Projects Grid
                    Expanded(
                      child: filteredProjects.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_open,
                                    size: 64,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchQuery.isNotEmpty
                                        ? 'No projects match your search'
                                        : 'No projects found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Projects are scanned from ~/Projects and ~/Desktop/Projects',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 400,
                                      childAspectRatio: 2.5,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: filteredProjects.length,
                                itemBuilder: (context, index) {
                                  final project = filteredProjects[index];
                                  return ModernProjectCard(
                                    project: project,
                                    onTap: () => _launch(project),
                                    onNotesPressed: () =>
                                        _showNotesDialog(project),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),

                // Tools Tab
                ToolsPanel(tools: detailedTools),

                // Analytics Tab
                const AnalyticsDashboard(),
              ],
            ),
          ),

          // Status Bar
          if (launchMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Text(
                launchMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
        ],
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
  bool _loadingNote = true;

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
        _loadingNote = false;
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
