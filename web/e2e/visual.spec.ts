// [Sprint 56 T2] Before-and-after shots of the screens rebuilt on their drafts: a change that moves a screen shows here
// as a difference against the committed shot (e2e/visual.spec.ts-snapshots/). The numbers, the times, the crests and
// the league's code change from one new account to the next, so they are masked; the shape is what is compared.
// After a change meant to move a screen: `npx playwright test e2e/visual.spec.ts --update-snapshots`, and look at the
// new shots before committing them.
import { expect, test, type Page } from '@playwright/test'
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
// [Sprint 66 T6] Every size at night and by day.
const SIZES: [number, number, 'dark' | 'light'][] = [
  [667, 375, 'dark'],
  [915, 412, 'dark'],
  [1440, 900, 'dark'],
  [667, 375, 'light'],
  [915, 412, 'light'],
  [1440, 900, 'light'],
]

const masks = (page: Page) => [
  page.locator('.font-numbers'),
  page.locator('img'),
  page.locator('[dir="ltr"]'),
  page.locator('bdi'),
  page.locator('.dock-crest'),
  page.locator('.shell-bar'),
  page.locator('.skeleton'),
  // [Sprint 66 T6] The players on the transfer list are each new league's own: their rows as boxes (where they sit is
  // still compared, not who is in them).
  page.getByRole('region', { name: 'قائمة الانتقالات' }).getByRole('listitem'),
]

test('the rebuilt screens keep their shape', async ({ page }) => {
  test.setTimeout(600_000)
  await signUp(page)
  await page.goto('/leagues/new')
  await ready(page)
  await page.locator('.league-tile').first().click()
  await page.getByRole('button', { name: 'أنشئ الدوري واختر فريقك' }).click()
  await page.locator('section[aria-label="أندية الدوري"] button').first().click()
  await page.getByRole('button', { name: /أنشئ الدوري بـ/ }).click()
  await expect(page).toHaveURL(/\/leagues\/\d+/, { timeout: 20_000 })
  // Past the one-time windows (the club's contract, the first steps' greetings).
  await page.keyboard.press('Escape')

  for (const [width, height, scheme] of SIZES) {
    await page.setViewportSize({ width, height })
    await page.emulateMedia({ colorScheme: scheme, reducedMotion: 'reduce' })
    await page.evaluate((s) => localStorage.setItem('glm.theme', s), scheme)
    for (const [path, name] of SCREENS) {
      await page.goto(path)
      await ready(page)
      await page.waitForTimeout(1200)
      await page.keyboard.press('Escape')
      await expect(page).toHaveScreenshot(`${name}-${width}-${scheme}.png`, {
        mask: masks(page),
        animations: 'disabled',
        // [Sprint 66 T6] Small: a button's colour is seen (0.2% of the picture, the masks taking what moves).
        maxDiffPixelRatio: 0.002,
      })
    }
  }
})
