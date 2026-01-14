#!/usr/bin/env /Users/huy.ly/.puro/envs/stable/flutter/bin/dart

import 'dart:io';
import 'dart:async';

typedef VoidCallback = void Function();

// Usage:
// 1. Make executable: chmod +x flutter_watch.dart
// 2. Run: dart run flutter_watch.dart [args]
// 3. Or: ./flutter_watch.dart [args] (if dart is in PATH)

void main(List<String> args) async {
  final config = _parseArgs(args);
  final runner = _FlutterRunner(flutterArgs: config.flutterArgs);
  final debouncer = _Debouncer(milliseconds: config.debounceMs);

  final exitSignal = ProcessSignal.sigint.watch();
  final termSignal = ProcessSignal.sigterm.watch();
  final exitFuture = Future.any([exitSignal.first, termSignal.first]);

  void onFileChange() {
    debouncer.run(() async {
      print('Restarting flutter run...');
      await runner.restart();
    });
  }

  final watchers = _watchDirectory(
    patterns: config.watchPatterns,
    ignorePatterns: config.ignorePatterns,
    onChange: onFileChange,
  );

  await runner.start();

  await exitFuture;

  for (final watcher in watchers) {
    await watcher.cancel();
  }
  await runner.stop();
  print('\nStopped watching.');
}

_Config _parseArgs(List<String> args) {
  final watchPatterns = <String>['lib/**/*.dart', 'test/**/*.dart'];
  final ignorePatterns = <String>[
    '.dart_tool/**',
    '.flutter-plugins',
    'build/**',
    '.DS_Store',
    '*.g.dart',
    '*.freezed.dart',
  ];
  var debounceMs = 300;
  final flutterArgs = <String>[];

  var i = 0;
  while (i < args.length) {
    final arg = args[i];

    if (arg == '--patterns') {
      if (i + 1 < args.length) {
        watchPatterns.clear();
        watchPatterns.addAll(args[i + 1].split(',').map((p) => p.trim()));
        i += 2;
        continue;
      }
      _usage('Missing value for --patterns');
    } else if (arg == '--ignore') {
      if (i + 1 < args.length) {
        ignorePatterns.clear();
        ignorePatterns.addAll(args[i + 1].split(',').map((p) => p.trim()));
        i += 2;
        continue;
      }
      _usage('Missing value for --ignore');
    } else if (arg == '--debounce-ms') {
      if (i + 1 < args.length) {
        debounceMs = int.tryParse(args[i + 1]) ?? 300;
        i += 2;
        continue;
      }
      _usage('Missing value for --debounce-ms');
    } else if (arg == '--help' || arg == '-h') {
      _printHelp();
      exit(0);
    } else {
      flutterArgs.add(arg);
      i++;
    }
  }

  return _Config(
    watchPatterns: watchPatterns,
    ignorePatterns: ignorePatterns,
    debounceMs: debounceMs,
    flutterArgs: flutterArgs,
  );
}

List<StreamSubscription<FileSystemEvent>> _watchDirectory({
  required List<String> patterns,
  required List<String> ignorePatterns,
  required void Function() onChange,
}) {
  final watchers = <StreamSubscription<FileSystemEvent>>[];
  final currentDir = Directory.current;
  final watchedDirs = <Directory>{};

  bool matchesPattern(String path) {
    final relativePath = path.startsWith(currentDir.path)
        ? path.substring(currentDir.path.length + 1)
        : path;

    for (final ignore in ignorePatterns) {
      if (_matchesGlob(relativePath, ignore)) {
        return false;
      }
    }

    for (final pattern in patterns) {
      if (_matchesGlob(relativePath, pattern)) {
        return true;
      }
    }
    return false;
  }

  void watchDir(Directory dir) {
    if (!dir.existsSync()) return;
    if (watchedDirs.contains(dir)) return;
    watchedDirs.add(dir);

    final sub = dir.watch(recursive: false).listen((event) {
      if (matchesPattern(event.path)) {
        onChange();
      }
    });

    watchers.add(sub);
  }

  for (final pattern in patterns) {
    if (pattern.contains('**')) {
      final parts = pattern.split('**');
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        final dir = Directory(parts[0]);
        if (dir.existsSync()) {
          watchDir(dir);
        }
      } else {
        watchDir(currentDir);
      }
    } else {
      final dir = Directory(pattern.replaceAll('/*', ''));
      if (dir.existsSync()) {
        watchDir(dir);
      }
    }
  }

  return watchers;
}

