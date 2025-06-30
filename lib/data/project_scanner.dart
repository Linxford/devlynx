import 'dart:io';

class Project {
  final String path;
  final String name;
  final String type;
  final String? description;
  final DateTime? lastModified;
  final List<String> technologies;

  const Project({
    required this.path,
    required this.name,
    required this.type,
    this.description,
    this.lastModified,
    this.technologies = const [],
  });

  String get displayName => name.replaceAll('_', ' ').replaceAll('-', ' ');

  String get icon {
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
}

Future<List<Project>> scanProjects(List<String> rootDirs) async {
  final List<Project> foundProjects = [];

  for (final dirPath in rootDirs) {
    final root = Directory(dirPath);
    if (!await root.exists()) continue;

    await for (final entity in root.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is Directory) {
        final project = await _analyzeProject(entity);
        if (project != null) {
          foundProjects.add(project);
        }
      }
    }
  }

  // Sort by last modified (most recent first)
  foundProjects.sort(
    (a, b) => (b.lastModified ?? DateTime(1970)).compareTo(
      a.lastModified ?? DateTime(1970),
    ),
  );

  return foundProjects;
}

Future<Project?> _analyzeProject(Directory dir) async {
  final path = dir.path;
  final name = path.split(Platform.pathSeparator).last;
  final technologies = <String>[];
  String? description;
  DateTime? lastModified;

  try {
    final stat = await dir.stat();
    lastModified = stat.modified;
  } catch (_) {}

  // Check for various project types
  final files = <String, bool>{};
  await for (final entity in dir.list(recursive: false)) {
    if (entity is File) {
      files[entity.path.split(Platform.pathSeparator).last] = true;
    }
  }

  // Flutter
  if (files['pubspec.yaml'] == true) {
    try {
      final pubspec = File('$path/pubspec.yaml');
      final content = await pubspec.readAsString();
      description = _extractDescription(content);
      technologies.add('Dart');
      if (content.contains('flutter:')) {
        technologies.add('Flutter');
        return Project(
          path: path,
          name: name,
          type: 'flutter',
          description: description,
          lastModified: lastModified,
          technologies: technologies,
        );
      }
    } catch (_) {}
  }

  // Node.js projects
  if (files['package.json'] == true) {
    try {
      final packageJson = File('$path/package.json');
      final content = await packageJson.readAsString();
      description = _extractJsonDescription(content);
      technologies.add('JavaScript');

      // Detect framework
      String projectType = 'node';
      if (content.contains('"next"') || content.contains('"@next/')) {
        projectType = 'nextjs';
        technologies.add('Next.js');
      } else if (content.contains('"react"')) {
        projectType = 'react';
        technologies.add('React');
      } else if (content.contains('"vue"')) {
        projectType = 'vue';
        technologies.add('Vue.js');
      } else if (content.contains('"@angular/')) {
        projectType = 'angular';
        technologies.add('Angular');
      } else if (content.contains('"svelte"')) {
        projectType = 'svelte';
        technologies.add('Svelte');
      }

      if (content.contains('"typescript"')) {
        technologies.add('TypeScript');
      }

      return Project(
        path: path,
        name: name,
        type: projectType,
        description: description,
        lastModified: lastModified,
        technologies: technologies,
      );
    } catch (_) {}
  }

  // Python
  if (files['requirements.txt'] == true ||
      files['pyproject.toml'] == true ||
      files['setup.py'] == true) {
    technologies.add('Python');
    return Project(
      path: path,
      name: name,
      type: 'python',
      description: description,
      lastModified: lastModified,
      technologies: technologies,
    );
  }

  // Rust
  if (files['Cargo.toml'] == true) {
    try {
      final cargo = File('$path/Cargo.toml');
      final content = await cargo.readAsString();
      description = _extractTomlDescription(content);
      technologies.add('Rust');
      return Project(
        path: path,
        name: name,
        type: 'rust',
        description: description,
        lastModified: lastModified,
        technologies: technologies,
      );
    } catch (_) {}
  }

  // Go
  if (files['go.mod'] == true) {
    technologies.add('Go');
    return Project(
      path: path,
      name: name,
      type: 'go',
      description: description,
      lastModified: lastModified,
      technologies: technologies,
    );
  }

  // Java (Maven/Gradle)
  if (files['pom.xml'] == true || files['build.gradle'] == true) {
    technologies.add('Java');
    return Project(
      path: path,
      name: name,
      type: 'java',
      description: description,
      lastModified: lastModified,
      technologies: technologies,
    );
  }

  // Docker
  if (files['docker-compose.yml'] == true || files['Dockerfile'] == true) {
    technologies.add('Docker');
    return Project(
      path: path,
      name: name,
      type: 'docker',
      description: description,
      lastModified: lastModified,
      technologies: technologies,
    );
  }

  // Git repository (fallback)
  if (Directory('$path/.git').existsSync()) {
    return Project(
      path: path,
      name: name,
      type: 'git',
      description: description,
      lastModified: lastModified,
      technologies: technologies,
    );
  }

  return null;
}

String? _extractDescription(String content) {
  final match = RegExp(
    r'description:\s*["\047]([^"\047]+)["\047]',
  ).firstMatch(content);
  return match?.group(1);
}

String? _extractJsonDescription(String content) {
  final match = RegExp(r'"description":\s*"([^"]+)"').firstMatch(content);
  return match?.group(1);
}

String? _extractTomlDescription(String content) {
  final match = RegExp(r'description\s*=\s*"([^"]+)"').firstMatch(content);
  return match?.group(1);
}
