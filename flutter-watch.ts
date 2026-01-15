#!/usr/bin/env bun

import { watch } from "fs";
import process from "process";

const DEBOUNCE_MS = 300;
const FLUTTER_READY_REGEX = /Flutter run key commands|The Flutter DevTools/;

let flutterProc: ReturnType<typeof Bun.spawn> | null = null;
let reloadCount = 0;
let isFlutterReady = false;
let debounceTimer: ReturnType<typeof setTimeout> | null = null;
let watcher: ReturnType<typeof watch> | null = null;

const colors = {
  reset: "\x1b[0m",
  bright: "\x1b[1m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
};

function log(message: string, color: string = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function parseArgs(args: string[]): {
  flutterArgs: string[];
  watchPath: string;
} {
  const flutterArgs: string[] = [];
  const watchPath = process.cwd();

  for (let i = 0; i < args.length; i++) {
    flutterArgs.push(args[i]);
  }

  return { flutterArgs, watchPath };
}

function setupStdinPassthrough() {
  if (!flutterProc?.stdin || typeof flutterProc.stdin === "number") {
    return;
  }

  process.stdin.setRawMode(true);
  process.stdin.resume();

  process.stdin.on("data", (data: Uint8Array) => {
    for (const byte of data) {
      if (byte === 3) {
        process.kill(process.pid, "SIGINT");
        return;
      }
      if (byte === 26) {
        process.kill(process.pid, "SIGTSTP");
        return;
      }
    }

    if (flutterProc?.stdin && typeof flutterProc.stdin !== "number") {
      flutterProc.stdin.write(data);
      flutterProc.stdin.flush();
    }
  });
}

function startFlutterProcess(args: string[]) {
  log("Starting Flutter process...", colors.cyan);

  flutterProc = Bun.spawn(["puro", "flutter", "run", ...args], {
    stdout: "pipe",
    stderr: "inherit",
    stdin: "pipe",
    onExit(proc, exitCode) {
      log(`Flutter process exited with code ${exitCode}`, colors.yellow);
      cleanup();
      process.exit(exitCode || 0);
    },
  });

  const stdoutReader = flutterProc.stdout.getReader();
  async function readStdout() {
    while (true) {
      const { done, value } = await stdoutReader.read();
      if (done) break;

      const text = new TextDecoder().decode(value);
      process.stdout.write(text);

      if (FLUTTER_READY_REGEX.test(text)) {
        isFlutterReady = true;
        log("\n✓ Flutter is ready for hot reload!", colors.green);
      }
    }
  }
  readStdout();

  log(`Flutter process started (PID: ${flutterProc.pid})`, colors.green);

  setupStdinPassthrough();
}

function triggerHotReload(filePath: string) {
  if (!flutterProc || flutterProc.killed || !isFlutterReady) {
    return;
  }

  const stdin = flutterProc.stdin;
  if (!stdin || typeof stdin === "number") {
    return;
  }

  reloadCount++;
  const timestamp = new Date().toLocaleTimeString();
  log(
    `\n[${timestamp}] Hot reload #${reloadCount} triggered by: ${filePath}`,
    colors.bright + colors.green,
  );

  const encoder = new TextEncoder();
  stdin.write(encoder.encode("r"));
  stdin.flush();
}

function handleFileChange(event: string, filename: string | null) {
  const timestamp = new Date().toLocaleTimeString();
  log(`[${timestamp}] ${event}: ${filename || "unknown"}`, colors.reset);

  if (!filename || !filename.endsWith(".dart")) {
    return;
  }

  if (debounceTimer) {
    clearTimeout(debounceTimer);
  }

  debounceTimer = setTimeout(() => {
    triggerHotReload(filename);
    debounceTimer = null;
  }, DEBOUNCE_MS);
}

function setupWatcher(watchPath: string) {
  log(`Watching for .dart file changes in: ${watchPath}`, colors.cyan);

  watcher = watch(watchPath, { recursive: true }, (event, filename) => {
    handleFileChange(event, filename);
  });

  log("Watcher started. Press Ctrl+C to stop.", colors.green);
}

function cleanup() {
  log("\nShutting down...", colors.yellow);

  if (watcher) {
    watcher.close();
    watcher = null;
  }

  if (debounceTimer) {
    clearTimeout(debounceTimer);
    debounceTimer = null;
  }

  process.stdin.setRawMode(false);
  process.stdin.pause();

  if (flutterProc && !flutterProc.killed) {
    log("Stopping Flutter process...", colors.yellow);
    flutterProc.kill();
  }
}

function setupSignalHandlers() {
  const handleShutdown = () => {
    cleanup();
    process.exit(0);
  };

  process.on("SIGINT", handleShutdown);
  process.on("SIGTERM", handleShutdown);
}

async function main() {
  const { flutterArgs, watchPath } = parseArgs(process.argv.slice(2));

  log("🚀 Flutter Watch - Auto Hot Reload", colors.bright + colors.blue);
  log("=".repeat(50), colors.blue);

  setupSignalHandlers();
  startFlutterProcess(flutterArgs);
  setupWatcher(watchPath);

  log(`Watching .dart files (debounce: ${DEBOUNCE_MS}ms)`, colors.yellow);
  log("\nWaiting for Flutter to be ready for hot reload...\n", colors.cyan);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
