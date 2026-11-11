// [Sprint 51 W1] Nothing scrolls a screen sideways: every screen of a club, on a phone turned sideways (the game's own
// way), a small phone and a computer. A badge on the top bar once hung 2px off the edge of every club screen.
import { expect, test } from '@playwright/test'
import { ready, signUp } from './helpers'

const SCREENS = ['/club', '/team', '/lineup', '/tactics', '/market', '/match', '/training', '/stadium', '/finance', '/stats', '/scout',
  '/specialists', '/takers', '/friendlies', '/quests', '/fixtures', '/', '/leagues', '/inbox', '/profile']

test('no screen scrolls sideways, on a phone or a computer', async ({ page }) => {
  test.setTimeout(600_000)   // 60 screens
  await signUp(page)
  await page.goto('/leagues/new')
  await ready(page)
  await page.locator('.league-tile').first().click()
  await page.getByRole('button', { name: 'أنشئ الدوري واختر فريقك' }).click()
  await page.locator('section[aria-label="أندية الدوري"] button').first().click()
  await page.getByRole('button', { name: /أنشئ الدوري بـ/ }).click()
  await expect(page).toHaveURL(/\/leagues\/\d+/, { timeout: 20_000 })

  const wide: string[] = []
  for (const [width, height] of [[915, 412], [667, 375], [1440, 900]]) {
    await page.setViewportSize({ width, height })
    for (const path of SCREENS) {
      await page.goto(path)
      await ready(page)
      await page.waitForTimeout(800)   // the screen's data in (not networkidle: the live screens keep polling)
      const [scroll, client] = await page.evaluate(() => [document.documentElement.scrollWidth, document.documentElement.clientWidth])
      if (scroll > client) wide.push(`${width}×${height} ${path}: ${scroll} > ${client}`)
    }
  }
  expect(wide).toEqual([])
})
