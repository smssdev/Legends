// [Sprint 60 T1] The site and the app side by side: one page with each of the screens built on the approved drafts, the
// site's shot (web/e2e/visual.spec.ts, Playwright) beside the app's (mobile/test/shots, Flutter at 844×390), for the owner
// to judge whether they are one game: the order, the names and the parts the same.
//
// From the repository's root, after both sets of shots are current:
//   (cd web && COMPARE=1 npx playwright test e2e/compare.spec.ts)   → the site at 844×390, unmasked (tools/design/out/web/)
//   node tools/design/compare.mjs                 → tools/design/out/compare.html (one file, the images inside it)
// Without the first step the site's side is its committed visual shots (e2e/visual.spec.ts-snapshots, the numbers and
// names masked), at --size 915 (or 667) and --scheme dark (or light).
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..')
const arg = (name, fallback) => {
  const i = process.argv.indexOf(`--${name}`)
  return i > 0 ? process.argv[i + 1] : fallback
}
const size = arg('size', '915')
const scheme = arg('scheme', 'dark')
const webDir = join(root, 'web/e2e/visual.spec.ts-snapshots')
const liveDir = join(root, 'tools/design/out/web')
const appDir = join(root, 'mobile/test/shots/goldens')

// [screen, the site's shot, the app's shot, the draft]: sprints/60-app-design-parity.md, D1.
const SCREENS = [
  ['المكتب · Office', 'office', 'league', 'Office.html'],
  ['الفريق · Squad', 'squad', 'squad', 'Squad.html'],
  ['التشكيلة · Lineup', 'lineup', 'lineup', 'Lineup.html'],
  ['التكتيك · Tactics', 'tactics', 'tactics', 'Tactics.html'],
  ['السوق · Market', 'market', 'market', 'Market.html'],
  ['المباراة القادمة · Next match', 'next-match', 'next-match', 'NextMatch.html'],
  ['المباراة · Match', null, 'live', 'Match.html'],
  ['الرئيسية · Home', 'home', 'home', 'Home.html'],
  ['جدول المباريات · Fixtures', 'fixtures', 'league-matches', null],
]

const image = (file) => (existsSync(file) ? `data:image/png;base64,${readFileSync(file).toString('base64')}` : null)
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c])
const side = (label, src, note) =>
  `<figure><figcaption>${esc(label)}</figcaption>${src ? `<img src="${src}" alt="${esc(label)}" loading="lazy">` : `<p class="none">${esc(note)}</p>`}</figure>`

let missing = 0
const rows = SCREENS.map(([name, web, app, draft]) => {
  const live = web && image(join(liveDir, `${web}.png`))
  const w = live || (web && image(join(webDir, `${web}-${size}-${scheme}-linux.png`)))
  const a = image(join(appDir, `${app}.png`))
  if ((web && !w) || !a) missing++
  return `<section><h2>${esc(name)}${draft ? ` <small>docs/design/legends-ui/landscape/${esc(draft)}</small>` : ''}</h2><div class="pair">
${side(live ? 'الموقع 844×390' : `الموقع ${size} (لقطة مقنّعة)`, w, web ? 'لا لقطة: npx playwright test e2e/visual.spec.ts --update-snapshots' : 'المباراة الحية ليست في لقطات الموقع (تتطلب مباراة جارية)')}
${side('التطبيق 844×390', a, 'لا لقطة: flutter test test/shots --tags shots --run-skipped --update-goldens')}
</div></section>`
}).join('\n')

const html = `<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>GLM: الموقع والتطبيق</title>
<style>
:root { color-scheme: dark; --bg: #0b1626; --panel: #12233a; --text: #eef3fa; --muted: #93a3bf; --gold: #f5b82e; }
body { margin: 0; padding: 16px; background: var(--bg); color: var(--text); font: 15px/1.6 system-ui, sans-serif; }
h1 { margin: 0 0 4px; font-size: 22px; } h1 + p { margin: 0 0 20px; color: var(--muted); }
section { margin: 0 0 28px; padding: 14px; border-radius: 14px; background: var(--panel); }
h2 { margin: 0 0 10px; font-size: 17px; color: var(--gold); } h2 small { color: var(--muted); font-weight: 400; font-size: 12px; direction: ltr; unicode-bidi: isolate; }
.pair { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; align-items: start; }
@media (max-width: 900px) { .pair { grid-template-columns: 1fr; } }
figure { margin: 0; } figcaption { color: var(--muted); font-size: 13px; margin-bottom: 4px; }
img { width: 100%; height: auto; border-radius: 8px; display: block; }
.none { padding: 24px; border: 1px dashed var(--muted); border-radius: 8px; color: var(--muted); }
</style></head><body>
<h1>الموقع والتطبيق جنباً إلى جنب</h1>
<p>Sprint 60 T1: كل شاشة بُنيت على مسودتها، لقطة الموقع (Playwright) بجانب لقطة التطبيق (Flutter). المطلوب: الترتيب والأسماء والمكونات واحدة.</p>
${rows}
</body></html>
`
const out = join(root, 'tools/design/out')
mkdirSync(out, { recursive: true })
writeFileSync(join(out, 'compare.html'), html)
console.log(`compare: ${SCREENS.length} screens → tools/design/out/compare.html${missing ? ` (${missing} without a shot)` : ''}`)
