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
// [Sprint 51 W4] An Arabic sentence in a .ts file (a label a screen shows later through $t, a toast, a broadcast line) needs
// its English too, or it shows in Arabic in the English game. Not checked: the files below, each with its reason; a new
// .ts file is checked from its first line.
const TS_ARABIC_ONLY = {
  'content/legal.ts': 'the policy and terms carry their English in the same file',
  'content/seo.ts': 'the search tags, written per language in the same file',
  'lib/format.ts': "Arabic plural words, used only when the locale is 'ar'",
  'lib/clock.ts': "Arabic plural words, used only when the locale is 'ar'",
  'lib/dates.ts': 'the Arabic list separator',
  'match/commentary.ts': "the simulator's Arabic lines; English has its own table (voice.json)",
  // Known gaps, closed by their sprints (each removes its line here):
  'content/leagueAtlas.ts': 'Sprint 56: the countries on the league picker',
  'components/characters/art.ts': "Sprint 63: the characters' names and descriptions",
  'match/feed/art.ts': 'Sprint 57: the broadcast words come from the server',
  'match/feed/story.ts': 'Sprint 57: the moment story comes from the server',
}
for (const f of files) {
  const rel = f.slice(4).split('\\').join('/')
  if (!f.endsWith('.ts') || rel === 'i18n/en.ts' || rel.endsWith('.d.ts') || TS_ARABIC_ONLY[rel]) continue
  for (const lit of readFileSync(f, 'utf8').matchAll(/'((?:[^'\\\n]|\\.)*)'/g)) {
    const k = unq(lit[1])
    if (ARABIC.test(k) && !en.has(k) && !lost.includes(`${f}: ${k}`)) missing(k, f)
  }
}
if (lost.length) {
  console.error(`${lost.length} sentence(s) without English in src/i18n/en.ts:\n` + lost.join('\n'))
  process.exit(1)
}
console.log(`i18n: ${en.size} sentences, all with their English`)
