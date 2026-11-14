// [Sprint 57 W4] The offside scene (art.ts's SCENES.offside).
import { t as tr } from '../../../lib/i18n'
import { ball, player, put, title } from '../figures'
import { K, type SceneData, ease, el, lerp, officialKit, other, rnd, sa, seg } from '../kit'
import { cam, persp, stage } from '../stage'

// [Sprint 38 S1] Offside, as on TV: the pass is played, the attacker is a step beyond the last defender, the assistant
// on the touchline raises his flag, and the picture freezes with the line drawn across the defence.
export function offside(e: SceneData) {
  const svg = stage(e.side),
    w = svg.world,
    R = rnd(Number(e.no || 7) * 37)
  const defs = [0, 1, 2, 3].map(() => player(w, K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }))
  const rn = player(w, K(e.side).kit, e.no, 1, { look: Math.floor(R() * 40) }),
    ps = player(w, K(e.side).kit, '', 1, { look: Math.floor(R() * 40) })
  const ar = player(w, officialKit(), '', 1, { look: 20, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
  const fl = el('g', {}, w)
  fl.innerHTML =
    '<rect x="-0.8" y="0" width="1.6" height="18" fill="#2B2B2B"/><path d="M0.8 0 H13 V9 H0.8 Z" fill="#F2E205"/><path d="M0.8 0 H6.9 V4.5 H0.8 Z M6.9 4.5 H13 V9 H6.9 Z" fill="#D3122F"/>'
  const b = ball(svg),
    lineY = 206,
    runTo = [352, 190]
  // A horizontal line has no height, so a filter would draw nothing: the glow is a wider faint line under it.
  const line = el('g', { opacity: 0 }, w)
  el('line', { x1: -40, y1: lineY, x2: 680, y2: lineY, stroke: 'rgba(239,68,68,.35)', 'stroke-width': 7 }, line)
  el('line', { x1: -40, y1: lineY, x2: 680, y2: lineY, stroke: '#EF4444', 'stroke-width': 2.4, 'stroke-dasharray': '10 7' }, line)
  const fr = el('rect', { width: 640, height: 340, fill: 'rgba(30,70,160,.18)', opacity: 0 }, svg)
  const tt = title(svg, tr('تسلل'), '#EF4444')
  return {
    dur: 4.2,
    svg,
    update(t: number) {
      // The picture freezes at the pass's arrival (1.5 s) until 2.6 s.
      const T = t > 1.5 && t < 2.6 ? 1.5 : t < 2.6 ? t : t - 1.1
      cam(svg, 1.08, 340, 200)
      defs.forEach((d, i) => {
        put(d, 170 + i * 90 + Math.sin(T * 2 + i) * 4, lineY + (i % 2) * 3)
        T < 1.3 ? d.run(T * 8 + i, 0.3) : d.pose(4, -4, i === 1 ? 140 : 10, i === 2 ? -140 : -10)
      })
      const go = ease(seg(T, 0, 1.4))
      put(rn, lerp(330, runTo[0], go), lerp(262, runTo[1], go))
      rn.run(T * 12, go < 1 ? 0.8 : 0.2)
      put(ps, 250, 286)
      T < 0.75 && T > 0.45 ? ps.kick(seg(T, 0.45, 0.75)) : ps.pose()
      // The assistant level with the last defender on the far touchline: the flag goes up as the ball arrives.
      const up = ease(seg(T, 1.2, 1.45))
      put(ar, 572, lineY)
      ar.face?.('front')
      ar.mood('focus')
      ar.pose(3, -3, 10, -10 - 160 * up)
      const s2 = persp(lineY)
      sa(fl, 'transform', `translate(${572 + 15 * s2 * up} ${lineY - 58 * s2 - lerp(-30, 52, up) * s2}) scale(${s2})`)
      const k = ease(seg(T, 0.7, 1.5)),
        p = [lerp(256, runTo[0] - 6, k), lerp(282, runTo[1] + 3, k)]
      b.set(p[0], p[1] - 30 * Math.sin(Math.PI * k) * 0.6, p[1], T * 900, 1)
      sa(line, 'opacity', seg(t, 1.5, 1.7) * (1 - seg(t, 2.6, 2.9)))
      sa(fr, 'opacity', t > 1.5 && t < 2.6 ? 1 : 0)
      tt(seg(t, 1.6, 2.0))
    },
  }
}
