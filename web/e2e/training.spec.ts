// [Sprint 66 T5 (3)] Training and the stadium across time: a player put in a training slot and a stadium part
// started, the game's clock moved on (clock:travel, as CLAUDE.md asks for anything that waits) and the scheduler's
// jobs run once: the player has progressed and the part is built. The clock goes back however the test ends.
import { expect, test } from '@playwright/test'
import { artisan, makeLeague, ready, signUp } from './helpers'

test.afterEach(() => {
  artisan('clock:travel', 'reset')
})

test('a coach trains a player and builds a stadium part, and both are done once the time has passed', async ({ page }) => {
  await signUp(page)
  await makeLeague(page)

  // A player in training: the recommended midfielder.
  await page.goto('/training')
  await ready(page)
  await page.getByRole('region', { name: 'مرشحون للتدريب' }).getByRole('button', { name: 'درّب' }).first().click()
  await expect(page.getByRole('button', { name: 'اختر لاعباً' })).toHaveCount(3, { timeout: 20_000 })

  // A part of the stands.
  await page.goto('/stadium')
  await ready(page)
  const stands = page.getByRole('region', { name: 'أقسام الملعب' }).getByRole('article').first()
  await stands.getByRole('button', { name: /ابدأ الجزء التالي/ }).click()
  await expect(page.getByText('يُبنى الآن: التذاكر والمقاعد')).toBeVisible({ timeout: 20_000 })

  // A day later, as the scheduler would have it.
  artisan('clock:travel', '+1d')
  artisan('training:tick')
  artisan('stadium:due')

  await page.reload()
  await ready(page)
  await expect(stands.getByRole('img', { name: 'المرحلة 1: 1 من 5' })).toBeVisible({ timeout: 20_000 })
  await expect(page.getByRole('region', { name: 'الملعب الآن' })).toContainText('1 / 45')

  await page.goto('/training')
  await ready(page)
  const progress = page.getByRole('progressbar', { name: 'التقدم' }).first()
  await expect(progress).toBeVisible({ timeout: 20_000 })
  await expect.poll(async () => Number(await progress.getAttribute('aria-valuenow'))).toBeGreaterThan(0)
})
