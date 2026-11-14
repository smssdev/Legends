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

// [Sprint 65 W3] The same rule for a scoped style: --ink-<name> is the accent at night and its ink by day.
const inkVars = own(t.ink).map(([name]) => `--ink-${kebab(name)}: var(--color-${kebab(name)});`);
const inkDay = own(t.ink).map(([name, value]) => `--ink-${kebab(name)}: ${value};`);

// [Sprint 65 W3] Every pair in tokens.json contrast, at night and by day: the build stops below its ratio.
const lum = (hex) => {
  const c = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((x) => (x <= 0.03928 ? x / 12.92 : ((x + 0.055) / 1.055) ** 2.4));
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
};
const ratio = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
const short = [];
for (const look of ['night', 'day']) {
  const pal = { ...t.color, ...(look === 'day' ? Object.fromEntries(own(t.colorLight)) : {}) };
  const pick = (n) => (n.startsWith('ink:') ? (look === 'day' ? t.ink[n.slice(4)] ?? pal[n.slice(4)] : pal[n.slice(4)]) : pal[n]);
  const check = (fg, bg, min, what) => {
    const a = pick(fg) ?? fg, b = pal[bg] ?? bg;
    if (!/^#[0-9A-Fa-f]{6}$/.test(a) || !/^#[0-9A-Fa-f]{6}$/.test(b)) { short.push(`${look}: ${what} is not a colour`); return; }
    const r = ratio(a, b);
    if (r < min) short.push(`${look}: ${what} ${r.toFixed(2)} < ${min}`);
  };
  for (const kind of ['text', 'marks']) for (const fg of t.contrast[kind].fg) for (const g of t.contrast.grounds) check(fg, g, t.contrast[kind].min, `${fg} on ${g}`);
  for (const [fg, bg] of t.contrast.fills.pairs) {
    if (fg.startsWith('line:')) { const l = t.line[fg.slice(5)]; check(l.fg, l.bg, t.contrast.fills.min, `${fg} badge`); }
    else check(fg, bg, t.contrast.fills.min, `${fg} on ${bg}`);
  }
}
if (short.length) {
  console.error(`tokens: ${short.length} colour pair(s) under their contrast\n  ${short.join('\n  ')}`);
  process.exit(1);
}

fs.mkdirSync(new URL('.', out), { recursive: true });
fs.writeFileSync(out, `/* Generated from docs/design/tokens.json by scripts/tokens.mjs. Do not edit. */
@theme {
  ${vars.join('\n  ')}
}
:root {
  ${inkVars.join('\n  ')}
}
html.light {
  color-scheme: light;
  ${day.join('\n  ')}
  ${inkDay.join('\n  ')}
}
html.light .theme-night {
  color-scheme: dark;
  color: var(--color-text);
  ${night.join('\n  ')}
  ${inkVars.join('\n  ')}
}
${ink.join('\n')}
`);
console.log(`tokens: ${vars.length} variables, ${day.length} for the day theme, every contrast pair met`);
