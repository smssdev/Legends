// [Sprint 66 T5 (6)] A group between two coaches: one makes it with the other in it and writes a message and sends a
// picture; the other reads both and reports the message to the admins.
import { expect, test } from '@playwright/test'
import { ready, signUp } from './helpers'

test('a coach makes a group, writes and sends a picture, and the other member reports the message', async ({ browser }) => {
  const a = await (await browser.newContext()).newPage()
  const b = await (await browser.newContext()).newPage()
  const friend = await signUp(b)
  await signUp(a)

  // The group, with the friend in it.
  await a.goto('/groups')
  await ready(a)
  await a.getByRole('button', { name: 'جروب جديد' }).click()
  await a.getByLabel('اسم الجروب').fill('جروب التجربة')
  await a.getByLabel('أضف أعضاء بأسماء المستخدمين').fill(friend)
  await a.getByRole('button', { name: 'أنشئ الجروب' }).click()
  await expect(a).toHaveURL(/\/groups\/\d+/, { timeout: 20_000 })
  const group = new URL(a.url()).pathname

  // A message and a picture.
  await a.getByLabel('اكتب رسالة…').fill('أهلاً بالجميع في الجروب')
  await a.getByRole('button', { name: 'أرسل', exact: true }).click()
  await expect(a.getByText('أهلاً بالجميع في الجروب')).toBeVisible({ timeout: 20_000 })
  await a.locator('input[type="file"][accept="image/*"]').setInputFiles('e2e/fixtures/gold.png')
  await expect(a.locator('main img[alt="صورة"]').first()).toBeVisible({ timeout: 20_000 })

  // The friend reads them and reports the message.
  await b.goto(group)
  await ready(b)
  await expect(b.getByText('أهلاً بالجميع في الجروب')).toBeVisible({ timeout: 20_000 })
  await expect(b.locator('main img[alt="صورة"]').first()).toBeVisible()
  await b.getByRole('button', { name: /أهلاً بالجميع في الجروب/ }).click()
  await b.getByRole('button', { name: 'بلّغ عن الرسالة' }).click()
  await b.getByLabel('محتوى غير لائق').check()
  await b.getByRole('button', { name: 'أرسل البلاغ للإدارة' }).click()
  await expect(b.getByText('وصل البلاغ للإدارة. شكراً لك.')).toBeVisible({ timeout: 20_000 })
})
