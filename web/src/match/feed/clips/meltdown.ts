// @ts-nocheck
// [Sprint 57 W4] The meltdown scene (art.ts's SCENES.meltdown).
import { t as tr } from '../../../lib/i18n'
import { boom, headOf, tint, vein } from '../effects'
import { player, title } from '../figures'
import { K, ease, el, lerp, rnd, sa, seg } from '../kit'
import { cam, stage } from '../stage'

// [Sprint 42 F6] The coach's meltdown after a chance blasted over: hands on his head, he pulls his hair, kicks the
// bench away, throws his jacket down, fire coming out of his eyes.
export function meltdown(e) {
  const R = rnd(e.v ?? 71), svg = stage(e.side), w = svg.world, kit = K(e.side).kit
  el('rect', { x: -80, y: 236, width: 800, height: 110, fill: 'rgba(4,11,28,.55)' }, w)
  const bench = el('g', {}, w)
  bench.innerHTML = '<rect x="-60" y="-24" width="120" height="10" rx="3" fill="#0B1626" stroke="#4A5A78"/><rect x="-60" y="-14" width="120" height="6" fill="#16243A"/><rect x="-54" y="-8" width="6" height="22" fill="#4A5A78"/><rect x="48" y="-8" width="6" height="22" fill="#4A5A78"/>'
  const co = player(w, '#1F2937', '', 1.8, { look: Math.floor(R() * 40), shorts: '#1F2937', socks: '#111827', trim: kit })
  const jacket = el('path', { d: 'M-16 -14 L16 -14 L20 18 L-20 18 Z', fill: '#1F2937', stroke: kit, 'stroke-width': 2, opacity: 0 }, w)
  const fireL = el('g', { opacity: 0 }, w)
  fireL.innerHTML = '<path data-f="1" stroke="#FF7A1A" stroke-width="4" stroke-linecap="round"/><path data-f="1" stroke="#FFD400" stroke-width="2" stroke-linecap="round"/><path data-f="2" stroke="#FF7A1A" stroke-width="4" stroke-linecap="round"/><path data-f="2" stroke="#FFD400" stroke-width="2" stroke-linecap="round"/>'
  const hairs = el('g', { stroke: '#2A1A10', 'stroke-width': 1.6, opacity: 0 }, w)
  hairs.innerHTML = Array.from({ length: 6 }, (_, i) => `<path d="M${-10 + i * 4} 0 q2 -6 0 -10"/>`).join('')
  const redT = tint(svg, '#FF1E1E'), boomB = boom(svg, w, 'BANG!'), vn = vein(svg)
  const tt = title(svg, tr('المدرب ينفجر!'), '#EF4444')
  return { dur: 2.8, svg, update(t) {
    cam(svg, 1.1, 320, 190)
    redT(0.18 * seg(t, 0.05, 0.15) * (1 - seg(t, 0.6, 1.2)))
    const kick = seg(t, 0.9, 1.15), thr = seg(t, 1.5, 1.8)
    co.face?.('front'); co.mood('angry'); co.at(300, 190, 0, 1.8)
    if (t < 0.9) { const p = Math.sin(t * 28) * 10; co.pose(4, -4, 150 + p, -150 - p) }
    else if (t < 1.3) co.kick(kick)
    else if (t < 1.9) co.pose(4, -4, lerp(150, 60, thr), -lerp(150, 60, thr))
    else { const p = Math.sin(t * 20) * 8; co.pose(6, -6, 150 + p, -150 - p) }
    const [hx, hy] = headOf(300, 190, 1.8)
    vn(hx + 16, hy - 20, 1, t)
    // Tufts of hair pulled out, flying.
    sa(hairs, 'opacity', t > 0.3 && t < 1.0 ? 1 : 0); sa(hairs, 'transform', `translate(${hx} ${(hy - 20 - (t - 0.3) * 40).toFixed(1)}) rotate(${Math.round(t * 200)})`)
    // Fire from his eyes.
    const fl = Math.sin(t * 40) * 3, on = t > 0.25
    sa(fireL, 'opacity', on ? 1 : 0)
    for (const [i, e2] of [...fireL.children].entries()) { const sx = hx + (i < 2 ? -6 : 6), sy = hy + 0, d = i < 2 ? -1 : 1; sa(e2, 'd', `M${sx} ${sy} L${sx + d * (26 + fl)} ${sy - 8 + fl}`) }
    // The bench kicked away, spinning.
    const bf = ease(seg(t, 1.05, 1.9)); sa(bench, 'transform', `translate(${lerp(420, 700, bf).toFixed(1)} ${(250 - Math.sin(Math.PI * bf) * 90).toFixed(1)}) rotate(${Math.round(bf * 540)})`)
    boomB(430, 228, seg(t, 1.05, 1.6))
    // The jacket thrown to the ground.
    const jf = ease(seg(t, 1.7, 2.1)); sa(jacket, 'opacity', t > 1.7 ? 1 : 0); sa(jacket, 'transform', `translate(${lerp(300, 230, jf).toFixed(1)} ${lerp(150, 280, jf).toFixed(1)}) rotate(${Math.round(jf * 200)}) scale(${lerp(1.4, 1, jf).toFixed(2)} ${lerp(1.4, 0.35, jf).toFixed(2)})`)
    tt(seg(t, 0.15, 0.5))
  } }
}
