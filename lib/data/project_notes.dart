import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class ProjectNote {
  final String projectPath;
  final String content;
  final DateTime lastModified;
  final List<String> tags;

  const ProjectNote({
    required this.projectPath,
    required this.content,
    required this.lastModified,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'project_path': projectPath,
    'content': content,
    'last_modified': lastModified.toIso8601String(),
    'tags': tags,
  };

  factory ProjectNote.fromJson(Map<String, dynamic> json) {
    return ProjectNote(
      projectPath: json['project_path'] as String,
      content: json['content'] as String,
      lastModified: DateTime.parse(json['last_modified'] as String),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class ProjectNotesManager {
  final String _configDir = p.join(
    Platform.environment['HOME'] ?? '.',
    '.config',
    'devlynx',
  );
  final String _notesFile = 'project_notes.json';

  Future<File> _getFile() async {
    final dir = Directory(_configDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(_configDir, _notesFile));
  }

  Future<Map<String, ProjectNote>> loadAllNotes() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return {};

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final Map<String, ProjectNote> notes = {};
      for (final entry in decoded.entries) {
        notes[entry.key] = ProjectNote.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }

      return notes;
    } catch (e) {
      stderr.writeln('⚠️ Failed to load project notes: $e');
      return {};
    }
  }

  Future<ProjectNote?> loadNote(String projectPath) async {
    final allNotes = await loadAllNotes();
    return allNotes[projectPath];
  }

  Future<void> saveNote(
    String projectPath,
    String content, {
    List<String> tags = const [],
  }) async {
    try {
      final allNotes = await loadAllNotes();

      allNotes[projectPath] = ProjectNote(
        projectPath: projectPath,
        content: content,
        lastModified: DateTime.now(),
        tags: tags,
      );

      final file = await _getFile();
      final jsonMap = <String, dynamic>{};
      for (final entry in allNotes.entries) {
        jsonMap[entry.key] = entry.value.toJson();
      }

      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonMap);
      await file.writeAsString(jsonStr);
    } catch (e) {
      stderr.writeln('⚠️ Failed to save project note: $e');
    }
  }

  Future<void> deleteNote(String projectPath) async {
    try {
      final allNotes = await loadAllNotes();
      allNotes.remove(projectPath);

      final file = await _getFile();
      final jsonMap = <String, dynamic>{};
      for (final entry in allNotes.entries) {
        jsonMap[entry.key] = entry.value.toJson();
      }

      final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonMap);
      await file.writeAsString(jsonStr);
    } catch (e) {
      stderr.writeln('⚠️ Failed to delete project note: $e');
    }
  }

  Future<List<ProjectNote>> searchNotes(String query) async {
    final allNotes = await loadAllNotes();
    final results = <ProjectNote>[];

    for (final note in allNotes.values) {
      if (note.content.toLowerCase().contains(query.toLowerCase()) ||
          note.tags.any(
            (tag) => tag.toLowerCase().contains(query.toLowerCase()),
          )) {
        results.add(note);
      }
    }

    // Sort by last modified (most recent first)
    results.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return results;
  }

  Future<List<String>> getAllTags() async {
    final allNotes = await loadAllNotes();
    final tags = <String>{};

    for (final note in allNotes.values) {
      tags.addAll(note.tags);
    }

    return tags.toList()..sort();
  }
}
