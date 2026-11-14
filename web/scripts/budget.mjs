// [Sprint 58 T1] The site's weight, checked after every build (CI is off: npm run build runs it): the entry script at
// most 75 KB and the home page's first load (what index.html loads and preloads: scripts, styles, fonts) at most
// 110 KB, both as Brotli sends them. Over either, the build stops. The API's side (3 requests to open /club) is
// e2e/budget.spec.ts.
import { readFileSync } from 'node:fs'
import { brotliCompressSync, constants } from 'node:zlib'

const ENTRY_KB = 75
const FIRST_KB = 110
const dist = new URL('../dist/', import.meta.url)
const index = readFileSync(new URL('shell.html', dist), 'utf8')
const br = (path) =>
  brotliCompressSync(readFileSync(new URL('.' + path, dist)), { params: { [constants.BROTLI_PARAM_QUALITY]: 11 } }).length
const kb = (n) => Math.round((n / 1024) * 10) / 10
const files = [...new Set([...index.matchAll(/(?:src|href)="(\/(?:assets|fonts)\/[^"]+)"/g)].map((m) => m[1]))]
const entry = files.find((f) => /^\/assets\/index-[^/]+\.js$/.test(f))
if (!entry) {
  console.error('budget: no entry script in shell.html')
  process.exit(1)
}
const entrySize = br(entry)
const first = files.reduce((t, f) => t + br(f), 0)
const lines = [
  `budget: entry ${entry} ${kb(entrySize)} KB of ${ENTRY_KB}`,
  `budget: first load ${files.length} files ${kb(first)} KB of ${FIRST_KB}`,
]
console.log(lines.join('\n'))
if (entrySize > ENTRY_KB * 1024 || first > FIRST_KB * 1024) {
  console.error('budget: over (see sprints/58-web-performance.md T1)')
  process.exit(1)
}
