// [Sprint 63 G3] The site's icon map is brand/icons/*.svg as tools/brand/icons.py writes it: stops the build when a
// drawing changed and the map was not written again (python3 tools/brand/icons.py).
import { readdirSync, readFileSync } from 'node:fs'

const src = '../brand/icons'
const want = Object.fromEntries(
  readdirSync(src).filter((f) => f.endsWith('.svg')).sort().map((f) => [f.slice(0, -4), readFileSync(`${src}/${f}`, 'utf8').match(/<path d="([^"]+)"/)[1]]),
)
const have = Object.fromEntries([...readFileSync('src/components/icons.g.ts', 'utf8').matchAll(/^ {2}(\w+): '([^']*)',$/gm)].map((m) => [m[1], m[2]]))
const stale = [...new Set([...Object.keys(want), ...Object.keys(have)])].filter((k) => want[k] !== have[k])
if (stale.length) {
  console.error(`icons: the map is behind brand/icons (${stale.join(', ')}): run python3 tools/brand/icons.py`)
  process.exit(1)
}
console.log(`icons: OK (${Object.keys(want).length} from brand/icons)`)
