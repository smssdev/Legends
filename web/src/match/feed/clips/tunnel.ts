// [Sprint 57 W4] The tunnel scene (art.ts's SCENES.tunnel).
import { t as tr } from '../../../lib/i18n'
import { player, title } from '../figures'
import { K, type SceneData, el, rnd, seg } from '../kit'
import { cam, stage } from '../stage'

// [Sprint 36 F5] Half time: both teams walk off towards the tunnel at the side, the camera following them.
export function tunnel(_e: SceneData) {
  const svg = stage('home'),
    w = svg.world,
    R = rnd(5)
  const walkers = [0, 1, 2, 3, 4, 5].map((i) => ({
    p: player(w, K(i % 2 ? 'away' : 'home').kit, '', 1.2, { look: Math.floor(R() * 40) }),
    x: 140 + i * 52,
    y: 200 + (i % 3) * 18,
    ph: i,
  }))
  el('rect', { x: 560, y: 120, width: 90, height: 120, rx: 6, fill: '#0B1626' }, w)
  el('rect', { x: 570, y: 130, width: 70, height: 110, fill: '#040B1C' }, w)
  const tt = title(svg, tr('إلى غرف الملابس'))
  return {
    dur: 2.8,
    svg,
    update(t: number) {
      cam(svg, 1.05, 380, 200)
      for (const q of walkers) {
        q.p.face?.('side', 1)
        q.p.at(q.x + t * 60, q.y, 0, 1.2)
        q.p.run(t * 7 + q.ph, 0.25)
      }
      tt(seg(t, 0.2, 0.6))
    },
  }
}
