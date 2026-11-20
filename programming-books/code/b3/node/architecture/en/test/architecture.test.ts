import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { test } from "node:test";

// which folders each layer may import from
const rules: Record<string, RegExp> = {
  "order.ts": /^$/,
  "ports.ts": /^\.\/order\.ts$/,
  "place-order.ts": /^\.\/(order|ports)\.ts$/,
};

test("each layer imports only what it may", () => {
  const folder = "src/orders";
  for (const file of readdirSync(folder)) {
    const allowed = rules[file];
    if (!allowed) continue;
    const source = readFileSync(`${folder}/${file}`, "utf8");
    for (const [, from] of source.matchAll(/from "([^"]+)"/g)) {
      assert.match(from!, allowed, `${file} must not import ${from}`);
    }
  }
});
