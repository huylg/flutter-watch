import type { Subprocess as BunSubprocess } from "bun";

export type Subprocess = BunSubprocess;

export interface FSWatcher {
  close(): void;
}

export interface WatchOptions {
  recursive?: boolean;
}

export type WatchCallback = (event: "rename" | "change", filename: string | Buffer | null) => void;
