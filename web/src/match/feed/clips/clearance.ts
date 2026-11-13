// [Sprint 57 W4] The clearance scene (art.ts's SCENES.clearance).
import { t as tr } from '../../../lib/i18n'
import { boom, dust, shakeIt, speedLines } from '../effects'
import { ball, dive, keeper, player, put, ready, title } from '../figures'
import { K, type SceneData, bez, ease, el, lerp, other, rnd, sa, seg } from '../kit'
import { LINE, cam, goalFrame, persp, stage } from '../stage'

// [Sprint 42 F1] Cleared off the line: the shot beats the diving keeper and rolls slowly towards the empty net; a
// defender comes from nowhere in a slide and a cloud of dust and kicks it off the line. A "!" over the striker,
// and the camera pulls back on his team-mates' despair.
export function clearance(e: SceneData) {
  const R = rnd(e.v ?? Number(e.no ?? 9) * 53), svg = stage(e.side), w = svg.world, atk = K(e.side).kit, dfk = K(other(e.side)).kit
  goalFrame(svg)
  const kp = keeper(svg, other(e.side), Math.floor(R() * 40))
  const mates = [0, 1].map(() => player(w, atk, '', 1, { look: Math.floor(R() * 40) }))
  const sh = player(w, atk, e.no, 1, { look: Math.floor(R() * 40) }), df = player(w, dfk, e.defNo ?? '', 1, { look: Math.floor(R() * 40) })
  const b = ball(svg), sl = speedLines(svg, w, 7), dst = dust(svg, w, 10), kick = boom(svg, w, 'WHACK!', '#E9EEF6', '#1E3A8A')
  const bang = el('text', { 'text-anchor': 'middle', 'font-family': 'Barlow Condensed, sans-serif', 'font-weight': 800, 'font-size': 34, fill: '#FFD400', stroke: '#040B1C', 'stroke-width': 4, 'paint-order': 'stroke', opacity: 0 }, w); bang.textContent = '!'
  const tt = title(svg, tr('أنقذها من على الخط!'), '#7FB4FF')
  const KT = 2.4, dir = R() < 0.5 ? -1 : 1, from = [320 + dir * 30, 236], line = [320 - dir * 20, LINE + 4], away = [320 + dir * 230, 120]
  return { dur: 4.2, svg, update(t: number) {
    // The camera on the goal, then pulled back for the despair.
    const back = ease(seg(t, KT + 0.2, KT + 1.2)); cam(svg, lerp(1.22, 0.96, back), 320, lerp(170, 200, back))
    // The striker shoots past the keeper (0.5), then stands there, hands on his head.
    put(sh, from[0] + dir * 6, from[1] + 10)
    if (t < 0.35) sh.run(t * 12, 0.6); else if (t < 0.65) sh.kick(seg(t, 0.35, 0.6)); else if (t < KT) sh.pose(3, -3, 30, -30); else { sh.face?.('front'); sh.mood('shock'); sh.pose(3, -3, 150, -150) }
    const [hx, hy] = [from[0] + dir * 6, from[1] + 10 - 100 * persp(from[1] + 10)]
    sa(bang, 'opacity', seg(t, KT + 0.05, KT + 0.15)); sa(bang, 'x', hx); sa(bang, 'y', hy - Math.abs(Math.sin(t * 9)) * 4)
    // The keeper dives the wrong way and stays down.
    if (t < 0.55) ready(kp, 320, LINE + 2, t, 1.3); else dive(kp, 320, LINE + 2, 320 + dir * 70, 120, seg(t, 0.55, 0.95), seg(t, 1.0, 1.5))
    // The ball: a slow, slow roll towards the line, then kicked away.
    let p, gr
    if (t < 0.6) { p = [from[0] - dir * 4, from[1] + 2]; gr = p[1] }
    else if (t < KT) { const f = 1 - Math.pow(1 - seg(t, 0.6, KT), 1.6); p = [lerp(from[0], line[0], f), lerp(from[1], line[1], f)]; gr = p[1] }
    else { const f = ease(seg(t, KT, KT + 0.8)); p = bez([line, [lerp(line[0], away[0], 0.5), 60], away], f); gr = lerp(line[1], 200, f) }
    b.set(p[0], p[1], gr, t * (t < KT ? 300 : 2200), 1 - seg(t, KT + 0.7, KT + 0.85))
    // The defender: from nowhere, a slide at full speed along the line, dust everywhere.
    const s = seg(t, 1.75, KT), dx = lerp(320 - dir * 260, line[0] - dir * 4, ease(s))
    if (t < 1.75) sa(df.g, 'opacity', 0)
    else {
      sa(df.g, 'opacity', 1); put(df, dx, line[1] + 6, dir * 70, 1, -14 * persp(line[1])); df.pose(6, -6, -30, -120)
      sl(dx, line[1] - 12, dir, 0, s < 1 ? 1 : 1 - seg(t, KT, KT + 0.3), t)
    }
    dst(line[0] - dir * 6, line[1] + 10, seg(t, KT - 0.2, KT + 0.9))
    kick(line[0], line[1] - 14, seg(t, KT - 0.02, KT + 0.6))
    shakeIt(svg, 4 * seg(t, KT, KT + 0.03) * (1 - seg(t, KT + 0.05, KT + 0.4)), t)
    // His team-mates, seen as the camera pulls back: arms up, then heads in hands.
    mates.forEach((m, i) => { put(m, 320 + (i ? 120 : -130) * dir, 300 + i * 12); if (t < KT) m.run(t * 10, 0.5); else { m.face?.('front'); m.mood('sad'); m.pose(3, -3, 150, -150) } })
    tt(seg(t, KT + 0.3, KT + 0.7))
  } }
}
