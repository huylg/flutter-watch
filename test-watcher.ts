#!/usr/bin/env bun

import { watch } from "fs";
import process from "process";

const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  cyan: "\x1b[36m"
};

function log(message: string, color: string = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function testWatcher() {
  log("🧪 Testing file watcher...", colors.cyan);
  log("Watching current directory for .dart file changes", colors.cyan);
  log("Create or modify a .dart file to test (Ctrl+C to stop)\n", colors.yellow);

  const watcher = watch(process.cwd(), { recursive: true }, (event, filename) => {
    if (filename && filename.endsWith('.dart')) {
      log(`✓ Detected ${event} in: ${filename}`, colors.green);
    }
  });

  process.on("SIGINT", () => {
    log("\nStopping watcher...", colors.yellow);
    watcher.close();
    process.exit(0);
  });
}

testWatcher();
