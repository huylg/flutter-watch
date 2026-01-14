# Quick Start

## Installation

```bash
# Clone the repository
git clone <repository>
cd flutter-watch

# No dependencies needed - just Bun and Flutter
```

## Usage

```bash
# Run in your Flutter project
bun run flutter-watch.ts

# Or make it executable and run directly
chmod +x flutter-watch.ts
./flutter-watch.ts

# Pass Flutter arguments
bun run flutter-watch.ts --device macos

# Watch different directory
bun run flutter-watch.ts --path /path/to/project

# Build standalone executable (no Bun needed)
bun run build
./flutter-watch --device macos
```

## Test File Watcher (without Flutter)

```bash
bun run test-watcher.ts
```

## What Happens

1. Flutter starts normally with `flutter run`
2. Script watches all `.dart` files recursively
3. When you save a `.dart` file, it auto-triggers hot reload
4. Press Ctrl+C to stop both watcher and Flutter

## Requirements

- Bun (>= 1.0.0)
- Flutter installed and in PATH

## Tips

- Works best for development (not production builds)
- Only .dart files trigger hot reload
- Assets/config changes need manual restart (press 'R')
- 2-second debounce prevents spam reloads during batch saves
