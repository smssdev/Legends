// [Sprint 57 W4] The freekick scene (art.ts's SCENES.freekick).
import { t as tr } from '../../../lib/i18n'
import { ball, dive, drawTrail, flash, flashes, keeper, player, put, ready, title, trail } from '../figures'
import { K, type SceneData, bez, clamp, ease, el, inout, lerp, officialKit, other, rnd, sa, seg } from '../kit'
import { LINE, POSTS, cam, goalFrame, stage } from '../stage'

export function freekick(e: SceneData) {
  const R = rnd(e.v ?? Number(e.no ?? 9) * 53),
    svg = stage(e.side),
    w = svg.world,
    G = goalFrame(svg)
  const kp = keeper(svg, other(e.side), Math.floor(R() * 40))
  const wall = [0, 1, 2, 3].map(() => player(w, K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }))
  const tk = player(w, K(e.side).kit, e.no, 1, { look: Math.floor(R() * 40) }),
    b = ball(svg),
    trl = trail(svg)
  const fl = flash(svg),
    cf = flashes(svg)
  // [Sprint 38 S3] The referee marks the wall's line with his spray, then steps away.
  const rf = player(w, officialKit(), '', 1, { look: 9, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
  const foam = el('path', { fill: 'none', stroke: '#F7F9FC', 'stroke-width': 2.6, 'stroke-linecap': 'round', opacity: 0.85 }, w)
  const KT = 2.65,
    tS = 1.85,
    side = R() < 0.5 ? -1 : 1,
    spot = [320 - side * 50, 252],
    scared = rnd((e.v ?? 5) * 11 + 4)() < 0.5
  const target = e.scored
    ? [side > 0 ? POSTS[1] - 12 : POSTS[0] + 12, 84 + R() * 8]
    : e.saved
      ? [320 + side * (44 + R() * 14), 92 + R() * 14]
      : [320 + side * 20, 50]
  const path = [spot, [lerp(spot[0], target[0], 0.4) - side * 30, 30], target]
  const tt = title(
    svg,
    e.scored ? tr('هدف!') : e.saved ? tr('تصدٍّ!') : tr('فوق العارضة'),
    e.scored ? undefined : e.saved ? '#2BB673' : '#C9D2E1',
  )
  return {
    dur: 5.2,
    svg,
    update(t: number) {
      cam(svg, 1.06 + 0.1 * inout(seg(t, 0.2, tS)), 320, 165)
      // The wall, nine metres off, jumps as the kick is taken.
      const jump = 14 * Math.sin(Math.PI * seg(t, tS - 0.05, tS + 0.45))
      const sp = seg(t, 0, 0.55),
        x0 = spot[0] + side * 20 - 34,
        x1 = spot[0] + side * 20 + 34
      sa(foam, 'd', `M${x0} 224 L${lerp(x0, x1, sp)} 224`)
      sa(foam, 'opacity', 0.85 * (1 - seg(t, 4.2, 5)))
      put(
        rf,
        t < 0.6 ? lerp(x0, x1, sp) : lerp(x1, spot[0] + side * 140, ease(seg(t, 0.6, 1.4))),
        t < 0.6 ? 228 : lerp(228, 240, ease(seg(t, 0.6, 1.4))),
      )
      t < 0.6 ? rf.pose(8, -8, 10, -60) : t < 1.4 ? rf.run(t * 9, 0.5) : rf.pose()
      rf.mood('focus')
      // [Sprint 42 H2] One wall in two loses its nerve: hands over their faces, and one of them ducks out of it.
      wall.forEach((p, i) => {
        const duck = scared && i === 2 ? -16 * seg(t, tS - 0.35, tS - 0.1) * (1 - seg(t, KT + 0.6, KT + 1.2)) : 0
        put(p, spot[0] + side * 20 + (i - 1.5) * 15, 218, scared && i === 2 ? side * 20 * seg(t, tS - 0.35, tS - 0.1) : 0, 1, jump + duck)
        scared && t > tS - 0.5 && t < KT + 0.8
          ? p.pose(4, -4, 150, -150, jump > 1 ? 0.5 : 0, jump > 1 ? 0.5 : 0)
          : p.pose(4, -4, 4, -4, jump > 1 ? 0.5 : 0, jump > 1 ? 0.5 : 0)
      })
      const f = inout(seg(t, 0.6, tS))
      put(tk, lerp(spot[0] - side * 30, spot[0] - side * 5, f), lerp(spot[1] + 30, spot[1] + 6, f))
      if (t < 0.6) tk.pose(3, -3, 20, -20)
      else if (t < tS - 0.3) tk.run(t * 11, 0.7)
      else tk.kick(seg(t, tS - 0.3, tS + 0.12))
      if (t > KT + 0.6 && e.scored) tk.celebrate(t)
      if (t < tS + 0.12) ready(kp, 320 - side * 14, LINE + 2, t)
      else
        dive(
          kp,
          320 - side * 14,
          LINE + 2,
          e.scored ? lerp(320, target[0], 0.75) : e.saved ? target[0] : lerp(320, target[0], 0.4),
          e.scored ? target[1] + 8 : Math.max(86, target[1]),
          seg(t, tS + 0.12, KT),
          seg(t, KT + 0.2, KT + 0.9),
        )
      let p, gr
      if (t < tS) {
        p = spot
        gr = spot[1]
      } else if (t < KT) {
        const g = seg(t, tS, KT)
        p = bez(path, g)
        gr = lerp(spot[1], LINE + 2, g)
        drawTrail(trl, path, g, 0.6)
      } else if (e.scored) {
        const a = t - KT,
          d = clamp((a - 0.15) / 0.5)
        p = [target[0], lerp(target[1] - 8 * ease(clamp(a / 0.15)), 146, d * d)]
        gr = LINE - 8
        sa(trl, 'opacity', 0)
      } else if (e.saved) {
        const a = ease(clamp((t - KT) / 0.8))
        p = bez([target, [target[0] + side * 40, target[1] - 20], [target[0] + side * 120, 190]], a)
        gr = lerp(LINE, 190, a)
        sa(trl, 'opacity', 0)
      } else {
        const a = clamp((t - KT) / 0.7)
        p = [target[0] + side * 12 * a, target[1] - 28 * a]
        gr = LINE - 20 * a
        sa(trl, 'opacity', 0)
      }
      b.set(p[0], p[1], gr, t > tS ? t * 1600 : 0, !e.scored && !e.saved ? 1 - seg(t, KT + 0.3, KT + 0.7) : 1)
      if (e.scored) {
        G.bulge(target[0], target[1] - 8, seg(t, KT, KT + 0.1) * (1 - seg(t, KT + 0.25, KT + 1.2)))
        fl(seg(t, KT - 0.01, KT + 0.05) * (1 - seg(t, KT + 0.05, KT + 0.25)) * 0.16)
        cf(t, t > KT)
      }
      tt(seg(t, KT + 0.2, KT + 0.6))
    },
  }
}
