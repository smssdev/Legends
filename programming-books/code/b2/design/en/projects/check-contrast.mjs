// en/projects/check-contrast.ts
import { readFileSync } from "node:fs";
var tokens = JSON.parse(readFileSync(new URL("../tokens.json", import.meta.url), "utf8"));
function luminance(hex) {
  const [r, g, b] = [1, 3, 5].map((i) => {
    const c = parseInt(hex.slice(i, i + 2), 16) / 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}
function contrast(a, b) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}
var PAIRS = [
  ["text", "surface"],
  ["text-muted", "surface"],
  ["action-text", "action"],
  ["action-soft-text", "action-soft"],
  ["danger", "danger-soft"],
  ["success", "success-soft"],
  ["warning", "warning-soft"]
];
var failures = 0;
for (const [theme, colours] of Object.entries(tokens.semantic)) {
  for (const [fg, bg] of PAIRS) {
    const ratio = contrast(tokens.primitive[colours[fg]], tokens.primitive[colours[bg]]);
    const ok = ratio >= 4.5;
    if (!ok) failures++;
    console.log(`${theme.padEnd(5)} ${`${fg} / ${bg}`.padEnd(32)} ${ratio.toFixed(2).padStart(5)} ${ok ? "\u2713" : "\u2717 below 4.5"}`);
  }
}
console.log(failures === 0 ? "All pairs pass WCAG AA." : `${failures} pairs fail. Fix the tokens before releasing.`);
process.exitCode = failures === 0 ? 0 : 1;
