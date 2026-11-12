// [Sprint 57 W4] The handshake scene (art.ts's SCENES.handshake).
import { t as tr } from '../../../lib/i18n'
import { player, title } from '../figures'
import { K, type SceneData, rnd, seg } from '../kit'
import { cam, stage } from '../stage'

// [Sprint 36 F5] Full time: the two teams pass each other in a line, shaking hands.
export function handshake(_e: SceneData) {
  const svg = stage('home'), w = svg.world, R = rnd(9)
  const a = [0, 1, 2, 3].map(() => player(w, K('home').kit, '', 1.3, { look: Math.floor(R() * 40) }))
  const b = [0, 1, 2, 3].map(() => player(w, K('away').kit, '', 1.3, { look: Math.floor(R() * 40) }))
  const tt = title(svg, tr('المصافحة'))
  return { dur: 3.0, svg, update(t: number) {
    cam(svg, 1.1, 320, 200)
    a.forEach((p, i) => { const x = 60 + i * 80 + t * 70; p.face?.('side', 1); p.at(x, 196, 0, 1.3); const near = b.some((_, j) => Math.abs(x - (580 - j * 80 - t * 70)) < 40); near ? p.pose(3, -3, 10, -80) : p.run(t * 6 + i, 0.2) })
    b.forEach((p, i) => { const x = 580 - i * 80 - t * 70; p.face?.('side', -1); p.at(x, 214, 0, 1.3); const near = a.some((_, j) => Math.abs(x - (60 + j * 80 + t * 70)) < 40); near ? p.pose(3, -3, 10, -80) : p.run(t * 6 + i, 0.2) })
    tt(seg(t, 0.2, 0.6))
  } }
}
