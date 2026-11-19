import { config } from "./config.ts";

const LEVELS = ["debug", "info", "warn", "error"] as const;
type Level = (typeof LEVELS)[number];

export function log(level: Level, message: string): void {
  // messages below the configured level are dropped
  if (LEVELS.indexOf(level) < LEVELS.indexOf(config.LOG_LEVEL)) return;
  const line = `${level.padEnd(5)} ${message}`;
  if (level === "error") console.error(line);
  else console.log(line);
}
