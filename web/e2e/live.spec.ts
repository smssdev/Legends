// [Sprint 66 T5 (4)] A live match between two coaches on two devices (the simulator's room: the same live screen as a
// league match, without the league's scheduler): an order before the whistle, the coach's window at the 15th minute,
// and the end on both screens. The room's minutes follow the game's clock on the server, so clock:travel brings the
// window and the whistle sooner; the clock goes back however the test ends.
import { expect, test, type Page } from '@playwright/test'
import { artisan, ready } from './helpers'

test.afterEach(() => {
  artisan('clock:travel', 'reset')
})

async function pick(page: Page, name: string, club: string) {
  await page.getByPlaceholder('مثلاً: سليمان').fill(name)
  await page.getByPlaceholder(/ابحث عن نادٍ/).fill(club)
  await page.getByRole('region', { name: 'اختر فريقك' }).getByRole('button').first().click()
}

test('two coaches play a live match from two devices: an order, the window, the end', async ({ browser }) => {
  test.setTimeout(240_000)
  const host = await (await browser.newContext()).newPage()
  const guest = await (await browser.newContext()).newPage()

  // The host opens a room; the guest comes in from its link.
  await host.goto('/sim/room')
  await ready(host)
  await pick(host, 'المضيف', 'ريال')
  await host.getByRole('button', { name: 'افتح الغرفة' }).click()
  const link = await host.getByLabel('رابط الغرفة').inputValue()
  expect(link).toMatch(/\/sim\/room\/\w+/)
  await guest.goto(new URL(link).pathname)
  await ready(guest)
  await pick(guest, 'الضيف', 'برشلونة')
  await guest.getByRole('button', { name: 'ادخل المباراة' }).click()
  await expect(guest).toHaveURL(/\/sim\/[a-z0-9-]+$/i, { timeout: 20_000 })
  await expect(host).toHaveURL(guest.url(), { timeout: 20_000 })

  // An order before the whistle, from the host's drawer.
  await host.getByRole('button', { name: 'الأوامر' }).click()
  const drawer = host.getByRole('complementary', { name: 'لوحة المدرب' })
  await drawer.getByRole('tab', { name: 'تكتيك' }).click()
  await drawer.getByRole('combobox', { name: 'خطة اللعب' }).selectOption({ label: 'هجوم مرتد' })
  await drawer.getByRole('button', { name: 'طبّق في الدقيقة التالية' }).click()
  await expect(drawer.getByText(/يُطبق مع صافرة البداية|يُطبق في الدقيقة القادمة|طُبّق في الدقيقة/).first()).toBeVisible({ timeout: 20_000 })

  // To about the 10th minute, then the minutes play on screen up to the 15th: the window opens for the coach (a minute
  // caught up in a jump does not open it, as for a coach coming back late).
  artisan('clock:travel', '+30s')
  await expect(drawer.getByText('النافذة مفتوحة')).toBeVisible({ timeout: 60_000 })

  // The whistle: past the 90 minutes, both coaches come back to the match and find it over.
  artisan('clock:travel', '+30m')
  for (const p of [host, guest]) {
    await p.reload()
    await ready(p)
    await expect(p.getByText('نهاية المباراة').first()).toBeVisible({ timeout: 60_000 })
  }
})
