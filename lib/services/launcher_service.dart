import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/project_scanner.dart';

class LauncherService {
  /// Launches the selected project using appropriate tools
  Future<void> launchProject(Project project) async {
    final String path = project.path;
    final String type = project.type;

    debugPrint('🚀 Launching "${project.name}" [$type]');

    try {
      switch (type) {
        case 'flutter':
          await _openInEditor(path);
          await _runInTerminal('flutter run', workingDir: path);
          break;

        case 'react':
        case 'nextjs':
          await _openInEditor(path);
          if (await _hasScript(path, 'dev')) {
            await _runInTerminal('npm run dev', workingDir: path);
          } else if (await _hasScript(path, 'start')) {
            await _runInTerminal('npm start', workingDir: path);
          }
          break;

        case 'vue':
          await _openInEditor(path);
          if (await _hasScript(path, 'dev')) {
            await _runInTerminal('npm run dev', workingDir: path);
          } else if (await _hasScript(path, 'serve')) {
            await _runInTerminal('npm run serve', workingDir: path);
          }
          break;

        case 'angular':
          await _openInEditor(path);
          await _runInTerminal('ng serve', workingDir: path);
          break;

        case 'svelte':
          await _openInEditor(path);
          await _runInTerminal('npm run dev', workingDir: path);
          break;

        case 'node':
          await _openInEditor(path);
          if (await _hasScript(path, 'dev')) {
            await _runInTerminal('npm run dev', workingDir: path);
          } else if (await _hasScript(path, 'start')) {
            await _runInTerminal('npm start', workingDir: path);
          }
          break;

        case 'python':
          await _openInEditor(path);
          if (await File('$path/main.py').exists()) {
            await _runInTerminal('python main.py', workingDir: path);
          } else if (await File('$path/app.py').exists()) {
            await _runInTerminal('python app.py', workingDir: path);
          } else if (await File('$path/manage.py').exists()) {
            await _runInTerminal(
              'python manage.py runserver',
              workingDir: path,
            );
          }
          break;

        case 'rust':
          await _openInEditor(path);
          await _runInTerminal('cargo run', workingDir: path);
          break;

        case 'go':
          await _openInEditor(path);
          await _runInTerminal('go run .', workingDir: path);
          break;

        case 'java':
          await _openInEditor(path);
          if (await File('$path/pom.xml').exists()) {
            await _runInTerminal('mvn spring-boot:run', workingDir: path);
          } else if (await File('$path/build.gradle').exists()) {
            await _runInTerminal('./gradlew bootRun', workingDir: path);
          }
          break;

        case 'docker':
          await _openInEditor(path);
          await _runInTerminal('docker-compose up -d', workingDir: path);
          break;

        case 'git':
          await _openInEditor(path);
          break;

        default:
          await _openInEditor(path);
          debugPrint('⚠️ No specific launcher configured for type: $type');
      }
    } catch (e) {
      stderr.writeln('❌ Error launching project: $e');
    }
  }

  /// Quick actions for projects
  Future<void> runQuickAction(Project project, String action) async {
    final path = project.path;

    try {
      switch (action) {
        case 'terminal':
          await _openTerminal(path);
          break;
        case 'explorer':
          await _openFileManager(path);
          break;
        case 'browser':
          await _openInBrowser('http://localhost:3000');
          break;
        case 'build':
          await _buildProject(project);
          break;
        case 'test':
          await _testProject(project);
          break;
        case 'install':
          await _installDependencies(project);
          break;
      }
    } catch (e) {
      stderr.writeln('❌ Error running action "$action": $e');
    }
  }

  Future<void> _buildProject(Project project) async {
    final path = project.path;
    switch (project.type) {
      case 'flutter':
        await _runInTerminal('flutter build linux', workingDir: path);
        break;
      case 'react':
      case 'nextjs':
      case 'vue':
      case 'svelte':
      case 'node':
        await _runInTerminal('npm run build', workingDir: path);
        break;
      case 'rust':
        await _runInTerminal('cargo build --release', workingDir: path);
        break;
      case 'go':
        await _runInTerminal('go build', workingDir: path);
        break;
      case 'java':
        if (await File('$path/pom.xml').exists()) {
          await _runInTerminal('mvn clean package', workingDir: path);
        } else {
          await _runInTerminal('./gradlew build', workingDir: path);
        }
        break;
    }
  }

  Future<void> _testProject(Project project) async {
    final path = project.path;
    switch (project.type) {
      case 'flutter':
        await _runInTerminal('flutter test', workingDir: path);
        break;
      case 'react':
      case 'nextjs':
      case 'vue':
      case 'svelte':
      case 'node':
        await _runInTerminal('npm test', workingDir: path);
        break;
      case 'rust':
        await _runInTerminal('cargo test', workingDir: path);
        break;
      case 'go':
        await _runInTerminal('go test ./...', workingDir: path);
        break;
      case 'python':
        await _runInTerminal('python -m pytest', workingDir: path);
        break;
    }
  }

