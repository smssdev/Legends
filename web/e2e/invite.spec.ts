// [Sprint 66 T5 (5)] A friend invited by the league's link: two coaches in two browsers. The owner shares the link,
// the friend opens it and asks to join, the owner approves, and the friend takes a club.
import { expect, test } from '@playwright/test'
import { makeLeague, ready, signContract, signUp } from './helpers'

test('a friend opens the league’s invitation link, is approved by its owner and takes a club', async ({ browser }) => {
  const owner = await (await browser.newContext()).newPage()
  const friend = await (await browser.newContext()).newPage()

  await signUp(owner)
  const league = await makeLeague(owner)
  await signContract(owner)
  await owner.getByRole('tab', { name: 'الموسم' }).click()
  const card = owner
    .locator('section, div')
    .filter({ has: owner.getByRole('heading', { name: 'ادعُ أصحابك' }) })
    .last()
  const code = (await card.locator('[dir="ltr"]').first().textContent())!.trim()
  expect(code).toMatch(/^[A-Z0-9]{8}$/)

  // The friend, from the link.
  await signUp(friend)
  await friend.goto(`/join/${code}`)
  await ready(friend)
  await friend.getByRole('button', { name: 'أرسل طلب الانضمام' }).click()
  await expect(friend.getByRole('heading', { name: /^طلبك وصل لـ/ })).toBeVisible({ timeout: 20_000 })

  // The owner approves him.
  await owner.goto(league)
  await ready(owner)
  await signContract(owner)
  await owner.getByRole('tab', { name: /المدربون/ }).click()
  await owner.getByRole('button', { name: 'وافق', exact: true }).click()
  await expect(owner.getByText('وافقت', { exact: true })).toBeVisible({ timeout: 20_000 })

  // The friend takes a club still with a bot.
  await expect(friend.getByRole('heading', { name: /على طلبك$/ })).toBeVisible({ timeout: 30_000 })
  await friend.getByRole('link', { name: 'اختر فريقك' }).click()
  await ready(friend)
  await friend.getByRole('list', { name: 'الأندية' }).getByRole('button').filter({ hasText: 'متاح' }).first().click()
  await friend.getByRole('button', { name: /^استلم تدريب/ }).click()
  await expect(friend).toHaveURL(/\/leagues\/\d+|\/club|\/$/, { timeout: 20_000 })
  await expect(friend).not.toHaveURL(/pick/)
})
