// The promo video's screens [2026-11-15]: a new coach on the local game (composer dev, or php artisan serve and vite),
// with a league and his club, photographed as a player sees them: the phone held sideways (2x, sharp in the video) and
// a computer, plus frames of a match's broadcast. Into tools/promo/out/shots/ (not committed: made again on demand).
//   node tools/promo/capture.mjs   (from the repository's root; the web's Playwright and the installed Chromium)
import { createRequire } from 'node:module'
import { mkdirSync } from 'node:fs'

const require = createRequire(new URL('../../web/package.json', import.meta.url))
const { chromium } = require('playwright')
const BASE = process.env.BASE ?? 'http://localhost:5173'
const OUT = new URL('./out/shots/', import.meta.url).pathname
mkdirSync(OUT, { recursive: true })

const browser = await chromium.launch(process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {})
const phone = { viewport: { width: 915, height: 412 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, locale: 'ar' }
const ctx = await browser.newContext({ ...phone, reducedMotion: 'no-preference', colorScheme: 'dark' })
const page = await ctx.newPage()

async function ready() {
  await page.locator('.splash').waitFor({ state: 'detached', timeout: 30_000 }).catch(() => {})
  const hello = page.locator('.bot-hello-x')
  if (await hello.isVisible().catch(() => false)) await hello.click()
  const later = page.locator('section[aria-labelledby="sound-prompt-title"]').getByRole('button', { name: 'لاحقاً' })
  await later.waitFor({ state: 'visible', timeout: 1500 }).then(() => later.click()).catch(() => {})
}
async function shot(path, name, wait = 1800) {
  await page.goto(BASE + path)
  await ready()
  await page.waitForTimeout(wait)
  await page.keyboard.press('Escape')
  await page.waitForTimeout(300)
  await page.screenshot({ path: OUT + name + '.png' })
  console.log('shot', name)
}

// A coach, his starter coins, a league with his club, his contract signed (with the keys).
const username = 'promo' + Date.now().toString(36)
await page.goto(BASE + '/register')
await ready()
await page.locator('input[autocomplete="nickname"]').fill('مدرب أسطوري')
await page.locator('input[autocomplete="username"]').fill(username)
await page.locator('input[type="password"]').first().fill('promo-pass-2026')
const terms = page.locator('input[type="checkbox"]')
if (await terms.count()) await terms.first().check()
await page.getByRole('button', { name: 'إنشاء الحساب' }).click()
await page.waitForURL((u) => !u.pathname.includes('register'), { timeout: 20_000 })
await page.goto(BASE + '/')
await ready()
await page.getByRole('button', { name: 'استلم مكافأتك' }).click().catch(() => {})
await page.goto(BASE + '/leagues/new')
await ready()
await page.locator('.league-tile').first().click()
await page.getByRole('button', { name: 'أنشئ الدوري واختر فريقك' }).click()
await page.locator('section[aria-label="أندية الدوري"] button').first().click()
await page.getByRole('button', { name: /أنشئ الدوري بـ/ }).click()
await page.waitForURL(/\/leagues\/\d+/, { timeout: 20_000 })
const pad = page.getByRole('button', { name: /وقّع بإصبعك هنا/ })
if (await pad.isVisible({ timeout: 5000 }).catch(() => false)) {
  await page.screenshot({ path: OUT + 'contract.png' })
  await pad.focus()
  await page.keyboard.press('Enter')
  await page.waitForTimeout(400)
  await page.screenshot({ path: OUT + 'contract-signed.png' })
  await page.getByRole('button', { name: 'وقّع وتولَّ القيادة' }).click()
  await page.getByRole('button', { name: 'إلى غرفة الملابس' }).click()
}

for (const [path, name] of [
  ['/club', 'office'],
  ['/team', 'squad'],
  ['/lineup', 'lineup'],
  ['/tactics', 'tactics'],
  ['/market', 'market'],
  ['/training', 'training'],
  ['/stadium', 'stadium'],
  ['/match', 'next-match'],
  ['/leagues/new', 'league-picker'],
  ['/tournaments/new', 'tournament'],
  ['/groups', 'groups'],
]) await shot(path, name)

// A match against the computer: frames of its broadcast, every 1.2 s for a minute.
await page.goto(BASE + '/sim')
await ready()
await page.getByRole('button', { name: /ابدأ/ }).last().click()
await page.waitForURL(/\/sim\/[a-z0-9]+/, { timeout: 20_000 })
await ready()
for (let i = 0; i < 50; i++) {
  await page.waitForTimeout(1200)
  await page.screenshot({ path: OUT + `match-${String(i).padStart(2, '0')}.png` })
}
console.log('match frames')

// The computer: the office and the lineup.
await page.setViewportSize({ width: 1440, height: 900 })
for (const [path, name] of [
  ['/club', 'desk-office'],
  ['/lineup', 'desk-lineup'],
]) await shot(path, name)

await browser.close()
console.log('done:', OUT)
