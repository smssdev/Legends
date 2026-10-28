// Every screen at four widths [Sprint 21 E3.3]: no sideways scroll, nothing overlapping, nothing jumping while it loads.
//
//   (backend) php artisan serve      (web) npx vite
//   node tools/web/responsive_audit.cjs [http://localhost:5173] [out-dir]
//
// Signs up a fresh coach, gives them the coins a league costs (php artisan tinker, development only), makes and starts
// a league, then opens each screen at 360, 768, 1280 and 1920 pixels in Arabic and in English. For each it reports
// the sideways overflow, visible elements that overlap a sibling, how far the page moved between the first paint and
// the settled page (layout shift), and Arabic left in the English page. A screenshot of each is saved in out-dir.
// Exits 1 when any screen fails, so it can gate a change.
const { chromium } = require('playwright')
const { execFileSync } = require('child_process')
const fs = require('fs')
const path = require('path')

const BASE = process.argv[2] || 'http://localhost:5173'
const OUT = process.argv[3] || path.join(require('os').tmpdir(), 'glm-audit')
const WIDTHS = (process.env.WIDTHS || '360,768,1280,1920').split(',').map(Number)
const BACKEND = path.join(__dirname, '..', '..', 'backend')

async function api(page, method, url, body) {
  return page.evaluate(async ([method, url, body]) => {
    const xsrf = decodeURIComponent(document.cookie.match(/(?:^|; )XSRF-TOKEN=([^;]*)/)?.[1] ?? '')
    const r = await fetch('/api/v1' + url, { method, credentials: 'same-origin', headers: { Accept: 'application/json', 'Content-Type': 'application/json', 'X-XSRF-TOKEN': xsrf }, body: body ? JSON.stringify(body) : undefined })
    return { status: r.status, json: await r.json().catch(() => null) }
  }, [method, url, body])
}

async function setup(page) {
  await page.goto(BASE + '/login')
  await page.evaluate(() => fetch('/sanctum/csrf-cookie', { credentials: 'same-origin' }))
  const username = 'audit' + Date.now().toString(36)
  const reg = await api(page, 'POST', '/auth/register', { name: 'Audit Coach', username, password: 'audit-pass-1' })
  if (reg.status !== 201) throw new Error('register ' + reg.status + ' ' + JSON.stringify(reg.json))
  const id = reg.json.user.id
  execFileSync('php', ['artisan', 'tinker', '--execute', `App\\Wallet\\Wallet::post(${id}, 'daily', 100000, 'audit:${id}');`], { cwd: BACKEND })
  const template = 'Premier League'
  const clubs = await api(page, 'GET', '/data/clubs?league=' + encodeURIComponent(template))
  const starts = new Date(Date.now() + 86400000).toISOString()
  const made = await api(page, 'POST', '/leagues', { template, team_count: 20, rounds_per_day: 1, round_times: ['21:00'], prep_days: 2, season_end_mode: 'renew',
    starts_at: starts, starting_budget: 3000000, fair_league: true, integrity: true, club_id: clubs.json.clubs[0].id })
  if (made.status !== 201) throw new Error('league ' + made.status + ' ' + JSON.stringify(made.json))
  const league = made.json.league.id
  await api(page, 'POST', `/leagues/${league}/start`)
  return { league }
}

