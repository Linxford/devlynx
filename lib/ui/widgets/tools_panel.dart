import 'package:flutter/material.dart';
import '../../data/tool_detector.dart';

class ToolsPanel extends StatelessWidget {
  final List<DetectedTool> tools;

  const ToolsPanel({super.key, required this.tools});

  @override
  Widget build(BuildContext context) {
    final groupedTools = groupToolsByCategory(tools);
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 800;

    if (tools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.primaryContainer.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('🔧', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 16),
            Text(
              'No development tools detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Install development tools to see them here',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      itemCount: groupedTools.length,
      itemBuilder: (context, index) {
        final category = groupedTools.keys.elementAt(index);
        final categoryTools = groupedTools[category]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface.withOpacity(0.9),
                colorScheme.surfaceVariant.withOpacity(0.8),
              ],
            ),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            childrenPadding: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                _getCategoryIcon(category),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Tooltip(
                  message: '${categoryTools.length} tools in this category',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getCategoryColor(category).withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${categoryTools.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(category),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            children: categoryTools
                .map((tool) => _ToolTile(tool: tool))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _getCategoryIcon(String category) {
    final color = _getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getCategoryEmoji(category),
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Language':
        return '💻';
      case 'Framework':
        return '🏗️';
      case 'Runtime':
        return '⚙️';
      case 'Package Manager':
        return '📦';
      case 'Version Control':
        return '📝';
      case 'Database':
        return '🗄️';
      case 'Container':
        return '🐳';
      case 'DevOps':
        return '☁️';
      case 'Editor':
        return '✏️';
      case 'Build Tool':
        return '🔨';
      case 'Testing':
        return '🧪';
      case 'Infrastructure':
        return '🏛️';
      default:
        return '🔧';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Language':
        return const Color(0xFF2196F3);
      case 'Framework':
        return const Color(0xFF9C27B0);
      case 'Runtime':
        return const Color(0xFF4CAF50);
      case 'Package Manager':
        return const Color(0xFFFF9800);
      case 'Version Control':
        return const Color(0xFFF44336);
      case 'Database':
        return const Color(0xFF3F51B5);
      case 'Container':
        return const Color(0xFF00BCD4);
      case 'DevOps':
        return const Color(0xFF009688);
      case 'Editor':
        return const Color(0xFFFFC107);
      case 'Build Tool':
        return const Color(0xFF795548);
      case 'Testing':
        return const Color(0xFFE91E63);
      case 'Infrastructure':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

class _ToolTile extends StatelessWidget {
  final DetectedTool tool;

  const _ToolTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surface.withOpacity(0.5),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withOpacity(0.8),
                colorScheme.primaryContainer.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getToolEmoji(tool.name),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          tool.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tool.version != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'v${tool.version}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
            if (tool.path != null) ...[
              const SizedBox(height: 4),
              Tooltip(
                message: tool.path!,
                child: Text(
                  tool.path!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: Tooltip(
          message: 'View details for ${tool.name}',
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('ℹ️', style: TextStyle(fontSize: 16)),
            ),
            onPressed: () => _showToolInfo(context),
          ),
        ),
      ),
    );
  }

  String _getToolEmoji(String toolName) {
    final name = toolName.toLowerCase();
    if (name.contains('node') || name.contains('npm')) return '🟢';
    if (name.contains('python') || name.contains('pip')) return '🐍';
    if (name.contains('rust') || name.contains('cargo')) return '🦀';
    if (name.contains('go')) return '🐹';
    if (name.contains('java')) return '☕';
    if (name.contains('docker')) return '🐳';
    if (name.contains('git')) return '📝';
    if (name.contains('code') || name.contains('vim')) return '✏️';
    if (name.contains('flutter') || name.contains('dart')) return '🦋';
    if (name.contains('react')) return '⚛️';
    if (name.contains('vue')) return '💚';
    if (name.contains('angular')) return '🅰️';
    if (name.contains('mysql') || name.contains('postgres')) return '🗄️';
    if (name.contains('redis')) return '🔴';
    if (name.contains('mongo')) return '🍃';
    if (name.contains('nginx') || name.contains('apache')) return '🌐';
    if (name.contains('terraform') || name.contains('ansible')) return '🏗️';
    if (name.contains('kubernetes') || name.contains('kubectl')) return '⚓';
    if (name.contains('aws') || name.contains('gcloud')) return '☁️';
    return '🔧';
  }

  void _showToolInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tool.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Category', tool.category),
            if (tool.version != null) _InfoRow('Version', tool.version!),
            if (tool.path != null) _InfoRow('Path', tool.path!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
