// [Sprint 66 T5 (2)] The market: a player bought from the transfer list, one of the coach's own put up for sale, and
// taken off it again.
import { expect, test } from '@playwright/test'
import { makeLeague, ready, signUp } from './helpers'

test('a coach buys a player, lists one of his own for sale and withdraws him', async ({ page }) => {
  await signUp(page)
  // The starter coins (a deal is registered with a coin).
  await page.goto('/')
  await ready(page)
  await page.getByRole('button', { name: 'استلم مكافأتك' }).click()
  await makeLeague(page)
  await page.goto('/market')
  await ready(page)

  // The cheapest goalkeeper on the list (the last of the first page is the weakest), bought.
  const list = page.getByRole('region', { name: 'قائمة الانتقالات' }).getByRole('listitem')
  await expect(list.first()).toBeVisible({ timeout: 20_000 })
  await list.last().getByRole('button').click()
  const buy = page.getByRole('button', { name: /^شراء ·/ })
  await expect(buy).toBeVisible()
  await buy.click()
  await expect(page.getByText('تم شراء هذا اللاعب وإضافته للفريق بنجاح')).toBeVisible({ timeout: 20_000 })
  await page.getByRole('button', { name: 'رائع' }).click()

  // One of his own on the list at his value, then withdrawn.
  await page.getByRole('tab', { name: /بيع لاعبيّ/ }).click()
  const sell = page.getByRole('region', { name: 'بيع لاعبيّ' })
  await sell.getByRole('button', { name: 'بيع', exact: true }).first().click()
  await page.getByRole('button', { name: 'اعرضه بقيمته' }).click()
  const listed = sell.getByRole('button', { name: 'معروض للبيع' })
  await expect(listed).toHaveCount(1, { timeout: 20_000 })
  await listed.click()
  await page.getByRole('button', { name: 'اسحبه من قائمة الانتقالات' }).click()
  await expect(listed).toHaveCount(0, { timeout: 20_000 })
})
