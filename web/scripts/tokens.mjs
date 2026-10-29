// Turns docs/design/tokens.json (shared with the future Flutter app) into a
// Tailwind v4 @theme block. Runs before dev and build; the output is generated.
// [X56] And the day theme: colorLight on html.light (the utilities read the same variables), the night's own colours
// again inside .theme-night (the match broadcast), and the accents' text in their darker ink on paper.
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

const own = (o) => Object.entries(o).filter(([k]) => !k.startsWith('$'));
const day = own(t.colorLight).map(([name, value]) => `--color-${kebab(name)}: ${value};`);
const night = own(t.colorLight).map(([name]) => `--color-${kebab(name)}: ${t.color[name]};`);
// Unlayered and of no weight at all (:where), so it beats the utility it darkens but not a row's own colour (.is-mine).
const ink = own(t.ink).map(([name, value]) => {
  const c = `text-${kebab(name)}`;
  return `:where(html.light :is(.${c}, .hover\\:${c}:hover, .focus-visible\\:${c}:focus-visible)):not(:where(.theme-night, .theme-night *)) { color: ${value}; }`;
});

fs.mkdirSync(new URL('.', out), { recursive: true });
fs.writeFileSync(out, `/* Generated from docs/design/tokens.json by scripts/tokens.mjs. Do not edit. */
@theme {
  ${vars.join('\n  ')}
}
html.light {
  color-scheme: light;
  ${day.join('\n  ')}
}
html.light .theme-night {
  color-scheme: dark;
  color: var(--color-text);
  ${night.join('\n  ')}
}
${ink.join('\n')}
`);
console.log(`tokens: ${vars.length} variables, ${day.length} for the day theme`);
