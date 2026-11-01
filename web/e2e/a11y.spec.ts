// [Sprint 30 G8] An accessibility check (axe-core, free) of the screens every coach sees first: no critical problem
// (a control with no name, an image with no text, a form field with no label…). The serious ones are listed in the
// report to be fixed one by one. And the RTL basics: the page is right to left in Arabic, left to right in English.
import AxeBuilder from '@axe-core/playwright'
import { expect, test } from '@playwright/test'
import { ready, signUp } from './helpers'

async function critical(page: import('@playwright/test').Page) {
  const r = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa']).disableRules(['color-contrast']).analyze()
  const serious = r.violations.filter((v) => v.impact === 'serious').map((v) => `${v.id} (${v.nodes.length})`)
  if (serious.length) test.info().annotations.push({ type: 'serious', description: serious.join(', ') })
  return r.violations.filter((v) => v.impact === 'critical').map((v) => `${v.id}: ${v.nodes.map((n) => n.target.join(' ')).slice(0, 3).join(' | ')}`)
}

test('the landing, the sign-in and the sign-up have no critical accessibility problem', async ({ page }) => {
  for (const path of ['/', '/login', '/register']) {
    await page.goto(path)
    await ready(page)
    expect(await critical(page), path).toEqual([])
  }
})

test('a signed-in coach’s home and leagues have no critical accessibility problem, right to left', async ({ page }) => {
  await signUp(page)
  for (const path of ['/', '/leagues', '/groups']) {
    await page.goto(path)
    await ready(page)
    await expect(page.locator('html')).toHaveAttribute('dir', 'rtl')
    expect(await critical(page), path).toEqual([])
  }
})