// What a screen looks like once settled: overflow, overlapping siblings, and Arabic left in English.
function inspect() {
  const doc = document.documentElement
  const overflow = doc.scrollWidth - window.innerWidth
  const overlaps = []
  const visible = (el) => {
    const s = getComputedStyle(el)
    const r = el.getBoundingClientRect()
    return s.visibility !== 'hidden' && s.display !== 'none' && s.position !== 'absolute' && s.position !== 'fixed' && r.width > 4 && r.height > 4 && +s.opacity > 0.05
  }
  for (const parent of document.querySelectorAll('main *')) {
    if (parent.closest('svg')) continue
    const kids = [...parent.children].filter(visible)
    if (kids.length < 2 || kids.length > 40) continue
    const s = getComputedStyle(parent)
    if (s.display === 'grid' && s.gridTemplateAreas !== 'none') continue
    for (let i = 0; i < kids.length; i++) for (let j = i + 1; j < kids.length; j++) {
      const a = kids[i].getBoundingClientRect(), b = kids[j].getBoundingClientRect()
      const w = Math.min(a.right, b.right) - Math.max(a.left, b.left), h = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top)
      if (w > 6 && h > 6) overlaps.push(`${kids[i].tagName.toLowerCase()}.${(kids[i].className?.baseVal ?? kids[i].className ?? '').toString().split(' ')[0]} × ${kids[j].tagName.toLowerCase()} (${Math.round(w)}×${Math.round(h)})`)
    }
  }
  // The language switch names Arabic in Arabic (lang="ar"): that is right in English too.
  const main = document.querySelector('main')?.cloneNode(true)
  main?.querySelectorAll('[lang="ar"]').forEach((n) => n.remove())
  if (main) { main.style.cssText = 'position:absolute;left:-99999px'; document.body.appendChild(main) }
  const text = main?.innerText ?? ''
  main?.remove()
  const arabic = doc.lang === 'en' ? [...new Set((text.match(/[؀-ۿ][؀-ۿ\s،؟]{3,}/g) ?? []).map((x) => x.trim()))].slice(0, 6) : []
  return { overflow, overlaps: overlaps.slice(0, 6), arabic }
}

;(async () => {
  fs.mkdirSync(OUT, { recursive: true })
  const browser = await chromium.launch()
  const ctx = await browser.newContext()
  const page = await ctx.newPage()
  const { league } = await setup(page)
  // Once for every page this tab opens: the layout shift since the first paint.
  await page.addInitScript(() => {
    window.__shift = 0
    window.__moved = []
    const name = (n) => n && n.nodeType === 1 ? `${n.tagName.toLowerCase()}.${String(n.className?.baseVal ?? n.className ?? '').split(' ').slice(0, 3).join('.')}` : '?'
    new PerformanceObserver((l) => l.getEntries().forEach((e) => {
      if (e.hadRecentInput) return
      window.__shift += e.value
      if (e.value > 0.02) window.__moved.push(`${e.value.toFixed(3)}: ${(e.sources ?? []).map((x) => name(x.node)).join(', ')}`)
    })).observe({ type: 'layout-shift', buffered: true })
  })
  const screens = ['/', '/leagues', `/leagues/${league}`, '/team', '/lineup', '/tactics', '/training', '/specialists', '/market', '/scout', '/stadium', '/finance',
    '/match', '/stats', `/leagues/${league}/predictions`, `/leagues/${league}/newspaper`, '/inbox', '/profile', '/wallet', '/leagues/new']
  let failed = 0
  for (const lang of (process.env.LANGS || 'ar,en').split(',')) {
    await page.evaluate((l) => localStorage.setItem('glm.locale', l), lang)
    for (const width of WIDTHS) {
      await page.setViewportSize({ width, height: width < 768 ? 800 : 900 })
      for (const screen of screens) {
        await page.goto(BASE + screen, { waitUntil: 'networkidle' }).catch(() => {})
        await page.waitForTimeout(500)
        const r = await page.evaluate(inspect)
        const shift = await page.evaluate(() => Math.round((window.__shift ?? 0) * 1000) / 1000)
        const moved = shift > 0.1 ? await page.evaluate(() => window.__moved ?? []) : []
        const bad = r.overflow > 1 || r.overlaps.length > 0 || shift > 0.1 || r.arabic.length > 0
        if (bad) failed++
        const name = `${lang}-${width}-${screen.replace(/\W+/g, '_') || 'home'}`
        await page.screenshot({ path: path.join(OUT, name + '.png'), fullPage: true })
        console.log(`${bad ? 'FAIL' : 'ok  '} ${lang} ${String(width).padStart(4)} ${screen.padEnd(28)} overflow=${r.overflow} shift=${shift}` +
          (moved.length ? `\n       moved: ${moved.join(' | ')}` : '') + (r.overlaps.length ? `\n       overlaps: ${r.overlaps.join(' | ')}` : '') + (r.arabic.length ? `\n       arabic: ${r.arabic.join(' | ')}` : ''))
      }
    }
  }
  await browser.close()
  console.log(failed ? `\n${failed} screens to fix. Screenshots in ${OUT}` : `\nAll screens fine. Screenshots in ${OUT}`)
  process.exit(failed ? 1 : 0)
})().catch((e) => { console.error(e); process.exit(2) })
