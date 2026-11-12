// @ts-nocheck
// [Sprint 57 W4] The brawl scene (art.ts's SCENES.brawl).
import { t as tr } from '../../../lib/i18n'
import { player, title } from '../figures'
import { K, officialKit, other, rnd, seg } from '../kit'
import { cam, stage } from '../stage'

// [Sprint 35 C2] After a red card: players of both sides square up and push, the referee steps in between them.
export function brawl(e) {
  const svg = stage(e.side), w = svg.world, R = rnd(e.v ?? 11)
  const a = [0, 1, 2].map((i) => player(w, K(e.side).kit, '', 1.3, { look: Math.floor(R() * 40) }))
  const b = [0, 1, 2].map((i) => player(w, K(other(e.side)).kit, '', 1.3, { look: Math.floor(R() * 40) }))
  const rf = player(w, officialKit(), '', 1.35, { look: 9, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
  const tt = title(svg, tr('توتر في الملعب'), '#EF4444')
  return { dur: 2.8, svg, update(t) {
    cam(svg, 1.12 + 0.05 * Math.sin(t * 2), 320, 200)
    const shove = Math.sin(t * 9)
    a.forEach((p, i) => { p.face?.('side', 1); p.mood('angry'); p.at(250 + i * 18 + shove * (i === 1 ? 10 : 4), 200 + i * 14, shove * 6, 1.3); p.pose(10, -10, 80 + shove * 30, 70 - shove * 20) })
    b.forEach((p, i) => { p.face?.('side', -1); p.mood('angry'); p.at(390 - i * 18 - shove * (i === 1 ? 10 : 4), 204 + i * 12, -shove * 6, 1.3); p.pose(10, -10, 80 - shove * 30, 70 + shove * 20) })
    rf.face?.('front'); rf.at(320, 214, 0, 1.35); rf.pose(3, -3, 100 + Math.sin(t * 6) * 10, -100 - Math.sin(t * 6) * 10)
    tt(seg(t, 0.2, 0.6))
  } }
}
