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
// [Sprint 54 D1] The touch target in px (never rem: W-D24), the type scale's six
// roles (text-caption ... text-display-lg, each with its line height and weight), the spacing steps as --space-*, the three shadows, the motion, and
// the broadcast's colours.
vars.push(`--spacing-touch: ${t.touch.web}px;`);
const own0 = (o) => Object.entries(o).filter(([k]) => !k.startsWith('$'));
// Plain variables (var(--space-md)), not Tailwind's spacing namespace: --spacing-md would turn max-w-md into 12px.
for (const [name, px] of own0(t.spacing)) vars.push(`--space-${name}: ${px}px;`);
for (const [name, r] of own0(t.type)) {
  const k = kebab(name);
  vars.push(`--text-${k}: ${r.size}px;`, `--text-${k}--line-height: ${r.line};`, `--text-${k}--font-weight: ${r.weight};`);
}
for (const [name, s] of own0(t.shadow)) {
  vars.push(`--shadow-${name}: 0 ${s.y}px ${s.blur}px ${s.spread}px color-mix(in srgb, var(--color-shade) ${Math.round(s.alpha * 100)}%, transparent);`);
}
vars.push(`--ease-soft: cubic-bezier(${t.motion.easeSoft.join(', ')});`, `--ease-spring: cubic-bezier(${t.motion.easeSpring.join(', ')});`);
for (const d of ['fast', 'base', 'slow']) vars.push(`--duration-${d}: ${t.motion[d]}ms;`);
for (const [name, value] of own0(t.broadcast)) vars.push(`--color-broadcast-${kebab(name)}: ${value};`);

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
