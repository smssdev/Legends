// [Sprint 63 G9] The mascot in the screens' states, drawn by the site's own code (web/src/components/characters/art.ts,
// the mascot A2 in a mood a state): empty (idle), an error (worried), no connection (asleep), a long wait (thinking), a
// celebration (cheering) and a welcome (joy). The site draws them live (EmptyState, AsyncState); the app, which has no
// drawing code for them, takes these pictures (mobile/assets/states/<state>.webp, 192 px: twice the 96 they show at).
//   NODE_PATH=$(npm root -g) node tools/brand/states.cjs       (then python3 tools/brand/states.py)
const fs = require('fs')
const path = require('path')
const { execFileSync } = require('child_process')
const { chromium } = require('playwright')

const ROOT = path.resolve(__dirname, '..', '..')
const WEB = path.join(ROOT, 'web')
const OUT = path.join(ROOT, 'brand', 'states')
const STATES = { empty: 'idle', error: 'worried', offline: 'sleep', slow: 'think', celebrate: 'cheer', welcome: 'joy' }

const art = execFileSync(path.join(WEB, 'node_modules', '.bin', 'esbuild'), ['src/components/characters/art.ts', '--bundle', '--format=iife', '--global-name=Art'], { cwd: WEB }).toString()
const css = fs.readFileSync(path.join(WEB, 'src', 'components', 'characters', 'characters.css'), 'utf8')

;(async () => {
  const browser = await chromium.launch()
  const page = await browser.newPage({ viewport: { width: 400, height: 400 }, deviceScaleFactor: 1 })
  await page.setContent(`<html><head><style>html,body{margin:0;background:transparent}${css}#c{width:384px}#c svg{display:block;width:100%;height:auto}</style></head><body><div id="c"></div><script>${art}</script></body></html>`)
  await page.evaluate(() => Art.ensureDefs())
  fs.mkdirSync(OUT, { recursive: true })
  for (const [state, mood] of Object.entries(STATES)) {
    await page.evaluate((m) => { document.getElementById('c').innerHTML = Art.drawCharacter('A2', m) }, mood)
    await page.waitForTimeout(100)
    await page.locator('#c svg').screenshot({ path: path.join(OUT, `${state}.png`), omitBackground: true, animations: 'disabled' })
    console.log(`${state}: ${mood}`)
  }
  await browser.close()
})()