  Future<void> _installDependencies(Project project) async {
    final path = project.path;
    switch (project.type) {
      case 'flutter':
        await _runInTerminal('flutter pub get', workingDir: path);
        break;
      case 'react':
      case 'nextjs':
      case 'vue':
      case 'svelte':
      case 'node':
        await _runInTerminal('npm install', workingDir: path);
        break;
      case 'rust':
        await _runInTerminal('cargo fetch', workingDir: path);
        break;
      case 'python':
        await _runInTerminal(
          'pip install -r requirements.txt',
          workingDir: path,
        );
        break;
    }
  }

  /// Opens project folder in VS Code (or fallback editor)
  Future<void> _openInEditor(String path) async {
    final editors = ['code', 'cursor', 'nvim', 'vim'];
    for (final editor in editors) {
      if (await _isCommandAvailable(editor)) {
        await _runDetached(editor, [path]);
        return;
      }
    }
    stderr.writeln('❌ No supported editor found.');
  }

  /// Opens terminal in project directory
  Future<void> _openTerminal(String path) async {
    final terminals = [
      'gnome-terminal',
      'konsole',
      'xterm',
      'alacritty',
      'kitty',
      'foot',
      'wezterm',
      'qterminal',
      'terminator',
      'terminix',
      'termite',
      'powershell',
      'cmd',
    ];
    for (final terminal in terminals) {
      if (await _isCommandAvailable(terminal)) {
        if (terminal == 'gnome-terminal') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else if (terminal == 'konsole') {
          await _runDetached(terminal, ['--workdir', path]);
        } else if (terminal == 'alacritty') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else if (terminal == 'kitty') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else if (terminal == 'foot') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else if (terminal == 'wezterm') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else if (terminal == 'qterminal') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else if (terminal == 'terminator') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else if (terminal == 'terminix') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else if (terminal == 'termite') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else if (terminal == 'powershell') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else if (terminal == 'cmd') {
          await _runDetached(terminal, ['--working-directory=$path']);
        } else {
          await _runDetached(terminal, [
            '-e',
            'bash',
            '-c',
            'cd "$path" && bash',
          ]);
        }
        return;
      }
    }
    stderr.writeln('❌ No supported terminal found.');
  }

  /// Opens file manager in project directory
  Future<void> _openFileManager(String path) async {
    if (Platform.isLinux) {
      await _runDetached('xdg-open', [path]);
    }
  }

  /// Opens URL in browser
  Future<void> _openInBrowser(String url) async {
    if (Platform.isLinux) {
      await _runDetached('xdg-open', [url]);
    }
  }

  /// Runs shell command in terminal emulator
  Future<void> _runInTerminal(
    String command, {
    required String workingDir,
  }) async {
    final terminals = [
      'gnome-terminal',
      'konsole',
      'xterm',
      'alacritty',
      'kitty',
      'foot',
      'wezterm',
      'qterminal',
      'terminator',
      'terminix',
      'termite',
      'powershell',
      'cmd',
    ];

    for (final terminal in terminals) {
      if (await _isCommandAvailable(terminal)) {
        if (terminal == 'gnome-terminal') {
          await _runDetached(terminal, [
            '--working-directory=$workingDir',
            '--',
            'bash',
            '-c',
            '$command; read -p "Press Enter to continue..."',
          ]);
        } else if (terminal == 'konsole') {
          await _runDetached(terminal, [
            '--workdir',
            workingDir,
            '-e',
            'bash',
            '-c',
            '$command; read -p "Press Enter to continue..."',
          ]);
        } else {
          await _runDetached(terminal, [
            '-e',
            'bash',
            '-c',
            'cd "$workingDir" && $command; read -p "Press Enter to continue..."',
          ]);
        }
        return;
      }
    }

    stderr.writeln('❌ No supported terminal found.');
  }

  /// Launches process directly without shell
  Future<void> _runDetached(String executable, List<String> args) async {
    await Process.start(executable, args, mode: ProcessStartMode.detached);
  }

  /// Checks if a script exists in package.json
  Future<bool> _hasScript(String path, String scriptName) async {
    final file = File('$path/package.json');
    if (!await file.exists()) return false;

    final content = await file.readAsString();
    return content.contains('"$scriptName"');
  }

  /// Checks if a CLI command exists in the system PATH
  Future<bool> _isCommandAvailable(String command) async {
    final result = await Process.run('which', [command]);
    return result.exitCode == 0;
  }
}
