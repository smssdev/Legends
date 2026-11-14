// [Sprint 30 G8, Sprint 65 W1] An accessibility check (axe-core, free) of every screen of the game, in the night and the
// day and in Arabic and English: no «serious» or «critical» problem (a control with no name, an image with no text,
// a colour too faint on its ground, content outside the page's landmarks…). And the RTL basics: the page is right to
// left in Arabic, left to right in English.
import AxeBuilder from '@axe-core/playwright'
import { expect, test, type Page } from '@playwright/test'
import { ready, signUp } from './helpers'

const PUBLIC = ['/', '/login', '/register', '/forgot-password', '/privacy', '/terms', '/guide', '/download']
const COACH = [
  '/',
  '/leagues',
  '/leagues/new',
  '/club',
  '/team',
  '/lineup',
  '/tactics',
  '/market',
  '/match',
  '/fixtures',
  '/league',
  '/training',
  '/stadium',
  '/finance',
  '/stats',
  '/scout',
  '/specialists',
  '/takers',
  '/friendlies',
  '/quests',
  '/inbox',
  '/profile',
  '/groups',
  '/tournaments',
  '/tournaments/new',
  '/wallet',
  '/store',
  '/ideas',
  '/support',
  '/announcements',
  '/sim',
]
// [Sprint 65 W2] And, though axe calls them moderate: everything inside the page's landmarks, one main, an h1 on every page.
const LANDMARKS = ['region', 'landmark-one-main', 'page-has-heading-one']
const LOOKS = [
  ['ar', 'dark'],
  ['ar', 'light'],
  ['en', 'dark'],
  ['en', 'light'],
] as const

async function problems(page: Page) {
  const r = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'best-practice']).analyze()
  return r.violations
    .filter((v) => v.impact === 'serious' || v.impact === 'critical' || LANDMARKS.includes(v.id))
    .map(
      (v) =>
        `${v.id} (${v.nodes.length}): ${v.nodes
          .map((n) => n.target.join(' '))
          .slice(0, 3)
          .join(' | ')}`,
    )
}

async function look(page: Page, locale: string, theme: string) {
  await page.evaluate(
    ([l, t]) => {
      localStorage.setItem('glm.locale', l)
      localStorage.setItem('glm.theme', t)
    },
    [locale, theme],
  )
}

async function sweep(page: Page, paths: string[]) {
  const found: string[] = []
  for (const [locale, theme] of LOOKS) {
    await look(page, locale, theme)
    for (const path of paths) {
      await page.goto(path)
      await ready(page)
      await page.waitForTimeout(600) // the screen's data in (not networkidle: the live screens keep polling)
      await expect(page.locator('html'), path).toHaveAttribute('dir', locale === 'ar' ? 'rtl' : 'ltr')
      for (const p of await problems(page)) found.push(`${locale}/${theme} ${path}: ${p}`)
    }
  }
  return found
}

test('the visitor’s screens have no serious accessibility problem, in both languages and both looks', async ({ page }) => {
  test.setTimeout(300_000)
  await page.goto('/')
  expect(await sweep(page, PUBLIC)).toEqual([])
})

test('every screen of a coach has no serious accessibility problem, in both languages and both looks', async ({ page }) => {
  test.setTimeout(900_000)
  await signUp(page)
  await page.goto('/leagues/new')
  await ready(page)
  await page.locator('.league-tile').first().click()
  await page.getByRole('button', { name: 'أنشئ الدوري واختر فريقك' }).click()
  await page.locator('section[aria-label="أندية الدوري"] button').first().click()
  await page.getByRole('button', { name: /أنشئ الدوري بـ/ }).click()
  await expect(page).toHaveURL(/\/leagues\/\d+/, { timeout: 20_000 })
  const league = new URL(page.url()).pathname
  expect(await sweep(page, [...COACH, league])).toEqual([])
})
