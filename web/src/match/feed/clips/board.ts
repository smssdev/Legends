// [Sprint 57 W4] The board scene (art.ts's SCENES.board).
import { t as tr } from '../../../lib/i18n'
import { player, title } from '../figures'
import { type SceneData, ease, el, esc, lerp, officialKit, sa, seg } from '../kit'
import { cam, ref, stage } from '../stage'

// [Sprint 38 S2] Stoppage time: the fourth official holds up the lit board with the minutes added.
export function board(e: SceneData) {
  const svg = stage('home'), w = svg.world
  const fo = player(w, officialKit(), '', 1.5, { look: 9, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
  const bd = el('g', {}, w)
  bd.innerHTML = `<rect x="-62" y="-40" width="124" height="64" rx="6" fill="#05080F" stroke="#3A4256" stroke-width="2"/><text y="12" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="46" fill="#3BFF8A" filter="${ref(svg, 'glow')}">+${esc(e.plus)}</text><rect x="-6" y="24" width="12" height="22" rx="3" fill="#1B2233"/>`
  const tt = title(svg, tr('الوقت بدل الضائع'), '#2BB673')
  return { dur: 3, svg, update(t: number) {
    cam(svg, 1.05, 320, 200)
    const up = ease(seg(t, 0.05, 0.5))
    fo.face?.('front'); fo.mood('focus'); fo.at(320, 196, 0, 1.5); fo.pose(3, -3, 150 * up, -150 * up)
    sa(bd, 'transform', `translate(320 ${lerp(170, 96, up)}) scale(${0.85 + 0.15 * up + 0.02 * Math.sin(t * 8)})`)
    tt(seg(t, 0.4, 0.8))
  } }
}
