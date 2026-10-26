// [UP2] Every Arabic sentence a screen passes through t() / $t() has its English in src/i18n/en.ts, or the build stops
// and names the missing ones. (A sentence not passed through t() is not checked: it stays Arabic in English.)
import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join } from 'node:path'

const files = []
const walk = (d) => readdirSync(d).forEach((f) => { const p = join(d, f); statSync(p).isDirectory() ? walk(p) : /\.(vue|ts)$/.test(f) && files.push(p) })
walk('src')
const ARABIC = /[؀-ۿ]/
const unq = (s) => s.replace(/\\'/g, "'").replace(/\\\\/g, '\\')
const en = new Set([...readFileSync('src/i18n/en.ts', 'utf8').matchAll(/^ {2}'((?:[^'\\]|\\.)*)': /gm)].map((m) => unq(m[1])))
const lost = []
const missing = (k, f) => lost.push(`${f}: ${k}`)

// The sections' names are shown through $t in the shell.
for (const m of readFileSync('src/layouts/nav.ts', 'utf8').matchAll(/label: '([^']*)'/g)) if (!en.has(m[1])) missing(m[1], 'src/layouts/nav.ts')

for (const f of files) {
  if (f.endsWith(join('i18n', 'en.ts'))) continue
  const src = readFileSync(f, 'utf8')
  // Every Arabic literal inside t( ... ) up to its closing parenthesis, so a ternary's two sentences count too;
  // the vars object at the end is left out.
  for (const m of src.matchAll(/(?<![\w.])\$?t\(/g)) {
    let depth = 1
    let quote = ''
    let i = m.index + m[0].length
    const start = i
    for (; i < src.length && depth; i++) {
      const c = src[i]
      if (quote) {
        if (c === '\\') i++
        else if (c === quote) quote = ''
        continue
      }
      if (c === "'" || c === '`' || c === '"') quote = c
      else if (c === '(') depth++
      else if (c === ')') depth--
    }
    const args = src.slice(start, i - 1).replace(/,\s*\{[^{}]*\}\s*$/, '')
    for (const lit of args.matchAll(/'((?:[^'\\]|\\.)*)'/g)) {
      const k = unq(lit[1])
      if (ARABIC.test(k) && !en.has(k)) missing(k, f)
    }
  }
}
if (lost.length) {
  console.error(`${lost.length} sentence(s) without English in src/i18n/en.ts:\n` + lost.join('\n'))
  process.exit(1)
}
console.log(`i18n: ${en.size} sentences, all with their English`)