bool _matchesGlob(String path, String pattern) {
  final regexPattern = pattern
      .replaceAll('*', '[^/]*')
      .replaceAll('?', '[^/]')
      .replaceAllMapped(RegExp(r'\[\!([^]]+)\]'), (m) => '[^${m[1]}]')
      .replaceAll('[', '\\[')
      .replaceAll(']', '\\]')
      .replaceAll('.', '\\.');

  final regex = RegExp('^$regexPattern\$');
  return regex.hasMatch(path);
}

void _printHelp() {
  print('Flutter Watch - Make flutter run watchable');
  print('');
  print('Usage: flutter_watch [OPTIONS] [flutter_run_args...]');
  print('');
  print('Options:');
  print('  --patterns <pats>    Comma-separated glob patterns to watch');
  print('                       (default: lib/**/*.dart,test/**/*.dart)');
  print('  --ignore <pats>      Comma-separated glob patterns to ignore');
  print(
      '                       (default: .dart_tool/**,.flutter-plugins,build/**,.DS_Store,*.g.dart,*.freezed.dart)');
  print('  --debounce-ms <ms>   Debounce delay in milliseconds');
  print('                       (default: 300)');
  print('  -h, --help           Show this help message');
  print('');
  print('Examples:');
  print('  flutter_watch');
  print('  flutter_watch --patterns "lib/**/*.dart" --debounce-ms 500');
  print('  flutter_watch --target lib/main.dart --release');
}

void _usage(String message) {
  stderr.writeln('Error: $message');
  stderr.writeln('Run "flutter_watch --help" for usage information.');
  exit(1);
}

class _Config {
  final List<String> watchPatterns;
  final List<String> ignorePatterns;
  final int debounceMs;
  final List<String> flutterArgs;

  _Config({
    required this.watchPatterns,
    required this.ignorePatterns,
    required this.debounceMs,
    required this.flutterArgs,
  });
}

class _Debouncer {
  final int milliseconds;
  Timer? _timer;

  _Debouncer({required this.milliseconds});

  void run(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), callback);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

class _FlutterRunner {
  Process? _process;
  final List<String> flutterArgs;

  _FlutterRunner({required this.flutterArgs});

  Future<void> start() async {
    await _stopProcess();
    await _runFlutter();
  }

  Future<void> restart() async {
    await _stopProcess();
    await _runFlutter();
  }

  Future<void> stop() async {
    await _stopProcess();
  }

  Future<void> _stopProcess() async {
    if (_process != null) {
      try {
        _process!.kill(ProcessSignal.sigterm);
        await _process!.exitCode.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _process!.kill(ProcessSignal.sigkill);
            return 1;
          },
        );
      } catch (_) {}
      _process = null;
    }
  }

  Future<void> _runFlutter() async {
    try {
      _process =
          await Process.start('puro', ['flutter', 'run', ...flutterArgs]);

      _process!.stdout.listen((data) {
        stdout.add(data);
      });

      _process!.stderr.listen((data) {
        stderr.add(data);
      });

      _process!.exitCode.then((code) {
        if (code != 0) {
          stderr.writeln('flutter run exited with code $code');
        }
        _process = null;
      });
    } catch (e) {
      stderr.writeln('Failed to start flutter: $e');
      exit(1);
    }
  }
}
