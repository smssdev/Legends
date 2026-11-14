// [Sprint 57 W4] The save scene (art.ts's SCENES.save).
import { t as tr } from '../../../lib/i18n'
import { boom, danger, flame, shakeIt, tint } from '../effects'
import { put, title } from '../figures'
import { type SceneData, bez, ease, el, lerp, sa, seg } from '../kit'
import { openPlay } from '../play'
import { LINE, persp, ref } from '../stage'

export function save(e: SceneData) {
  const KT = 2.9,
    { svg, go } = openPlay(e, 'save', KT),
    dg = danger(svg),
    fire = flame(svg),
    pow = boom(svg, svg.world, 'BOOM!')
  const double = e.drama === 'double',
    pow2 = double ? boom(svg, svg.world, 'BOOM!') : null,
    blue = double ? tint(svg, '#3B82F6') : null
  const ring = el('circle', { r: 26, fill: 'none', stroke: '#2BB673', 'stroke-width': 3, opacity: 0, filter: ref(svg, 'glow') }, svg.world)
  const tt = title(svg, double ? tr('تصدٍّ مزدوج!') : tr('تصدٍّ رائع'), '#2BB673')
  let last: number[] | null = null,
    land: number[] | null = null
  return {
    dur: 5.4,
    svg,
    update(t: number) {
      const r = go(t),
        { target } = r
      dg(t, r)
      // [Sprint 42 C3] The shot a fireball to the top corner; the keeper's fingertips go BOOM.
      const fly = t > r.tS && t < KT
      fire(r.ball[0], r.ball[1], last ? r.ball[0] - last[0] : 1, last ? r.ball[1] - last[1] : 0, fly)
      last = r.ball
      pow(target[0], target[1], seg(t, KT - 0.02, KT + 0.7))
      shakeIt(
        svg,
        4 * seg(t, KT, KT + 0.04) * (1 - seg(t, KT + 0.05, KT + 0.4)) +
          (double ? 4 * seg(t, KT + 1.35, KT + 1.38) * (1 - seg(t, KT + 1.4, KT + 1.7)) : 0),
        t,
      )
      const s = seg(t, KT - 0.02, KT + 0.6)
      sa(ring, 'transform', `translate(${target[0]} ${target[1]}) scale(${0.4 + s * 1.6})`)
      sa(ring, 'opacity', s > 0 ? 1 - s : 0)
      // [Sprint 42 F2] The double save: the rebound falls to a team-mate who hits it at once; the keeper, still on the
      // ground, pushes off with one hand and flings himself across to block it with his foot.
      if (double) {
        const dx = Math.sign(target[0] - 320) || 1,
          reb = [target[0] + dx * 96, 196],
          aim = [320 - dx * 34, 128]
        if (t < KT + 0.9) land = r.glove ?? land
        const L = land ?? [target[0], LINE - 6]
        if (t > KT + 0.3) {
          const run = ease(seg(t, KT + 0.3, KT + 0.85))
          put(r.mate, lerp(reb[0] + dx * 40, reb[0] + dx * 10, run), reb[1] + 36)
          t > KT + 0.8 && t < KT + 1.1
            ? r.mate.kick(seg(t, KT + 0.8, KT + 1.05))
            : t > KT + 1.5
              ? r.mate.pose(3, -3, 150, -150)
              : r.mate.run(t * 13, 1 - run)
        }
        if (t > KT + 0.95) {
          const f = seg(t, KT + 0.95, KT + 1.35),
            up = Math.sin(Math.PI * Math.min(1, f * 1.1)),
            s0 = persp(LINE)
          const kx = lerp(L[0], aim[0] + dx * 10, ease(f)),
            ky = lerp(L[1] + 20 * s0, aim[1] + 30, ease(f)) - up * 26
          r.kp.at(kx, ky, -dx * (90 + 300 * ease(f)), s0)
          r.kp.pose(lerp(10, 80, f), -lerp(10, 110, f), 40 + 60 * (1 - f), -150)
          let p, gr
          if (t < KT + 1.35) {
            const g = seg(t, KT + 1.0, KT + 1.35)
            p = bez([reb, [lerp(reb[0], aim[0], 0.5), 150], aim], g)
            gr = lerp(reb[1], LINE, g)
          } else {
            const g = ease(seg(t, KT + 1.35, KT + 2.1))
            p = bez([aim, [aim[0] - dx * 60, 60], [aim[0] - dx * 190, 150]], g)
            gr = lerp(LINE, 150, g)
          }
          r.b.set(p[0], p[1], gr, t * 1800, 1 - seg(t, KT + 1.9, KT + 2.1))
          pow2!(aim[0], aim[1], seg(t, KT + 1.33, KT + 2.0))
          blue!(0.3 * seg(t, KT + 1.35, KT + 1.42) * (1 - seg(t, KT + 1.55, KT + 1.9)))
        }
      }
      tt(seg(t, double ? KT + 1.5 : KT + 0.3, double ? KT + 1.9 : KT + 0.7))
    },
  }
}
