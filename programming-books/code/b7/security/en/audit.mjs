import crypto from "node:crypto";
import fs from "node:fs";
import {redact} from "./lib/pii.mjs";

// An audit log that can prove what was sent, without keeping what was
// sent.
export function audit(user, prompt) {
  const {safe} = redact(prompt);
  const entry = {
    time: "2026-11-24T10:00:00Z",
    user: crypto.createHash("sha256").update(`salt:${user}`).digest("hex").slice(0, 12),
    prompt: safe,
    hash: crypto.createHash("sha256").update(prompt).digest("hex").slice(0, 16),
  };
  fs.appendFileSync("audit.log", `${JSON.stringify(entry)}\n`);
  return entry;
}

console.log(audit("mona@example.com", "Hi, this is Mona Hassan (mona.hassan@example.com, 0101 234 5678). My card 4111 1111 1111 1111 was charged twice for order 41."));
