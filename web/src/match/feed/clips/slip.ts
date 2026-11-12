// [Sprint 57 W4] The slip scene (art.ts's SCENES.slip).
import { t as tr } from '../../../lib/i18n'
import { dust } from '../effects'
import { ball, player, title } from '../figures'
import { K, SMOOTH, type SceneData, el, lerp, other, rnd, sa, seg } from '../kit'
import { cam, stage } from '../stage'

// [Sprint 42 F8] A slip in the rain: a downpour, he runs with the ball, loses his feet and slides a long way on his
// belly like a penguin in a spray of water and mud, the ball stops where he left it, and the other side takes it.
export function slip(e: SceneData) {
  const R = rnd(Number(e.no || 7) * 67), svg = stage(e.side), w = svg.world, k = 1.4
  const pl = player(w, K(e.side).kit, e.no, k, { look: Math.floor(R() * 40) }), df = player(w, K(other(e.side)).kit, e.defNo ?? '', k, { look: Math.floor(R() * 40) }), b = ball(svg)
  const rain = el('g', { stroke: 'rgba(200,220,245,.75)', 'stroke-width': 1.6, 'stroke-linecap': 'round' }, svg)
  const dropsR = Array.from({ length: SMOOTH ? 40 : 110 }, () => el('line', {}, rain))
  el('rect', { width: 640, height: 340, fill: 'rgba(40,60,90,.22)', 'pointer-events': 'none' }, svg)
  const splash = dust(svg, w, 10, ['#7FB4FF', '#5B3A1E', '#A7D3FF', '#6B4A2A']), splash2 = dust(svg, w, 8, ['#A7D3FF', '#5B3A1E'])
  const tt = title(svg, tr('انزلاق!'), '#7FB4FF')
  const KT = 1.0
  return { dur: 3.6, svg, update(t: number) {
    cam(svg, 1.06, 320, 210)
    dropsR.forEach((l, i) => { const x = (i * 73) % 680 - 20, y = ((i * 41 + t * 700) % 380) - 30; sa(l, 'x1', x); sa(l, 'y1', y.toFixed(0)); sa(l, 'x2', x - 6); sa(l, 'y2', (y + 18).toFixed(0)) })
    // He runs with it, his feet go (1.0), up in the air, then a long slide on his belly.
    let x, y, r = 0
    if (t < KT) { x = lerp(80, 280, seg(t, 0, KT)); y = 200; pl.face?.('side', 1); pl.mood('focus'); pl.run(t * 14, 1) }
    else if (t < KT + 0.3) { const f = seg(t, KT, KT + 0.3); x = lerp(280, 320, f); y = lerp(200, 262, f) - Math.sin(Math.PI * f) * 40; r = f * 90; pl.mood('shock'); pl.pose(-60, 40, -160, -160) }
    else { const f = 1 - Math.pow(1 - seg(t, KT + 0.3, 2.6), 2); x = lerp(320, 560, f); y = 262; r = 90; pl.mood('shock'); pl.pose(4, -4, -170, -170) }
    pl.at(x, y, r, k)
    splash(x + 30, 282, t > KT + 0.3 && t < 2.7 ? ((t - KT) % 0.32) / 0.32 : 0)
    splash2(300, 282, seg(t, KT + 0.25, KT + 0.9))
    // The ball stops where he left it; the defender comes in and takes it away.
    let bx = t < KT ? x + 14 : lerp(294, 300, seg(t, KT, KT + 0.4)), by = 284 - 0
    const dx = t < 1.9 ? lerp(-60, 260, seg(t, 1.2, 1.9)) : lerp(290, -60, seg(t, 2.4, 3.6))
    df.face?.('side', t < 2.4 ? 1 : -1); df.mood(t > 2.0 ? 'joy' : 'focus'); df.at(dx, 200, 0, k); df.run(t * 13, t > 1.2 ? 1 : 0)
    if (t > 2.4) bx = dx - 16
    b.set(bx, by, by, t < KT ? t * 900 : t > 2.4 ? t * 900 : 0)
    tt(seg(t, KT + 0.4, KT + 0.8))
  } }
}
