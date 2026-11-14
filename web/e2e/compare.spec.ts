// [Sprint 60 T1] The site's side of the comparison page (tools/design/compare.mjs): the eight screens at the app's size
// (844×390, dark), unmasked, into tools/design/out/web/. Only on request, not in the run before a PR:
//   COMPARE=1 npx playwright test e2e/compare.spec.ts && node ../tools/design/compare.mjs
import { expect, test } from '@playwright/test'
import { ready, signUp } from './helpers'

const SCREENS: [string, string][] = [
  ['/club', 'office'],
  ['/team', 'squad'],
  ['/lineup', 'lineup'],
  ['/tactics', 'tactics'],
  ['/market', 'market'],
  ['/match', 'next-match'],
  ['/fixtures', 'fixtures'],
  ['/', 'home'],
]

test.skip(!process.env.COMPARE, 'COMPARE=1 to take the comparison shots')

test("the site at the app's size, for the comparison page", async ({ page }) => {
  test.setTimeout(300_000)
  await signUp(page)
  await page.goto('/leagues/new')
  await ready(page)
  await page.locator('.league-tile').first().click()
  await page.getByRole('button', { name: 'أنشئ الدوري واختر فريقك' }).click()
  await page.locator('section[aria-label="أندية الدوري"] button').first().click()
  await page.getByRole('button', { name: /أنشئ الدوري بـ/ }).click()
  await expect(page).toHaveURL(/\/leagues\/\d+/, { timeout: 20_000 })
  await page.keyboard.press('Escape')
  await page.setViewportSize({ width: 844, height: 390 })
  await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' })
  for (const [path, name] of SCREENS) {
    await page.goto(path)
    await ready(page)
    await page.waitForTimeout(1200)
    await page.keyboard.press('Escape')
    await page.screenshot({ path: `../tools/design/out/web/${name}.png`, animations: 'disabled' })
  }
})
