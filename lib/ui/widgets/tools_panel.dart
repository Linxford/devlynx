import 'package:flutter/material.dart';
import '../../data/tool_detector.dart';

class ToolsPanel extends StatelessWidget {
  final List<DetectedTool> tools;

  const ToolsPanel({super.key, required this.tools});

  @override
  Widget build(BuildContext context) {
    final groupedTools = groupToolsByCategory(tools);

    if (tools.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No development tools detected',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTools.length,
      itemBuilder: (context, index) {
        final category = groupedTools.keys.elementAt(index);
        final categoryTools = groupedTools[category]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Row(
              children: [
                _getCategoryIcon(category),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text('${categoryTools.length}'),
                  visualDensity: VisualDensity.compact,
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
    switch (category) {
      case 'Language':
        return const Icon(Icons.code, color: Colors.blue);
      case 'Framework':
        return const Icon(Icons.widgets, color: Colors.purple);
      case 'Runtime':
        return const Icon(Icons.settings, color: Colors.green);
      case 'Package Manager':
        return const Icon(Icons.inventory, color: Colors.orange);
      case 'Version Control':
        return const Icon(Icons.source, color: Colors.red);
      case 'Database':
        return const Icon(Icons.storage, color: Colors.indigo);
      case 'Container':
        return const Icon(Icons.view_in_ar, color: Colors.cyan);
      case 'DevOps':
        return const Icon(Icons.cloud, color: Colors.teal);
      case 'Editor':
        return const Icon(Icons.edit, color: Colors.amber);
      case 'Build Tool':
        return const Icon(Icons.build_circle, color: Colors.brown);
      case 'Testing':
        return const Icon(Icons.bug_report, color: Colors.pink);
      case 'Infrastructure':
        return const Icon(Icons.architecture, color: Colors.deepOrange);
      default:
        return const Icon(Icons.extension, color: Colors.grey);
    }
  }
}

class _ToolTile extends StatelessWidget {
  final DetectedTool tool;

  const _ToolTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          tool.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        tool.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tool.version != null)
            Text(
              'Version: ${tool.version}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          if (tool.path != null)
            Text(
              tool.path!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () => _showToolInfo(context),
      ),
    );
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
