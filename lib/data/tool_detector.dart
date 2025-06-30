import 'dart:io';

class DetectedTool {
  final String name;
  final String category;
  final String? version;
  final String? path;

  const DetectedTool({
    required this.name,
    required this.category,
    this.version,
    this.path,
  });
}

/// Detects common development tools by checking their presence in $PATH.
/// Returns a list of installed tool names.
Future<List<String>> detectInstalledTools() async {
  final tools = await detectDetailedTools();
  return tools.map((tool) => tool.name).toList();
}

/// Detects development tools with detailed information
Future<List<DetectedTool>> detectDetailedTools() async {
  final Map<String, String> toolCategories = {
    // Languages & Runtimes
    'flutter': 'Framework',
    'dart': 'Language',
    'node': 'Runtime',
    'npm': 'Package Manager',
    'yarn': 'Package Manager',
    'pnpm': 'Package Manager',
    'python': 'Language',
    'python3': 'Language',
    'pip': 'Package Manager',
    'pip3': 'Package Manager',
    'rustc': 'Language',
    'cargo': 'Package Manager',
    'go': 'Language',
    'java': 'Language',
    'javac': 'Language',
    'mvn': 'Build Tool',
    'gradle': 'Build Tool',
    'php': 'Language',
    'composer': 'Package Manager',
    'ruby': 'Language',
    'gem': 'Package Manager',
    'bundle': 'Package Manager',

    // Version Control
    'git': 'Version Control',
    'gh': 'Version Control',
    'svn': 'Version Control',
    'hg': 'Version Control',

    // Databases
    'psql': 'Database',
    'mysql': 'Database',
    'sqlite3': 'Database',
    'redis-server': 'Database',
    'redis-cli': 'Database',
    'mongo': 'Database',
    'mongod': 'Database',

    // DevOps & Containers
    'docker': 'Container',
    'docker-compose': 'Container',
    'podman': 'Container',
    'kubectl': 'DevOps',
    'helm': 'DevOps',
    'terraform': 'Infrastructure',
    'ansible': 'Infrastructure',
    'vagrant': 'DevOps',

    // Editors & IDEs
    'code': 'Editor',
    'cursor': 'Editor',
    'vim': 'Editor',
    'nvim': 'Editor',
    'nano': 'Editor',
    'emacs': 'Editor',

    // Build Tools & Task Runners
    'make': 'Build Tool',
    'cmake': 'Build Tool',
    'ninja': 'Build Tool',
    'webpack': 'Build Tool',
    'vite': 'Build Tool',
    'rollup': 'Build Tool',
    'parcel': 'Build Tool',
    'gulp': 'Task Runner',
    'grunt': 'Task Runner',

    // Testing
    'jest': 'Testing',
    'cypress': 'Testing',
    'playwright': 'Testing',
    'pytest': 'Testing',

    // Linting & Formatting
    'eslint': 'Linting',
    'prettier': 'Formatting',
    'black': 'Formatting',
    'rustfmt': 'Formatting',

    // Cloud CLIs
    'aws': 'Cloud',
    'gcloud': 'Cloud',
    'az': 'Cloud',
    'doctl': 'Cloud',
    'heroku': 'Cloud',
    'vercel': 'Cloud',
    'netlify': 'Cloud',

    // System Tools
    'curl': 'Network',
    'wget': 'Network',
    'jq': 'Utility',
    'yq': 'Utility',
    'htop': 'System',
    'btop': 'System',
    'neofetch': 'System',
  };

  final List<DetectedTool> detected = [];
  final List<String> toolsToCheck = toolCategories.keys.toList();

  for (final tool in toolsToCheck) {
    try {
      final result = await Process.run('which', [tool]);

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final path = result.stdout.toString().trim();
        String? version;

        // Try to get version for some tools
        try {
          final versionResult = await _getToolVersion(tool);
          version = versionResult;
        } catch (_) {
          // Version detection failed, that's okay
        }

        detected.add(
          DetectedTool(
            name: tool,
            category: toolCategories[tool] ?? 'Other',
            version: version,
            path: path,
          ),
        );
      }
    } catch (_) {
      // Tool check failed, continue with next tool
    }
  }

  // Sort by category, then by name
  detected.sort((a, b) {
    final categoryComparison = a.category.compareTo(b.category);
    if (categoryComparison != 0) return categoryComparison;
    return a.name.compareTo(b.name);
  });

  return detected;
}

Future<String?> _getToolVersion(String tool) async {
  final Map<String, List<String>> versionCommands = {
    'flutter': ['--version'],
    'dart': ['--version'],
    'node': ['--version'],
    'npm': ['--version'],
    'python': ['--version'],
    'python3': ['--version'],
    'go': ['version'],
    'java': ['-version'],
    'git': ['--version'],
    'docker': ['--version'],
    'code': ['--version'],
    'rustc': ['--version'],
    'cargo': ['--version'],
  };

  final command = versionCommands[tool];
  if (command == null) return null;

  try {
    final result = await Process.run(tool, command);
    if (result.exitCode == 0) {
      final output = result.stdout.toString().trim();
      if (output.isNotEmpty) {
        // Extract version number from output
        final versionMatch = RegExp(r'(\d+\.\d+(?:\.\d+)?)').firstMatch(output);
        return versionMatch?.group(1) ?? output.split('\n').first;
      }
    }
  } catch (_) {
    // Version command failed
  }

  return null;
}

/// Get tools grouped by category
Map<String, List<DetectedTool>> groupToolsByCategory(List<DetectedTool> tools) {
  final Map<String, List<DetectedTool>> grouped = {};

  for (final tool in tools) {
    grouped.putIfAbsent(tool.category, () => []).add(tool);
  }

  return grouped;
}
