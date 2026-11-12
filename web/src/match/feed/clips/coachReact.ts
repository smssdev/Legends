// @ts-nocheck
// [Sprint 57 W4] The coachReact scene (art.ts's SCENES.coachReact).
import { t as tr } from '../../../lib/i18n'
import { title } from '../figures'
import { K, ease, el, sa, seg } from '../kit'
import { cam, ref, stage } from '../stage'

// A coach on his touchline in his mood (the server's), the approved 3D model of his look (C1 to C3, Sprint 26):
// his joy at a goal, his anger at a goal against or a red card, his worry at a chance missed.
export function coachReact(e) {
  const svg = stage(e.side), w = svg.world
  el('rect', { x: -80, y: 236, width: 800, height: 110, fill: 'rgba(4,11,28,.55)' }, w)
  el('rect', { x: 60, y: 168, width: 520, height: 12, rx: 4, fill: '#0B1626' }, w)
  el('rect', { x: 60, y: 166, width: 520, height: 3, fill: 'rgba(200,215,235,.4)' }, w)
  el('path', { d: 'M100 300 H540', stroke: 'rgba(255,255,255,.7)', 'stroke-width': 2, 'stroke-dasharray': '8 6' }, w)
  const look = ['C1', 'C2', 'C3'].includes(e.look) ? e.look : 'C1', mood = e.mood ?? 'joy'
  const img = el('image', { href: `/characters/${look.toLowerCase()}-${mood}.webp`, x: 205, y: 8, width: 250, height: 325, preserveAspectRatio: 'xMidYMax meet' }, svg)
  const glow = el('circle', { cx: 360, cy: 180, r: 120, fill: K(e.side).kit, opacity: 0, filter: ref(svg, 'soft') }, svg)
  svg.insertBefore(glow, img)
  const words = { joy: 'فرحة المدرب', cheer: 'فرحة المدرب', angry: 'غضب المدرب', worried: 'قلق المدرب', sad: 'حسرة المدرب', surprise: 'دهشة المدرب', think: 'المدرب يفكر' }
  const tt = title(svg, tr(words[mood] ?? 'المدرب'), mood === 'angry' ? '#EF4444' : mood === 'joy' || mood === 'cheer' ? undefined : '#C9D2E1')
  return { dur: 2.4, svg, update(t) {
    cam(svg, 1.05 + 0.06 * t / 2.4, 320, 200)
    const f = ease(seg(t, 0, 0.35))
    sa(img, 'transform', `translate(${(1 - f) * 80} 0)`); sa(img, 'opacity', f)
    sa(glow, 'opacity', 0.35 * f)
    tt(seg(t, 0.2, 0.6))
  } }
}
