import { expect, type Page } from '@playwright/test'

/** Past the splash (it waits for the server's first answer). */
export async function ready(page: Page) {
  await page.locator('.splash').waitFor({ state: 'detached', timeout: 30_000 }).catch(() => {})
  // The Assistant Coach's greeting closed, as a coach would (it also leaves by itself after a few seconds).
  const hello = page.locator('.bot-hello-x')
  if (await hello.isVisible().catch(() => false)) await hello.click()
  // [Sprint 38 N1] The sound card, asked once a device: «لاحقاً», as a coach in a hurry would.
  const later = page.locator('section[aria-labelledby="sound-prompt-title"]').getByRole('button', { name: 'لاحقاً' })
  await later.waitFor({ state: 'visible', timeout: 1500 }).then(() => later.click()).catch(() => {})
}

/** A new coach, signed up through the form: a unique username, an 8-character password (Sprint 30 Q11). */
export async function signUp(page: Page): Promise<string> {
  const username = 'e2e' + Date.now().toString(36)
  await page.goto('/register')
  await ready(page)
  await page.locator('input[autocomplete="nickname"]').fill('مدرب التجربة')
  await page.locator('input[autocomplete="username"]').fill(username)
  await page.locator('input[type="password"]').first().fill('e2e-pass-2026')
  const terms = page.locator('input[type="checkbox"]')
  if (await terms.count()) await terms.first().check()
  await page.getByRole('button', { name: 'إنشاء الحساب' }).click()
  await expect(page).not.toHaveURL(/register/, { timeout: 20_000 })
  return username
}
