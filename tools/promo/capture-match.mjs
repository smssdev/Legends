// The promo's match frames [2026-11-15]: a simulator match at double speed, a frame every 0.8 s, until N frames.
//   node tools/promo/capture-match.mjs   (FRAMES=120 by default) → tools/promo/out/match/
import { createRequire } from 'node:module'
import { mkdirSync } from 'node:fs'

const require = createRequire(new URL('../../web/package.json', import.meta.url))
const { chromium } = require('playwright')
const BASE = process.env.BASE ?? 'http://localhost:5173'
const OUT = new URL('./out/match/', import.meta.url).pathname
mkdirSync(OUT, { recursive: true })
const browser = await chromium.launch(process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {})
const page = await (
  await browser.newContext({ viewport: { width: 915, height: 412 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, locale: 'ar', colorScheme: 'dark' })
).newPage()
await page.goto(BASE + '/sim')
await page.locator('.splash').waitFor({ state: 'detached', timeout: 30_000 }).catch(() => {})
await page.getByRole('button', { name: /ابدأ/ }).last().click()
await page.waitForURL(/\/sim\/[a-z0-9]+/, { timeout: 20_000 })
await page.waitForTimeout(1500)
await page.getByRole('button', { name: '×2' }).click().catch(() => page.getByText('2', { exact: false }).first().click().catch(() => {}))
const n = Number(process.env.FRAMES ?? 120)
for (let i = 0; i < n; i++) {
  await page.waitForTimeout(800)
  await page.screenshot({ path: OUT + `m-${String(i).padStart(3, '0')}.png` })
}
await browser.close()
console.log('done', n)
