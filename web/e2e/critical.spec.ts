// [Sprint 30 G8] The game's critical path, as a new coach walks it: sign up → the starter coins → a league with his
// team → the lineup → a match played to its end → its report.
import { expect, test } from '@playwright/test'
import { ready, signUp } from './helpers'

test('a new coach signs up, makes a league, sets his lineup, plays a match and reads its report', async ({ page }) => {
  await signUp(page)

  // The home screen: the starter coins, once (Sprint 30 P6).
  await page.goto('/')
  await ready(page)
  await page.getByRole('button', { name: 'استلم مكافأتك' }).click()
  await expect(page.getByText('هدية البداية')).toHaveCount(0)

  // A standard league (free) and its team.
  await page.goto('/leagues/new')
  await ready(page)
  // [Sprint 48 D1] First the league, on its tile.
  await page.locator('.league-tile').first().click()
  await page.getByRole('button', { name: 'أنشئ الدوري واختر فريقك' }).click()
  await page.locator('section[aria-label="أندية الدوري"] button').first().click()
  await page.getByRole('button', { name: /أنشئ الدوري بـ/ }).click()
  await expect(page).toHaveURL(/\/leagues\/\d+/, { timeout: 20_000 })

  // The club's lineup: eleven on the pitch.
  await page.goto('/lineup')
  await ready(page)
  await expect(page.locator('[data-spot^="slot:"]')).toHaveCount(11, { timeout: 20_000 })

  // A match, skipped to its end, and its report.
  await page.goto('/sim')
  await ready(page)
  await page.getByRole('button', { name: /ابدأ/ }).last().click()
  await expect(page).toHaveURL(/\/sim\/[a-z0-9]+/)
  const match = page.url().split('?')[0]
  // [Sprint 43 W3, Sprint 48 L1] Upright, the phone is asked to turn; sideways, the match plays.
  await page.setViewportSize({ width: 412, height: 915 })
  await expect(page.getByRole('dialog', { name: 'لفّ جوالك' })).toBeVisible({ timeout: 20_000 })
  await page.setViewportSize({ width: 915, height: 412 })
  await expect(page.getByRole('dialog', { name: 'لفّ جوالك' })).toHaveCount(0)
  await page.getByRole('button', { name: /تخطٍّ للنهاية/ }).click()
  await page.waitForTimeout(3000)
  await page.goto(match + '/report')
  await expect(page.getByText(/^النتيجة: /)).toBeVisible({ timeout: 20_000 })
  await expect(page.getByRole('heading', { name: 'أفضل 3 لاعبين' })).toBeVisible()
})
