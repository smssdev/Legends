// Renders brand/current/*.svg (from tools/brand/logo.py) to every PNG the web and the app use, in Chromium so
// the logo's Arabic and Latin lettering uses the game's font (Alexandria), then copies the web's files to web/public.
// Needs Playwright with a Chromium: node tools/brand/render.mjs [path-to-chromium]
import { chromium } from 'playwright'
import { copyFileSync, readFileSync } from 'fs'
import { dirname, join } from 'path'
import { fileURLToPath } from 'url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..')
const brand = join(root, 'brand', 'current')
const svg = (f) => readFileSync(join(brand, f), 'utf8')
const OUT = [
  ['icon.svg', 512, 'icon-512.png'], ['icon.svg', 192, 'icon-192.png'], ['icon.svg', 180, 'apple-touch-icon.png'],
  ['favicon.svg', 48, 'favicon-48.png'], ['favicon.svg', 32, 'favicon-32.png'], ['favicon.svg', 16, 'favicon-16.png'],
  ['logo.svg', 1024, 'logo-1024.png'], ['logo.svg', 512, 'logo-512.png'], ['logo-wide.svg', 1200, 'logo-wide.png'],
  ['emblem.svg', 512, 'emblem-512.png'],
  ['og-invite.svg', 1200, 'og-invite.png'],
  ['coin.svg', 512, 'coin-512.png'], ['coin.svg', 128, 'coin-128.png'], ['coin.svg', 48, 'coin-48.png'], ['coin.svg', 24, 'coin-24.png'],
]
const b = await chromium.launch(process.argv[2] ? { executablePath: process.argv[2] } : {})
const p = await b.newPage()
for (const [file, w, out] of OUT) {
  const text = svg(file)
  const [vw, vh] = text.match(/viewBox="0 0 (\d+) (\d+)"/).slice(1).map(Number)
  const h = Math.round((w * vh) / vw)
  await p.setViewportSize({ width: w, height: h })
  await p.setContent(`<link href="https://fonts.googleapis.com/css2?family=Alexandria:wght@700;800&display=swap" rel="stylesheet">
    <style>html,body{margin:0;background:transparent}svg{display:block;width:${w}px;height:${h}px}</style>${text}`)
  await p.evaluate(() => document.fonts.ready)
  await p.screenshot({ path: join(brand, out), omitBackground: true })
}
await b.close()
console.log(OUT.map((o) => o[2]).join(', '))

// What the site serves: the marks it shows as <img>, the icons the browser and the installed app take, the invite card.
const WEB = join(root, 'web', 'public')
for (const [from, to] of [
  ['emblem.svg', 'brand/emblem.svg'], ['emblem-loader.svg', 'brand/emblem-loader.svg'], ['coin.svg', 'brand/coin.svg'],
  ['emblem-ar.svg', 'brand/emblem-ar.svg'], ['emblem-loader-ar.svg', 'brand/emblem-loader-ar.svg'],
  ['og-invite.png', 'brand/og-invite.png'], ['favicon.svg', 'favicon.svg'], ['favicon-32.png', 'favicon.png'],
  ['icon-192.png', 'icon-192.png'], ['icon-512.png', 'icon-512.png'], ['apple-touch-icon.png', 'apple-touch-icon.png'],
]) copyFileSync(join(brand, from), join(WEB, to))
