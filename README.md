# Flutter Watch

A simple wrapper tool to make `flutter run` watchable.

## Features

- Automatically restarts `flutter run` when files change
- Configurable file patterns to watch
- Configurable ignore patterns
- Debounce mechanism (default: 300ms) to prevent excessive restarts
- Graceful process handling and clean shutdown

## Installation

No installation required. Just ensure you have Dart installed and in your PATH.

## Usage

```bash
# Run with default settings (watches lib/ and test/)
dart run flutter_watch.dart

# Or make executable and run directly
chmod +x flutter_watch.dart
./flutter_watch.dart

# Custom watch patterns
dart run flutter_watch.dart --patterns "lib/**/*.dart,config/**/*.yaml"

# Custom debounce duration
dart run flutter_watch.dart --debounce-ms 500

# Pass Flutter arguments
dart run flutter_watch.dart --target lib/main.dart --release

# Combined options
dart run flutter_watch.dart --patterns "lib/**/*.dart" --debounce-ms 200 --target lib/main.dart
```

## Options

- `--patterns <pats>` - Comma-separated glob patterns to watch (default: `lib/**/*.dart,test/**/*.dart`)
- `--ignore <pats>` - Comma-separated glob patterns to ignore (default: `.dart_tool/**,.flutter-plugins,build/**,.DS_Store,*.g.dart,*.freezed.dart`)
- `--debounce-ms <ms>` - Debounce delay in milliseconds (default: 300)
- `-h, --help` - Show help message

## Default Behavior

- **Watch patterns**: `lib/**/*.dart`, `test/**/*.dart`
- **Ignore patterns**: `.dart_tool/**`, `.flutter-plugins`, `build/**`, `.DS_Store`, `*.g.dart`, `*.freezed.dart`
- **Debounce**: 300ms

## How It Works

1. Monitors specified directories for file changes
2. When a file matching the watch patterns changes:
   - Waits 300ms (debounce) for more changes
   - Stops the current `flutter run` process
   - Starts a new `flutter run` process
3. Forwards Flutter output to your console
4. Handles Ctrl+C gracefully to stop watching and clean up

## Requirements

- Dart SDK (tested with >=3.0.0)
- Flutter SDK in your PATH
