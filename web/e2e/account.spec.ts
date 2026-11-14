// [Sprint 66 T5 (8)] The account: the language, the day look, a new password, signing out and in with it.
import { expect, test } from '@playwright/test'
import { ready, signUp } from './helpers'

test('a coach switches to English and the day look, changes his password, signs out and back in with it', async ({ page }) => {
  const username = await signUp(page)
  await page.goto('/profile')
  await ready(page)

  // The language: the page turns left to right, and back.
  const language = page.getByRole('radiogroup', { name: 'اللغة' }).first()
  await language.getByRole('radio', { name: 'English' }).click()
  await expect(page.locator('html')).toHaveAttribute('dir', 'ltr')
  await expect(page.locator('html')).toHaveAttribute('lang', 'en')
  await page.getByRole('radiogroup', { name: 'Language' }).first().getByRole('radio', { name: 'العربية' }).click()
  await expect(page.locator('html')).toHaveAttribute('dir', 'rtl')

  // The day look, kept on the device.
  await page.getByRole('radio', { name: /نهاري/ }).click()
  await expect(page.locator('html')).toHaveClass(/\blight\b/)
  await page.reload()
  await ready(page)
  await expect(page.locator('html')).toHaveClass(/\blight\b/)

  // A new password.
  await page.getByLabel('كلمة المرور الحالية').fill('e2e-pass-2026')
  await page.getByLabel('كلمة المرور الجديدة').fill('e2e-pass-2027')
  await page.getByRole('button', { name: 'احفظ كلمة المرور' }).click()
  await expect(page.getByText('تغيّرت كلمة المرور.')).toBeVisible()

  // Out, and in again with the new one (the old one refused).
  await page.getByRole('button', { name: 'تسجيل الخروج' }).click()
  await expect(page).toHaveURL(/\/login/)
  await ready(page)
  await page.locator('input[autocomplete="username"]').fill(username)
  await page.locator('input[autocomplete="current-password"]').fill('e2e-pass-2026')
  await page.getByRole('button', { name: 'دخول' }).click()
  await expect(page).toHaveURL(/\/login/)
  await page.locator('input[autocomplete="current-password"]').fill('e2e-pass-2027')
  await page.getByRole('button', { name: 'دخول' }).click()
  await expect(page).not.toHaveURL(/\/login/, { timeout: 20_000 })
})
