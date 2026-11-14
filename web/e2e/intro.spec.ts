// [Sprint 64 W1] A new coach plays a minute of a match within 120 seconds of the sign-up: the intro match opens by
// itself, its assistant can be skipped at any moment, and the skip leads to «take a club».
import { expect, test } from '@playwright/test'
import { signUp } from './helpers'

test('a new coach is playing his first match within two minutes of signing up', async ({ page }) => {
  test.setTimeout(150_000)
  await page.setViewportSize({ width: 915, height: 412 })
  const started = Date.now()
  await signUp(page)
  await expect(page).toHaveURL(/\/sim\/[a-z0-9]+/, { timeout: 30_000 })
  // A minute has been played: the clock on the picture reads a minute past zero.
  await expect(page.locator('.match-root')).toContainText(/\b([1-9]\d?)['’]/, { timeout: 90_000 })
  expect(Date.now() - started).toBeLessThan(120_000)
  // The skip is always in reach, and leads to a club.
  await page.getByRole('button', { name: 'تخطَّ المباراة التعريفية' }).click()
  await page.getByRole('button', { name: 'خذ نادياً' }).click()
  await expect(page).toHaveURL(/\/leagues/, { timeout: 20_000 })
})
