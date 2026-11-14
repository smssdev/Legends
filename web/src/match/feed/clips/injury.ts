// [Sprint 57 W4] The injury scene (art.ts's SCENES.injury).
import { t as tr } from '../../../lib/i18n'
import { bubbleOf, dizzy, dust, speedLines } from '../effects'
import { player, title } from '../figures'
import { K, type SceneData, ease, el, inout, lerp, rnd, sa, seg } from '../kit'
import { cam, stage } from '../stage'

// [Sprint 37 N3] The injury: he lies down, a team-mate waves to the bench, the medical staff run on with the
// stretcher and carry him off (an injured player leaves the match, the engine's rule).
// [Sprint 42 D3] As a cartoon: stars and little birds circle his head, and the two medics come on and go off at a
// comic sprint, legs a blur, with speed lines and a trail of dust.
export function injury(e: SceneData) {
  const svg = stage(e.side),
    w = svg.world,
    R = rnd(Number(e.no || 4) * 29)
  const pl = player(w, K(e.side).kit, e.no, 1.3, { look: Math.floor(R() * 40) }),
    mate = player(w, K(e.side).kit, '', 1.3, { look: Math.floor(R() * 40) })
  const medic = () => player(w, '#1FA463', '+', 1.25, { look: Math.floor(R() * 40), shorts: '#F4F6FA', socks: '#1FA463', trim: '#F4F6FA' })
  const m1 = medic(),
    m2 = medic()
  const bed = el('g', {}, w)
  bed.innerHTML =
    '<rect x="-64" y="-5" width="128" height="10" rx="3" fill="#E9EEF6" stroke="#8A97AD" stroke-width="1"/><path d="M-80 0 H80" stroke="#5A667C" stroke-width="3" stroke-linecap="round"/><path d="M-6 -2 H6 M0 -8 V4" stroke="#EF4444" stroke-width="2.4"/>'
  sa(bed, 'transform', 'translate(-200 0)')
  const stars = dizzy(svg),
    lines = speedLines(svg, w, 7),
    trailD = dust(svg, w, 6),
    ouch = bubbleOf(svg, w, '!!!')
  const tt = title(svg, tr('إصابة'), '#EF4444')
  return {
    dur: 5.6,
    svg,
    update(t: number) {
      cam(svg, 1.06, 320, 210)
      // The stretcher: in at a sprint (1.0 to 1.5), down by him, loaded, then off to the right even faster (3.0 on).
      const inn = ease(seg(t, 1.0, 1.5)),
        off = inout(seg(t, 3.0, 3.6)),
        lift = seg(t, 1.9, 2.5)
      const sx = t < 3.0 ? lerp(-140, 300, inn) : lerp(300, 820, off),
        sy = lerp(lerp(214, 230, seg(t, 1.5, 1.8)), 232, lift)
      sa(bed, 'transform', `translate(${sx.toFixed(1)} ${sy.toFixed(1)})`)
      const sprint = (t > 0.95 && t < 1.5) || (t > 3.0 && t < 3.6),
        carrying = t < 1.5 || t > 3.0
      for (const [m, dx] of [
        [m1, -86],
        [m2, 86],
      ] as const) {
        m.face?.('side', 1)
        m.mood(sprint ? 'focus' : 'idle')
        m.at(sx + dx, sy - 24 + (carrying ? 0 : 6) - (sprint ? Math.abs(Math.sin(t * 30)) * 3 : 0), sprint ? 8 : 0, 1.25)
        carrying ? m.run(t * (sprint ? 34 : 9) + dx, sprint ? 1 : 0.45) : m.pose(30, -30, 40, -40, 0.4, 0.4)
      }
      lines(sx - 40, sy - 20, 1, 0, sprint ? 1 : 0, t)
      trailD(sx - 110, 282, sprint ? ((t - 0.95) % 0.3) / 0.3 : 0)
      // He lies by the stretcher, dazed (stars round his head), then is on it.
      if (t < 1.9) {
        pl.face?.('front')
        pl.mood('sad')
        pl.at(300 + Math.sin(t * 3) * 2, 262, 82, 1.3)
        pl.pose(14, -6, 60 + Math.sin(t * 6) * 10, -20)
      } else {
        pl.face?.('side', 1)
        pl.mood('sad')
        pl.at(lerp(300, sx, lift), lerp(262, sy - 12, lift), 90, 1.15)
        pl.pose(4, -4, 40, -10)
      }
      const hx = t < 1.9 ? 327 : sx + 24,
        hy = t < 1.9 ? 246 : sy - 22
      stars(hx, hy, t, t > 0.15 && t < 3.3)
      ouch(hx + 26, hy - 24, seg(t, 0.2, 0.35) * (1 - seg(t, 0.95, 1.1)), 0.8, Math.sin(t * 40) * 1.5)
      // The team-mate waves to the bench, then stands, hands on hips.
      mate.face?.('front')
      mate.mood('sad')
      mate.at(420, 196, 0, 1.3)
      if (t < 1.3) {
        const wv = Math.sin(t * 12) * 24
        mate.pose(3, -3, 150 + wv, -150 - wv)
      } else if (t > 3.0 && t < 3.6) {
        mate.mood('shock')
        mate.pose(3, -3, 40, -40)
      } else mate.despair()
      tt(seg(t, 0.2, 0.6))
    },
  }
}
