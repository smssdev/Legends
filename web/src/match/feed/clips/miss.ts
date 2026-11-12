// @ts-nocheck
// [Sprint 57 W4] The miss scene (art.ts's SCENES.miss).
import { t as tr } from '../../../lib/i18n'
import { boom, burst, danger, dust, shakeIt, tint } from '../effects'
import { player, put, title } from '../figures'
import { K, bez, ease, el, lerp, other, rnd, sa, seg } from '../kit'
import { openPlay } from '../play'
import { LINE } from '../stage'

export function miss(e) {
  const KT = 2.9, { svg, go } = openPlay(e, 'miss', KT), dg = danger(svg), post = e.how === 'post'
  // [Sprint 42 H2] Over the bar, one in two: into the stand, where a fan catches it and his popcorn goes everywhere.
  // Wide, one in two: it hits the photographer behind the goal, who goes over backwards, his flash going off.
  const V = rnd((e.v ?? 3) * 7 + 1)(), fan = e.how === 'over' && V < 0.5, snap = e.how === 'wide' && V < 0.5
  const fanG = fan ? el('g', { opacity: 0 }, svg.world) : null
  if (fanG) fanG.innerHTML = '<rect x="-11" y="0" width="22" height="26" rx="7" fill="' + (K(other(e.side)).kit) + '"/><circle cy="-9" r="9" fill="#D9A982"/><circle cx="-3" cy="-10" r="1.4" fill="#111"/><circle cx="3" cy="-10" r="1.4" fill="#111"/><ellipse cx="0" cy="-4" rx="2.2" ry="2.8" fill="#5A1A14"/><rect data-a="1" x="-15" y="-2" width="5" height="18" rx="2.5" fill="' + (K(other(e.side)).kit) + '"/><rect data-a="2" x="10" y="-2" width="5" height="18" rx="2.5" fill="' + (K(other(e.side)).kit) + '"/><path d="M12 18 L22 18 L20 30 L14 30 Z" fill="#E9EEF6" stroke="#D21F1F"/>'
  const corn = fan ? dust(svg, svg.world, 12, ['#FFF3C4', '#FFE08A', '#FFFFFF']) : null
  const ph = snap ? player(svg.world, '#2A2F45', '', 0.9, { look: 13, shorts: '#111827', socks: '#111827' }) : null
  const cam2 = snap ? el('g', {}, svg.world) : null
  if (cam2) cam2.innerHTML = '<rect x="-8" y="-6" width="16" height="11" rx="2" fill="#111"/><circle r="4" fill="#333" stroke="#888"/><rect x="-4" y="-9" width="8" height="3" fill="#111"/>'
  const flashB = snap ? burst(svg, svg.world, '#FFFFFF', 12) : null, ouch = snap ? boom(svg, svg.world, 'BONK!') : null
  // [Sprint 42 C4] The woodwork: it rings and shakes the screen, a flash of blue shock, the striker's hands on his head.
  const blue = post ? tint(svg, '#3B82F6') : null, clang = post ? boom(svg, svg.world, 'CLANG!', '#E9EEF6', '#1E3A8A') : null, ringL = post ? burst(svg, svg.world, '#FFFFFF', 10) : null
  const tt = title(svg, e.how === 'post' ? tr('القائم!') : e.how === 'over' ? tr('فوق العارضة') : tr('بجانب القائم'), '#C9D2E1')
  return { dur: 5.0, svg, update(t) {
    const r = go(t); dg(t, r)
    if (fan) {
      // In the stand beside the goal; the ball flies on into his hands.
      const x = r.target[0] + (r.target[0] >= 320 ? 120 : -120), y = 92, f = seg(t, KT + 0.1, KT + 0.25)
      if (t > KT) { const g = ease(seg(t, KT, KT + 0.45)); const p = bez([r.target, [lerp(r.target[0], x, 0.5), 20], [x, y - 4]], g); r.b.set(p[0], p[1], 140, t * 900, 1) }
      sa(fanG, 'opacity', f); sa(fanG, 'transform', `translate(${x.toFixed(1)} ${(y + 6 * (1 - f)).toFixed(1)}) scale(.9)`)
      const up = t > KT + 0.3 ? 165 : 20
      sa(fanG.querySelector('[data-a="1"]'), 'transform', `rotate(${up} -12 0)`); sa(fanG.querySelector('[data-a="2"]'), 'transform', `rotate(${-up} 12 0)`)
      corn(x + 16, y + 20, seg(t, KT + 0.6, KT + 1.6))
    }
    if (snap) {
      const x = r.target[0] + (r.target[0] > 320 ? 26 : -26), y = LINE - 4, hit = seg(t, KT + 0.05, KT + 0.5)
      put(ph, x, y, (r.target[0] > 320 ? 1 : -1) * 80 * ease(hit), 0.9, 0); ph.face?.('front'); ph.mood(hit > 0 ? 'shock' : 'focus'); ph.pose(30, -30, 150, -40)
      sa(cam2, 'transform', `translate(${(x - 4).toFixed(1)} ${(y - 52 - 30 * Math.sin(Math.PI * hit)).toFixed(1)}) rotate(${Math.round(hit * 400)})`)
      flashB(x, y - 50, seg(t, KT + 0.05, KT + 0.35), 6); ouch(x + (r.target[0] > 320 ? 30 : -30), y - 82, seg(t, KT, KT + 0.6))
    }
    if (post) {
      const k = seg(t, KT - 0.02, KT + 0.8)
      clang(r.target[0], r.target[1] - 10, k); ringL(r.target[0], r.target[1], seg(t, KT, KT + 0.5), 14)
      shakeIt(svg, 8 * seg(t, KT, KT + 0.04) * (1 - seg(t, KT + 0.05, KT + 0.7)), t)
      blue(0.28 * seg(t, KT + 0.05, KT + 0.15) * (1 - seg(t, KT + 0.4, KT + 0.9)))
      if (t > KT + 0.3) { r.sh.face?.('front'); r.sh.mood('shock'); r.sh.pose(3, -3, 150, -150) }
    }
    tt(seg(t, KT + 0.35, KT + 0.75))
  } }
}
