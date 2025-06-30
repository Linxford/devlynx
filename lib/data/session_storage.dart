import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class SessionData {
  final String? lastProject;
  final List<String> lastTools;
  final DateTime? lastOpened;
  final String? notes;

  const SessionData({
    this.lastProject,
    this.lastTools = const [],
    this.lastOpened,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'last_project': lastProject,
        'last_tools': lastTools,
        'last_opened': lastOpened?.toIso8601String(),
        'notes': notes,
      };

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      lastProject: json['last_project'] as String?,
      lastTools: List<String>.from(json['last_tools'] ?? []),
      lastOpened: json['last_opened'] != null
          ? DateTime.tryParse(json['last_opened'])
          : null,
      notes: json['notes'] as String?,
    );
  }
}

class SessionStorage {
  final String _configDir = p.join(
    Platform.environment['HOME'] ?? '.',
    '.config',
    'devlynx',
  );
  final String _sessionFile = 'session.json';

  Future<File> _getFile() async {
    final dir = Directory(_configDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(_configDir, _sessionFile));
  }

  Future<SessionData?> loadSession() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return null;

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      return SessionData.fromJson(decoded);
    } catch (e) {
      stderr.writeln('⚠️ Failed to load session: $e');
      return null;
    }
  }

  Future<void> saveSession(SessionData session) async {
    try {
      final file = await _getFile();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(session.toJson());
      await file.writeAsString(jsonStr);
    } catch (e) {
      stderr.writeln('⚠️ Failed to save session: $e');
    }
  }
}
