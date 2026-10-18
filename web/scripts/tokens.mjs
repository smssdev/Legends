// Turns docs/design/tokens.json (shared with the future Flutter app) into a
// Tailwind v4 @theme block. Runs before dev and build; the output is generated.
import fs from 'node:fs';

const src = new URL('../../docs/design/tokens.json', import.meta.url);
const out = new URL('../src/styles/tokens.css', import.meta.url);
const t = JSON.parse(fs.readFileSync(src, 'utf8'));

const kebab = (s) => s.replace(/[A-Z]/g, (c) => '-' + c.toLowerCase());
const vars = [];

for (const [name, value] of Object.entries(t.color)) vars.push(`--color-${kebab(name)}: ${value};`);
for (const [line, { bg, fg }] of Object.entries(t.line)) {
  vars.push(`--color-line-${line}: ${bg};`, `--color-line-${line}-fg: ${fg};`);
}
for (const [level, { color }] of Object.entries(t.fitness)) vars.push(`--color-fitness-${level}: ${color};`);
for (const [name, { family }] of Object.entries(t.font).filter(([k]) => !k.startsWith('$'))) {
  vars.push(`--font-${name}: '${family}', sans-serif;`);
}
for (const [name, px] of Object.entries(t.size.radius)) vars.push(`--radius-${name}: ${px}px;`);
vars.push(`--spacing-touch: ${t.size.touchMin}px;`);

fs.mkdirSync(new URL('.', out), { recursive: true });
fs.writeFileSync(out, `/* Generated from docs/design/tokens.json by scripts/tokens.mjs. Do not edit. */\n@theme {\n  ${vars.join('\n  ')}\n}\n`);
console.log(`tokens: ${vars.length} variables`);
