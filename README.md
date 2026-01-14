# Flutter Watch

Auto hot reload wrapper for Flutter CLI. Automatically triggers hot reload when `.dart` files change.

## Features

- 🚀 Automatic hot reload on Dart file changes
- ⚡ Built with Bun for fast startup and low overhead
- 🎯 Uses Bun's native `fs.watch` API
- 📦 Debounces file changes to avoid rapid reloads
- 🔄 Passes all Flutter run arguments through
- 🛡️ Graceful shutdown handling

## Installation

### Prerequisites
- [Bun](https://bun.sh) (>= 1.0.0)
- [Flutter](https://flutter.dev/docs/get-started/install)

### Local Use

```bash
git clone <repository>
cd flutter-watch
bun install
```

### Global Installation

```bash
bun install -g
```

Or link locally:

```bash
bun link
```

## Usage

### Basic Usage

Run in your Flutter project directory:

```bash
bun run flutter-watch.ts
```

Or if installed globally:

```bash
flutter-watch
```

### With Flutter Arguments

All arguments after the script are passed to `flutter run`:

```bash
bun run flutter-watch.ts --device macos
bun run flutter-watch.ts --device chrome --web-port 8080
bun run flutter-watch.ts --release
```

### Examples

```bash
# Watch current directory
bun run flutter-watch.ts

# Run on iOS device
bun run flutter-watch.ts --device ios

# Run in release mode
bun run flutter-watch.ts --release

# Run with custom flavor
bun run flutter-watch.ts --flavor production
```

## Build Standalone Executable

Build a standalone binary that doesn't require Bun to be installed:

```bash
bun run build
```

This creates a standalone `flutter-watch` executable in the current directory (approx. 50-60MB, includes Bun runtime). You can then run it directly:

```bash
# Move to PATH or run from current directory
./flutter-watch --device macos

# Or move to a directory in your PATH
sudo mv flutter-watch /usr/local/bin/
flutter-watch --device macos
```

The compiled binary works on the same platform it was built on (macOS, Linux, or Windows).

## How It Works

1. **Spawns** a `flutter run` process with your provided arguments
2. **Watches** for changes to `.dart` files recursively using Bun's `fs.watch`
3. **Debounces** file changes (2 seconds by default) to prevent multiple rapid reloads
4. **Sends** the hot reload command (`r`) to the Flutter process when files change
5. **Displays** colored output showing reload events and file changes

## Output Example

```
🚀 Flutter Watch - Auto Hot Reload
==================================================
Starting Flutter process...
Flutter process started (PID: 12345)
Watching for .dart file changes in: /Users/user/project
Watcher started. Press Ctrl+C to stop.
Watching .dart files (debounce: 2000ms)

Waiting for Flutter to be ready for hot reload...

[23:45:12] Hot reload #1 triggered by: lib/main.dart
[23:45:45] Hot reload #2 triggered by: lib/widgets/button.dart
```

## Stopping

Press `Ctrl+C` to gracefully stop the watcher and Flutter process.

## Configuration

The script has built-in defaults, but you can modify them by editing `flutter-watch.ts`:

- `DEBOUNCE_MS`: Time to wait before triggering reload (default: 2000ms)
- `FLUTTER_READY_REGEX`: Pattern to detect when Flutter is ready for hot reload

## Limitations

- Only watches `.dart` files (assets and other files require full restart)
- Requires Flutter to be installed and available in PATH
- Requires Bun runtime (not compatible with Node.js directly)

## Troubleshooting

### Hot reload not working

1. Ensure Flutter process is running and ready (look for "Flutter run key commands" in output)
2. Check that you're editing `.dart` files (only these trigger hot reload)
3. Verify the watch path is correct

### Permission errors

If you get permission errors watching directories, check file system permissions or try running with appropriate permissions.

## License

MIT
