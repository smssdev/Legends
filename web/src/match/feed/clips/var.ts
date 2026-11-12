// [Sprint 57 W4] The var scene (art.ts's SCENES.var).
import { t as tr } from '../../../lib/i18n'
import { title } from '../figures'
import { type SceneData, ease, el, sa, seg } from '../kit'
import { openPlay } from '../play'

// [Sprint 35 C3] A goal ruled out by VAR: the move and the ball in the net (the scorer away to celebrate), then
// the referee's hand to his ear, the screen drawn in the air, the check (the offside lines, or the foul ringed),
// and «لا هدف».
export function varCheck(e: SceneData) {
  const KT = 3.0, { svg, go } = openPlay({ ...e, quality: e.quality ?? 'big' }, 'goal', KT)
  const shade = el('rect', { width: 640, height: 340, fill: 'rgba(8,18,40,.55)', opacity: 0 }, svg)
  const badge = el('g', { opacity: 0 }, svg)
  badge.innerHTML = `<rect x="-70" y="-26" width="140" height="52" rx="10" fill="#071733" stroke="#F5B82E" stroke-width="2"/><text y="10" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="30" fill="#FFD36B" letter-spacing="4">VAR</text>`
  const check = el('text', { x: 320, y: 300, 'text-anchor': 'middle', 'font-family': 'Tajawal, sans-serif', 'font-weight': 800, 'font-size': 18, fill: '#C9D2E1', opacity: 0 }, svg)
  check.textContent = e.reason === 'foul' ? tr('مراجعة الفار: خطأ محتمل') : tr('مراجعة الفار: تسلل محتمل')
  const scan = el('rect', { x: 0, y: 0, width: 640, height: 3, fill: '#7FB4FF', opacity: 0 }, svg)
  const lines = el('g', { opacity: 0 }, svg)
  lines.innerHTML = e.reason === 'foul'
    ? `<circle cx="300" cy="215" r="34" fill="none" stroke="#EF4444" stroke-width="4" stroke-dasharray="10 6"/>`
    : `<path d="M200 70 L170 330" stroke="#EF4444" stroke-width="3"/><path d="M232 70 L206 330" stroke="#2BB673" stroke-width="3"/>`
  const tv = el('rect', { x: -28, y: -18, width: 56, height: 36, rx: 3, fill: 'none', stroke: '#fff', 'stroke-width': 3, opacity: 0 }, svg)
  const no = title(svg, tr('لا هدف'), '#EF4444')
  const sub = el('text', { x: 320, y: 86, 'text-anchor': 'middle', 'font-family': 'Tajawal, sans-serif', 'font-weight': 800, 'font-size': 20, fill: '#fff', stroke: '#040B1C', 'stroke-width': 4, 'paint-order': 'stroke', opacity: 0 }, svg)
  sub.textContent = e.reason === 'foul' ? tr('خطأ قبل الهدف') : tr('تسلل')
  return { dur: 8.2, svg, update(t: number) {
    // The goal as it seemed, then the frame stays as the check runs.
    go(Math.min(t, 3.9))
    const c = seg(t, 4.0, 4.4) * (1 - seg(t, 7.8, 8.2))
    sa(shade, 'opacity', 0.9 * c)
    sa(badge, 'opacity', c); sa(badge, 'transform', `translate(96 296) scale(${0.6 + 0.1 * ease(seg(t, 4.0, 4.4))})`)
    // The referee draws the screen in the air.
    const d = seg(t, 4.3, 5.0)
    sa(tv, 'opacity', d > 0 && t < 6.4 ? 1 : 0); sa(tv, 'transform', `translate(320 228) scale(${0.3 + 0.7 * ease(d)})`)
    sa(check, 'opacity', seg(t, 4.6, 5.0) * (1 - seg(t, 6.2, 6.4)))
    sa(scan, 'opacity', t > 4.8 && t < 6.4 ? 0.8 : 0); sa(scan, 'y', 40 + ((t - 4.8) * 160) % 260)
    sa(lines, 'opacity', seg(t, 5.2, 5.6) * (1 - seg(t, 7.6, 8.0)))
    no(seg(t, 6.4, 6.8)); sa(sub, 'opacity', seg(t, 6.6, 7.0))
  } }
}
