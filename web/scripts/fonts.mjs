// [Sprint 63 G11, W-B10] The pages and the drawings ask only for the weights the game ships (public/fonts: Barlow
// Condensed up to 800, Tajawal up to 700): a 900 is drawn by the browser's fake bold, thicker and blurred.
//   node scripts/fonts.mjs        (before every build)
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join } from 'node:path'

const files = (dir) =>
  readdirSync(dir).flatMap((f) => {
    const p = join(dir, f)
    return statSync(p).isDirectory() ? files(p) : /\.(ts|vue|css)$/.test(f) ? [p] : []
  })
const wrong = files('src').filter((f) => /font-weight['"]?\s*[:=]\s*['"]?900|font-black/.test(readFileSync(f, 'utf8')))
if (wrong.length) {
  console.error(`fonts: a weight of 900 the game does not ship (800 at most for Barlow Condensed, 700 for Tajawal):\n  ${wrong.join('\n  ')}`)
  process.exit(1)
}
console.log('fonts: OK (no weight above what public/fonts holds)')
