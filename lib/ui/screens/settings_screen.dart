import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/settings_manager.dart' as settings_manager;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late settings_manager.DevLynxSettings _settings;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _settings = settings_manager.SettingsManager.settings;
    
    settings_manager.SettingsManager.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    settings_manager.SettingsManager.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        _settings = settings_manager.SettingsManager.settings;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface.withValues(alpha: 0.95),
              colorScheme.surfaceVariant.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(colorScheme),
              _buildTabBar(colorScheme),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppearanceTab(colorScheme),
                    _buildProjectsTab(colorScheme),
                    _buildFeaturesTab(colorScheme),
                    _buildAdvancedTab(colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('⚙️', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Customize your DevLynx experience',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        tabs: const [
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎨', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text('Appearance'),
                ],
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📁', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text('Projects'),
                ],
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✨', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text('Features'),
                ],
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔧', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text('Advanced'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Theme Mode', '🌓'),
          _buildThemeModeSelector(colorScheme),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Accent Color', '🎨'),
          _buildAccentColorSelector(colorScheme),
          const SizedBox(height: 24),
          
          _buildSectionHeader('UI Scale', '📏'),
          _buildUIScaleSlider(colorScheme),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Language', '🌍'),
          _buildLanguageSelector(colorScheme),
        ],
      ),
    );
  }

  Widget _buildProjectsTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Project Directories', '📂'),
          const SizedBox(height: 8),
          Text(
            'DevLynx will scan these directories for projects',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildProjectDirectoriesList(colorScheme),
          const SizedBox(height: 16),
          _buildAddDirectoryButton(colorScheme),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Recent Projects', '🕒'),
          _buildRecentProjectsList(colorScheme),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('AI Features', '🤖'),
          _buildFeatureToggle(
            'AI Insights',
            'Get AI-powered project recommendations and insights',
            _settings.enableAIInsights,
            (value) => _updateSettings(_settings.copyWith(enableAIInsights: value)),
            colorScheme,
          ),
          const SizedBox(height: 16),
          
          _buildSectionHeader('Voice Commands', '🎤'),
          _buildFeatureToggle(
            'Voice Control',
            'Control DevLynx with voice commands',
            _settings.enableVoiceCommands,
            (value) => _updateSettings(_settings.copyWith(enableVoiceCommands: value)),
            colorScheme,
          ),
          const SizedBox(height: 16),
          
          _buildSectionHeader('Analytics & Privacy', '📊'),
          _buildFeatureToggle(
            'Usage Analytics',
            'Help improve DevLynx by sharing anonymous usage data',
            _settings.enableAnalytics,
            (value) => _updateSettings(_settings.copyWith(enableAnalytics: value)),
            colorScheme,
          ),
          const SizedBox(height: 16),
          
          _buildSectionHeader('Notifications', '🔔'),
          _buildFeatureToggle(
            'Desktop Notifications',
            'Show system notifications for important events',
            _settings.enableNotifications,
            (value) => _updateSettings(_settings.copyWith(enableNotifications: value)),
            colorScheme,
          ),
          const SizedBox(height: 8),
          _buildFeatureToggle(
            'Sound Effects',
            'Play sound effects for actions and notifications',
            _settings.enableSounds,
            (value) => _updateSettings(_settings.copyWith(enableSounds: value)),
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Default Applications', '💻'),
          _buildApplicationSelector(
            'Terminal',
            'Default terminal application',
            _settings.preferredTerminal,
            (value) => _updateSettings(_settings.copyWith(preferredTerminal: value)),
            colorScheme,
          ),
          const SizedBox(height: 16),
          _buildApplicationSelector(
            'Code Editor',
            'Default code editor',
            _settings.preferredEditor,
            (value) => _updateSettings(_settings.copyWith(preferredEditor: value)),
            colorScheme,
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('System Integration', '🔗'),
          _buildFeatureToggle(
            'System Tray',
            'Show DevLynx icon in system tray',
            _settings.enableSystemTray,
            (value) => _updateSettings(_settings.copyWith(enableSystemTray: value)),
            colorScheme,
          ),
          const SizedBox(height: 8),
          _buildFeatureToggle(
            'Auto-start with System',
            'Launch DevLynx automatically when system starts',
            _settings.autoStartWithSystem,
            (value) => _updateSettings(_settings.copyWith(autoStartWithSystem: value)),
            colorScheme,
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Data Management', '💾'),
          _buildDataManagementButtons(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: settings_manager.ThemeMode.values.map((mode) {
          final isSelected = _settings.themeMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => _updateSettings(_settings.copyWith(themeMode: mode)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getThemeModeLabel(mode),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccentColorSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: settings_manager.AccentColor.values.map((color) {
          final isSelected = _settings.accentColor == color;
          return GestureDetector(
            onTap: () => _updateSettings(_settings.copyWith(accentColor: color)),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? colorScheme.onSurface : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUIScaleSlider(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Scale: ${(_settings.uiScale * 100).toInt()}%'),
              TextButton(
                onPressed: () => _updateSettings(_settings.copyWith(uiScale: 1.0)),
                child: const Text('Reset'),
              ),
            ],
          ),
          Slider(
            value: _settings.uiScale,
            min: 0.8,
            max: 1.5,
            divisions: 14,
            label: '${(_settings.uiScale * 100).toInt()}%',
            onChanged: (value) => _updateSettings(_settings.copyWith(uiScale: value)),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(ColorScheme colorScheme) {
    final languages = {
      'en': '🇺🇸 English',
      'es': '🇪🇸 Español',
      'fr': '🇫🇷 Français',
      'de': '🇩🇪 Deutsch',
      'zh': '🇨🇳 中文',
      'ja': '🇯🇵 日本語',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonFormField<String>(
        value: _settings.language,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        items: languages.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            _updateSettings(_settings.copyWith(language: value));
          }
        },
      ),
    );
  }

  Widget _buildProjectDirectoriesList(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _settings.projectDirectories.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final directory = _settings.projectDirectories[index];
          return ListTile(
            leading: const Text('📁', style: TextStyle(fontSize: 20)),
            title: Text(
              directory,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeProjectDirectory(directory),
              tooltip: 'Remove directory',
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddDirectoryButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addProjectDirectory,
        icon: const Icon(Icons.add),
        label: const Text('Add Project Directory'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          side: BorderSide(color: colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildRecentProjectsList(ColorScheme colorScheme) {
    if (_settings.recentProjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Text(
          'No recent projects',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _settings.recentProjects.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final project = _settings.recentProjects[index];
          final projectName = project.split(Platform.pathSeparator).last;
          
          return ListTile(
            leading: const Text('📂', style: TextStyle(fontSize: 20)),
            title: Text(projectName),
            subtitle: Text(
              project,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              '#${index + 1}',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureToggle(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationSelector(
    String title,
    String description,
    String currentValue,
    ValueChanged<String> onChanged,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: currentValue,
            decoration: InputDecoration(
              hintText: 'Enter application name or path',
              suffixIcon: IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: () => _selectApplication(onChanged),
                tooltip: 'Browse for application',
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementButtons(ColorScheme colorScheme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _exportSettings,
            icon: const Icon(Icons.download),
            label: const Text('Export Settings'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _importSettings,
            icon: const Icon(Icons.upload),
            label: const Text('Import Settings'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _resetSettings,
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
      ],
    );
  }

  String _getThemeModeLabel(settings_manager.ThemeMode mode) {
    switch (mode) {
      case settings_manager.ThemeMode.system:
        return 'System';
      case settings_manager.ThemeMode.light:
        return 'Light';
      case settings_manager.ThemeMode.dark:
        return 'Dark';
      case settings_manager.ThemeMode.custom:
        return 'Custom';
    }
  }

  void _updateSettings(settings_manager.DevLynxSettings newSettings) {
    settings_manager.SettingsManager.updateSettings(newSettings);
  }

  Future<void> _addProjectDirectory() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Project Directory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Directory Path',
                hintText: '/home/user/projects',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Common directories:\n/home/\$USER/Projects\n/home/\$USER/Documents\n/home/\$USER/Code',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final dir = Directory(result);
      if (await dir.exists()) {
        await settings_manager.SettingsManager.addProjectDirectory(result);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Directory does not exist')),
          );
        }
      }
    }
  }

  Future<void> _removeProjectDirectory(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Directory'),
        content: Text('Remove "$path" from project directories?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await settings_manager.SettingsManager.removeProjectDirectory(path);
    }
  }

  Future<void> _selectApplication(ValueChanged<String> onChanged) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Application Path or Name',
                hintText: 'code, /usr/bin/gnome-terminal, etc.',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Examples:\ncode (VS Code)\ngnome-terminal\nkonsole\nvim\nnano',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Set'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      onChanged(result);
    }
  }

  Future<void> _exportSettings() async {
    // Implementation for exporting settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings export coming soon!')),
    );
  }

  Future<void> _importSettings() async {
    // Implementation for importing settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings import coming soon!')),
    );
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await settings_manager.SettingsManager.updateSettings(const settings_manager.DevLynxSettings());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults')),
        );
      }
    }
  }
}
