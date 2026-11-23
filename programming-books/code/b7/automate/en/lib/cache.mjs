import crypto from "node:crypto";
import fs from "node:fs";
import {ask} from "./ask.mjs";

// The same item is never asked twice: answers are kept in a file, by the
// hash of the request.
const FILE = "cache.json";
const saved = fs.existsSync(FILE) ? JSON.parse(fs.readFileSync(FILE, "utf8")) : {};
export const stats = {asked: 0, cached: 0};

export async function cachedAsk(prompt, options = {}) {
  const key = crypto.createHash("sha256").update(prompt).digest("hex").slice(0, 16);
  if (key in saved) {
    stats.cached++;
    return saved[key];
  }
  stats.asked++;
  saved[key] = await ask(prompt, options);
  fs.writeFileSync(FILE, JSON.stringify(saved, null, 1));
  return saved[key];
}
