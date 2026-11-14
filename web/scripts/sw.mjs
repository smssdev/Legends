// [Sprint 58 W5] After the build, before the SEO pages: the service worker for this build (dist/sw.js from
// public/sw.js). Its version is the build's (the hash of what it saves), and it saves first the app's shell
// (dist/shell.html: index.html as built, before scripts/seo.mjs writes a page's own words into it), the built files the
// shell loads, the fonts, the icons and the emblems. Every placeholder must be filled, or the build stops.
import { createHash } from 'node:crypto'
import { copyFileSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'

const dist = new URL('../dist/', import.meta.url)
const index = readFileSync(new URL('index.html', dist), 'utf8')
copyFileSync(new URL('index.html', dist), new URL('shell.html', dist))
// What the shell loads: its scripts, styles and preloads from /assets/ and /fonts/.
const linked = [...index.matchAll(/(?:src|href)="(\/(?:assets|fonts)\/[^"]+)"/g)].map((m) => m[1])
const fonts = readdirSync(new URL('fonts/', dist))
  .filter((f) => f.endsWith('.woff2'))
  .map((f) => `/fonts/${f}`)
// The emblems the splash and the bar show (offline too), and the coin.
const brand = ['emblem.svg', 'emblem-ar.svg', 'emblem-loader.svg', 'emblem-loader-ar.svg', 'coin.svg'].map((f) => `/brand/${f}`)
const precache = [...new Set(['/shell.html', '/site.webmanifest', '/icon-192.png', '/icon-512.png', ...linked, ...fonts, ...brand])]
const hash = createHash('sha256')
for (const p of precache) hash.update(p === '/shell.html' ? index : p)
const build = hash.digest('hex').slice(0, 12)
const template = readFileSync(new URL('sw.js', dist), 'utf8')
const sw = template.replace("'glm-__BUILD__'", `'glm-${build}'`).replace('[/*__PRECACHE__*/]', JSON.stringify(precache))
if (sw.includes('__BUILD__') || sw.includes('__PRECACHE__')) {
  console.error('sw.mjs: public/sw.js lost its placeholders')
  process.exit(1)
}
writeFileSync(new URL('sw.js', dist), sw)
console.log(`sw: glm-${build}, ${precache.length} files saved first`)
