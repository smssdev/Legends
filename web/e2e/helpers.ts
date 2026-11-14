import { execFileSync } from 'node:child_process'
import { expect, type Page } from '@playwright/test'

/** Past the splash (it waits for the server's first answer). */
export async function ready(page: Page) {
  await page
    .locator('.splash')
    .waitFor({ state: 'detached', timeout: 30_000 })
    .catch(() => {})
  // The Assistant Coach's greeting closed, as a coach would (it also leaves by itself after a few seconds).
  const hello = page.locator('.bot-hello-x')
  if (await hello.isVisible().catch(() => false)) await hello.click()
  // [Sprint 39 N1] The sound card, asked once a device: «لاحقاً», as a coach in a hurry would.
  const later = page.locator('section[aria-labelledby="sound-prompt-title"]').getByRole('button', { name: 'لاحقاً' })
  await later
    .waitFor({ state: 'visible', timeout: 1500 })
    .then(() => later.click())
    .catch(() => {})
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

/** [Sprint 66 T5] A league with the coach's club in it (the first league and club offered); its path. */
export async function makeLeague(page: Page): Promise<string> {
  await page.goto('/leagues/new')
  await ready(page)
  await page.locator('.league-tile').first().click()
  await page.getByRole('button', { name: 'أنشئ الدوري واختر فريقك' }).click()
  await page.locator('section[aria-label="أندية الدوري"] button').first().click()
  await page.getByRole('button', { name: /أنشئ الدوري بـ/ }).click()
  await expect(page).toHaveURL(/\/leagues\/\d+/, { timeout: 20_000 })
  return new URL(page.url()).pathname
}

/** [Sprint 66 T5] The contract a coach signs on taking his club (Sprint 43), signed with the keys (Sprint 65 W5). */
export async function signContract(page: Page) {
  const pad = page.getByRole('button', { name: /وقّع بإصبعك هنا/ })
  if (!(await pad.isVisible({ timeout: 5000 }).catch(() => false))) return
  await pad.focus()
  await page.keyboard.press('Enter')
  await page.getByRole('button', { name: 'وقّع وتولَّ القيادة' }).click()
  await page.getByRole('button', { name: 'إلى غرفة الملابس' }).click()
  await expect(pad).toHaveCount(0)
}

/** [Sprint 66 T5] The local server's artisan (the journeys' server is on this machine, in CI as here). */
export function artisan(...args: string[]): string {
  return execFileSync('php', ['artisan', ...args], { cwd: '../backend', stdio: 'pipe' }).toString()
}

/** [Sprint 66 T5] Coins to a coach as the admin gives them (the ledger's admin_gift, once per key). */
export function giveCoins(username: string, amount: number) {
  const code = `App\\Wallet\\Wallet::post(App\\Models\\User::where('username', '${username}')->value('id'), 'admin_gift', ${amount}, 'e2e:${username}', 'e2e');`
  artisan('tinker', `--execute=${code}`)
}
