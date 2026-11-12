// @ts-nocheck
// [Sprint 57 W4] The corner scene (art.ts's SCENES.corner).
import { t as tr } from '../../../lib/i18n'
import { ball, dive, drawTrail, keeper, player, put, ready, title, trail } from '../figures'
import { K, bez, ease, el, lerp, other, rnd, sa, seg } from '../kit'
import { LINE, cam, goalFrame, stage } from '../stage'

// [Sprint 37 N1] The corner, one of three when it is won (from the scene's seed): a header at the far post, a flick at
// the near one, or played short to a team-mate who crosses; the taker stands at the flag. A claimed one: the keeper.
export function corner(e) {
  const R = rnd(e.v ?? (e.no ?? 9) * 71), svg = stage(e.side), w = svg.world, G = goalFrame(svg)
  const kp = keeper(svg, other(e.side), Math.floor(R() * 40))
  const pack = [0, 1, 2].map((i) => player(w, i % 2 ? K(e.side).kit : K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }))
  const df = player(w, K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }), hd = player(w, K(e.side).kit, e.no, 1, { look: Math.floor(R() * 40) })
  const tk = player(w, K(e.side).kit, '', 1, { look: Math.floor(R() * 40) }), sh2 = player(w, K(e.side).kit, '', 1, { look: Math.floor(R() * 40) })
  const pick = R(), style = e.claim ? (pick < 0.4 ? 'short' : 'far') : pick < 0.4 ? 'far' : pick < 0.7 ? 'near' : 'short'
  const b = ball(svg), trl = trail(svg)
  el('path', { d: 'M598 214 V184', stroke: '#DDE3F0', 'stroke-width': 2 }, w); el('path', { d: 'M599 184 L614 189 L599 194 Z', fill: '#F5B82E' }, w)
  const flag = [596, 214], lay = [548, 232], short = style === 'short', from = short ? lay : flag
  // The cross starts later when it is played short first; the near-post flick meets it before the six-yard line.
  const t0 = short ? 1.0 : 0.6, dt = t0 - 0.6, head = style === 'near' ? [284, 192] : [326, 186]
  const path = [from, [style === 'near' ? 420 : 470, style === 'near' ? 50 : 20], [head[0], head[1] - 44]]
  const tt = title(svg, e.claim ? tr('الحارس يمسكها') : tr('رأسية!'), e.claim ? '#2BB673' : '#C9D2E1')
  return { dur: 4.6, svg, update(t) {
    cam(svg, 1.06, 400, 170)
    // The taker at the flag, and the team-mate who comes short for it.
    put(tk, 606, 218); if (t < 0.62 && t > 0.3) tk.kick(seg(t, 0.3, 0.62)); else tk.pose()
    if (short) { put(sh2, lerp(520, lay[0] + 6, ease(seg(t, 0, 0.6))), lay[1] + 2); t > 0.75 && t < t0 + 0.1 ? sh2.kick(seg(t, 0.75, t0 + 0.08)) : t < 0.6 ? sh2.run(t * 12, 0.6) : sh2.pose() }
    else put(sh2, 470, 236), sh2.idle(t * 3)
    const f = seg(t, t0, t0 + 1.1), jump = 24 * Math.sin(Math.PI * seg(t, 1.35 + dt, 2.05 + dt))
    put(hd, lerp(style === 'near' ? 330 : 346, head[0], ease(seg(t, 0, 1.4 + dt))), head[1], 0, 1, jump); jump > 1 ? hd.pose(10, -10, 70, -70, 0.4, 0.4) : hd.run(t * 12, 0.6)
    put(df, lerp(310, head[0] + 16, ease(seg(t, 0, 1.4 + dt))), head[1] - 4, 0, 1, jump * 0.6); jump > 1 ? df.pose(8, -8, 60, -60, 0.3, 0.3) : df.run(t * 11, 0.5)
    pack.forEach((p, i) => { put(p, 290 + i * 40 + Math.sin(t * 3 + i) * 6, 200 + (i % 2) * 12); p.run(t * 10 + i, 0.4) })
    let glove = null
    if (e.claim) { const c = seg(t, 1.2 + dt, 1.7 + dt); glove = dive(kp, 320, LINE + 2, lerp(320, head[0] + 4, 0.8), lerp(120, 96, c), c, 0) }
    else ready(kp, style === 'near' ? 300 : 322, LINE + 2, t)
    let p, gr
    if (t < 0.6) { p = flag; gr = flag[1] }
    else if (short && t < t0) { const g = ease(seg(t, 0.6, 0.85)); p = [lerp(flag[0], lay[0], g), lerp(flag[1], lay[1], g)]; gr = p[1] }
    else if (t < t0 + 1.1) { const g = ease(f); p = bez(path, g); gr = lerp(from[1], head[1], g); drawTrail(trl, path, g, 0.5) }
    else if (e.claim) { p = glove ?? [head[0], 100]; gr = LINE + 2; sa(trl, 'opacity', 0) }
    else { const g = ease(seg(t, t0 + 1.1, t0 + 1.8)), off = style === 'near' ? 30 : -10; p = bez([[head[0], head[1] - 44], [head[0] + off * 0.6, 60], [head[0] + off, 40]], g); gr = lerp(head[1], LINE - 10, g); sa(trl, 'opacity', 0) }
    b.set(p[0], p[1], gr, t * 1200, e.claim ? 1 : 1 - seg(t, 2.2 + dt, 2.5 + dt))
    tt(seg(t, 2.2 + dt, 2.6 + dt))
  } }
}
