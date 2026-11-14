// [Sprint 54 W6] The design system binds: a screen draws through the components (components/ui), not with its own
// copy of their shape. Every .vue under pages/, layouts/ and components/ (but components/ui, where the shapes live)
// is read for four things, and the build stops on any new one:
//   button   a raw <button>, <a> or <RouterLink> painted gold or brand (UiButton is the button)
//   card     rounded-xl/2xl with bg-surface in one class list (UiCard is the card)
//   px-text  text-[Npx] or text-[Nrem] (the type scale is the text-caption … text-display roles)
//   hex      a #hex colour (tokens.json is the palette; --color-broadcast-* for the match's TV look)
// Files not yet moved to the components are counted in scripts/design-baseline.json: a file may go down, never up,
// and the list shrinks as Sprint 56 rebuilds each screen. `npm run design -- --write` rewrites it after a migration.
// Lasting exceptions (a flag's or a social network's own colours) are in KEEP below.
// (Not ESLint: the project has no linter, and four patterns over the templates did not need one; it runs before every
// build like scripts/i18n.mjs.)
import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs'
import { join, relative } from 'node:path'

const KEEP = new Set([
  'src/components/PublicFooter.vue', // the social networks' own colours
])
const BASE = 'scripts/design-baseline.json'
const files = []
const walk = (d) =>
  readdirSync(d).forEach((f) => {
    const p = join(d, f)
    statSync(p).isDirectory() ? walk(p) : f.endsWith('.vue') && files.push(p)
  })
for (const d of ['src/pages', 'src/layouts', 'src/components']) walk(d)

const TAG = /<(button|a|RouterLink)\b((?:[^>"']|"[^"]*"|'[^']*')*)>/g
const CLASSES = /(?:^|\s):?class="([^"]*)"/g
const strong = (c) => /(?<![\w/-])bg-(gold|brand)(?![\w/-])/.test(c)

function count(src) {
  const n = { button: 0, card: 0, 'px-text': 0, hex: 0 }
  for (const m of src.matchAll(TAG))
    for (const c of m[2].matchAll(CLASSES))
      if (strong(c[1])) {
        n.button++
        break
      }
  for (const c of src.matchAll(CLASSES))
    if (/(?<![\w-])rounded-(xl|2xl)(?![\w-])/.test(c[1]) && /(?<![\w/-])bg-surface(?![\w/-])/.test(c[1])) n.card++
  n['px-text'] = [...src.matchAll(/text-\[\d*\.?\d+(px|rem)\]/g)].length
  n.hex = [
    ...src
      .replace(/<!--[\s\S]*?-->/g, '')
      .replace(/\/\*[\s\S]*?\*\//g, '')
      .matchAll(/#[0-9a-fA-F]{3,8}(?![\w-])/g),
  ].length
  return n
}

const now = {}
for (const f of files) {
  const rel = relative('.', f).split('\\').join('/')
  if (rel.startsWith('src/components/ui/') || KEEP.has(rel)) continue
  const n = count(readFileSync(f, 'utf8'))
  const hit = Object.fromEntries(Object.entries(n).filter(([, v]) => v))
  if (Object.keys(hit).length) now[rel] = hit
}

if (process.argv.includes('--write')) {
  writeFileSync(BASE, JSON.stringify(Object.fromEntries(Object.entries(now).sort()), null, 2) + '\n')
  console.log(`design: ${Object.keys(now).length} files not yet on the components, written to ${BASE}`)
  process.exit(0)
}

const base = JSON.parse(readFileSync(BASE, 'utf8'))
const bad = []
for (const [f, hit] of Object.entries(now))
  for (const [k, v] of Object.entries(hit)) if (v > (base[f]?.[k] ?? 0)) bad.push(`${f}: ${k} ${base[f]?.[k] ?? 0} → ${v}`)
const shrunk = Object.entries(base).filter(([f, hit]) => Object.entries(hit).some(([k, v]) => (now[f]?.[k] ?? 0) < v)).length
if (bad.length) {
  console.error("design: a screen drew a component's shape itself (use components/ui; see scripts/design.mjs):\n  " + bad.join('\n  '))
  process.exit(1)
}
console.log(
  `design: OK (${Object.keys(now).length} files still to move${shrunk ? `; ${shrunk} went down, run npm run design -- --write` : ''})`,
)
