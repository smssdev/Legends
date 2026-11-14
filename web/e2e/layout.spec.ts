// [Sprint 51 W1] Nothing scrolls a screen sideways: every screen of a club, on a phone turned sideways (the game's own
// way), a small phone and a computer. A badge on the top bar once hung 2px off the edge of every club screen.
import { expect, test } from '@playwright/test'
import { ready, signUp } from './helpers'

// [Sprint 56 T1] The screens rebuilt to fit one phone held sideways: they do not scroll inside the frame either, every
// target answers a 44px touch (its own box, or the 44px area its ::after spreads around it) and no text is under 12px.
const FIT = new Set(['/club', '/team', '/lineup', '/tactics', '/market', '/match', '/fixtures'])
const SCREENS = [
  '/club',
  '/team',
  '/lineup',
  '/tactics',
  '/market',
  '/match',
  '/training',
  '/stadium',
  '/finance',
  '/stats',
  '/scout',
  '/specialists',
  '/takers',
  '/friendlies',
  '/quests',
  '/fixtures',
  '/',
  '/leagues',
  '/inbox',
  '/profile',
]

// [Sprint 55 W5] And the frame keeps to its share: on a phone held sideways the bar (the frame's height) is under 15% of
// the screen's (it was 35% with the old top bar and menu row). The screen scrolls inside the frame now, so «sideways»
// is measured on the screen's own box (.shell-page) as well as the page.
test('no screen scrolls sideways, on a phone or a computer', async ({ page }) => {
  test.setTimeout(600_000) // 60 screens
  await signUp(page)
  await page.goto('/leagues/new')
  await ready(page)
  await page.locator('.league-tile').first().click()
  await page.getByRole('button', { name: 'أنشئ الدوري واختر فريقك' }).click()
  await page.locator('section[aria-label="أندية الدوري"] button').first().click()
  await page.getByRole('button', { name: /أنشئ الدوري بـ/ }).click()
  await expect(page).toHaveURL(/\/leagues\/\d+/, { timeout: 20_000 })

  const wide: string[] = []
  const frame: string[] = []
  const fit: string[] = []
  for (const [width, height] of [
    [915, 412],
    [667, 375],
    [1440, 900],
  ]) {
    await page.setViewportSize({ width, height })
    for (const path of SCREENS) {
      await page.goto(path)
      await ready(page)
      await page.waitForTimeout(800) // the screen's data in (not networkidle: the live screens keep polling)
      const m = await page.evaluate(() => {
        const box = document.querySelector('.shell-page')
        const bar = document.querySelector('.shell-bar')?.getBoundingClientRect().height ?? 0
        return {
          scroll: document.documentElement.scrollWidth,
          client: document.documentElement.clientWidth,
          inner: box ? box.scrollWidth - box.clientWidth : 0,
          bar,
          h: innerHeight,
          page: document.documentElement.scrollHeight,
        }
      })
      if (m.scroll > m.client) wide.push(`${width}×${height} ${path}: ${m.scroll} > ${m.client}`)
      if (m.inner > 1) wide.push(`${width}×${height} ${path}: the screen ${m.inner}px wider than its box`)
      if (width < 1000 && m.bar / m.h >= 0.15) frame.push(`${width}×${height} ${path}: the bar is ${Math.round((m.bar / m.h) * 100)}%`)
      if (m.page > m.h) frame.push(`${width}×${height} ${path}: the page itself scrolls (${m.page} > ${m.h})`)
      if (FIT.has(path) && width < 1000) {
        const f = await page.evaluate(() => {
          const main = document.querySelector<HTMLElement>('.shell-main')!
          const shown = (el: Element) => {
            const r = el.getBoundingClientRect()
            const s = getComputedStyle(el)
            return r.width > 0 && r.height > 0 && s.visibility !== 'hidden' && r.bottom > 0 && r.top < innerHeight
          }
          const small = [
            ...document.querySelectorAll(
              '.shell-page button, .shell-page a[href], .shell-page input, .shell-page select, .shell-page [role=tab], .shell-page [role=switch]',
            ),
          ]
            .filter(shown)
            .filter((el) => {
              const r = el.getBoundingClientRect()
              if (r.width >= 44 && r.height >= 44) return false
              const a = getComputedStyle(el, '::after')
              return !(a.position === 'absolute' && a.content !== 'none')
            })
            .map(
              (el) =>
                `${Math.round(el.getBoundingClientRect().width)}×${Math.round(el.getBoundingClientRect().height)} ${(el.textContent || el.getAttribute('aria-label') || '').trim().slice(0, 20)}`,
            )
          const tiny: string[] = []
          const w = document.createTreeWalker(document.querySelector('.shell-page')!, NodeFilter.SHOW_TEXT)
          while (w.nextNode()) {
            const pe = w.currentNode.parentElement
            if (!w.currentNode.textContent?.trim() || !pe || !shown(pe)) continue
            const fs = parseFloat(getComputedStyle(pe).fontSize)
            if (fs < 12 && !pe.closest('[aria-hidden=true]')) tiny.push(`${fs}px ${w.currentNode.textContent.trim().slice(0, 16)}`)
          }
          return { scroll: main.scrollHeight - main.clientHeight, small, tiny }
        })
        if (f.scroll > 1) fit.push(`${width}×${height} ${path}: scrolls ${f.scroll}px inside the frame`)
        for (const x of f.small.slice(0, 5)) fit.push(`${width}×${height} ${path}: target ${x}`)
        for (const x of f.tiny.slice(0, 5)) fit.push(`${width}×${height} ${path}: text ${x}`)
      }
    }
  }
  expect(wide).toEqual([])
  expect(frame).toEqual([])
  expect(fit).toEqual([])
})
