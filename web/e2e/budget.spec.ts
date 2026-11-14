// [Sprint 58 T1] Opening the club takes at most 3 API requests (it was 9, and 2 crests), and no crest goes through
// Laravel: the visit's start is one request (GET /bootstrap), the board one, and the crests are static files.
import { expect, test } from '@playwright/test'
import { ready, signUp } from './helpers'

test('opening the club costs at most three API requests and no crest through Laravel', async ({ page }) => {
  test.setTimeout(120_000)
  await signUp(page)
  await page.goto('/leagues/new')
  await ready(page)
  await page.locator('.league-tile').first().click()
  await page.getByRole('button', { name: 'أنشئ الدوري واختر فريقك' }).click()
  await page.locator('section[aria-label="أندية الدوري"] button').first().click()
  await page.getByRole('button', { name: /أنشئ الدوري بـ/ }).click()
  await expect(page).toHaveURL(/\/leagues\/\d+/, { timeout: 20_000 })

  // A fresh load of /club, as a coach opening the site there.
  const api: string[] = []
  page.on('request', (r) => {
    const path = new URL(r.url()).pathname
    if (path.startsWith('/api/')) api.push(path.replace('/api/v1', ''))
  })
  await page.goto('/club')
  await ready(page)
  await page.waitForTimeout(3000)
  expect(
    api.filter((p) => p.includes('/crest.svg')),
    'crests through Laravel',
  ).toEqual([])
  expect(api.length, api.join(', ')).toBeLessThanOrEqual(3)
})
