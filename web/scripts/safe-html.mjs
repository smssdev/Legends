// [Sprint 57 W5] No value reaches the page as HTML unescaped: in every `.innerHTML = \`…\`` template under src/, each
// ${…} is esc(…) (match/feed/art.ts) or one of the drawing's own values below (colours the server checks as #RRGGBB,
// ids, numbers it computes, its own fragments). A name, a word or a formation's name must go through esc(). The build
// stops and names the line.
import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join } from 'node:path'

// The drawing's own: colours (the server's checked #RRGGBB, the theme's constants), fragments it builds, numbers.
const SAFE =
  /^(esc\(|ref\(|led\(|K\(|keeperKit\(|kitPatternSvg\(|k\.(kit|trim)|o\.trim|kit$|c$|A$|H$|TH\[|TRIM\[|day \?|shirt$|shorts$|fill$|ink$|pts$|id$|i$|st\.(defs|body)$|svg\.dataset\.id$|skins\[|Array\.from|i % 2|-?\d|\(320 \+|\(170 \+|dx|x$|y$|\(\(|a\b|r0\b)/
const files = []
const walk = (d) =>
  readdirSync(d).forEach((f) => {
    const p = join(d, f)
    statSync(p).isDirectory() ? walk(p) : /\.(ts|vue)$/.test(f) && !f.endsWith('.d.ts') && files.push(p)
  })
walk('src')
const bad = []
for (const f of files) {
  const src = readFileSync(f, 'utf8')
  for (const m of src.matchAll(/innerHTML\s*=[^`\n]*`((?:[^`\\]|\\.)*)`/g)) {
    for (const x of m[1].matchAll(/\$\{([^}]*)\}/g)) {
      const expr = x[1].trim()
      if (!SAFE.test(expr)) bad.push(`${f}:${src.slice(0, m.index).split('\n').length}: \${${expr}}`)
    }
  }
}
if (bad.length) {
  console.error('safe-html: a value goes into innerHTML without esc() (scripts/safe-html.mjs):\n  ' + bad.join('\n  '))
  process.exit(1)
}
console.log('safe-html: OK')
