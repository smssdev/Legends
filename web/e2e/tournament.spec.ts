// [Sprint 66 T5 (7)] A tournament and its draw: a coach makes the World Cup (with coins the admin gave him), the clock
// moves past its start and the scheduler's job draws it, and the draw is watched, then skipped to its end. The clock goes back
// however the test ends.
import { expect, test } from '@playwright/test'
import { artisan, giveCoins, ready, signUp } from './helpers'

test.afterEach(() => {
  artisan('clock:travel', 'reset')
})

test('a coach makes a tournament, it is drawn at its start, and he watches the draw to its end', async ({ page }) => {
  const username = await signUp(page)
  giveCoins(username, 1000)

  await page.goto('/tournaments/new')
  await ready(page)
  await page.getByLabel('اسم البطولة').fill('كأس التجربة')
  await page.getByRole('button', { name: /^أنشئ البطولة/ }).click()
  await expect(page).toHaveURL(/\/tournaments\/\d+/, { timeout: 20_000 })
  const tournament = new URL(page.url()).pathname.match(/\/tournaments\/\d+/)![0]
  await expect(page.getByText('كأس التجربة').first()).toBeVisible()

  // Past its start, as the scheduler would have it: drawn.
  artisan('clock:travel', '+8d')
  artisan('leagues:start')
  await page.goto(tournament)
  await ready(page)
  await page.getByRole('link', { name: 'شاهد القرعة' }).click()
  await expect(page).toHaveURL(/\/draw/)
  // The first teams come out of the bowl, then the rest at once.
  await expect(page.getByRole('button', { name: 'تخطَّ إلى النتيجة' })).toBeVisible({ timeout: 20_000 })
  await page.waitForTimeout(3000)
  await page.getByRole('button', { name: 'تخطَّ إلى النتيجة' }).click()
  await expect(page.getByText('انتهت القرعة')).toBeVisible({ timeout: 20_000 })
})
