// [Sprint 57 W4] The sub scene (art.ts's SCENES.sub).
import { t as tr } from '../../../lib/i18n'
import { burst, referee } from '../effects'
import { player, title } from '../figures'
import { K, type SceneData, type SvgNode, ease, el, lerp, rnd, sa, seg } from '../kit'
import { cam, ref, stage } from '../stage'

// [Sprint 37 N2] The substitution: the fourth official holds up the lit board (off in red, on in green), the player
// coming off walks to the line and shakes hands with the one coming on, who runs onto the pitch.
// [Sprint 42 D4] The sub, as a cartoon: the board flashes green and red, the tired player trudges off with his head
// down, the substitute bounces on the spot, they slap a high five, and he leaps onto the pitch.
export function sub(e: SceneData) {
  const svg = stage(e.side),
    w = svg.world,
    k = K(e.side).kit,
    R = rnd(Number(e.inNo || 3) * 17 + Number(e.outNo || 5))
  const fo = referee(w, 1.4)
  const out = player(w, k, e.outNo, 1.4, { look: Math.floor(R() * 40) }),
    inn = player(w, k, e.inNo, 1.4, { look: Math.floor(R() * 40) })
  const led = (n: number | string | undefined, c: string) =>
    `<text y="-2" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="34" fill="${c}" style="letter-spacing:1px" filter="${ref(svg, 'glow')}">${n ?? ''}</text>`
  const board = el('g', {}, w)
  board.innerHTML = `<rect data-frame="1" x="-58" y="-34" width="116" height="52" rx="5" fill="#05080F" stroke="#3A4256" stroke-width="2"/><g data-o="1" transform="translate(-28 8)">${led(e.outNo, '#FF4D4D')}</g><g data-i="1" transform="translate(28 8)">${led(e.inNo, '#3BFF8A')}</g><path d="M0 -26 V12" stroke="#1B2233" stroke-width="2"/><rect x="-6" y="18" width="12" height="24" rx="3" fill="#1B2233"/>`
  const frameB = board.querySelector<SvgNode>('[data-frame]')!,
    oN = board.querySelector<SvgNode>('[data-o]')!,
    iN = board.querySelector<SvgNode>('[data-i]')!
  const slap = burst(svg, w, '#FFD400', 10),
    sweat = el('path', { d: 'M0 -5 Q4 1 0 3 Q-4 1 0 -5 Z', fill: '#9AD4FF', opacity: 0 }, w)
  const tt = title(svg, tr('تبديل'), '#2BB673')
  return {
    dur: 5.0,
    svg,
    update(t: number) {
      cam(svg, 1.05, 320, 200)
      // The fourth official, the board up and flashing (out red, in green, its frame blinking both colours).
      const up = ease(seg(t, 0, 0.5)),
        blink = t < 2.4 ? Math.floor(t * 6) % 2 : 0
      fo.face?.('front')
      fo.mood('focus')
      fo.at(236, 186, 0, 1.4)
      fo.pose(3, -3, 150 * up, -150 * up)
      sa(board, 'transform', `translate(236 ${lerp(150, 92, up).toFixed(1)}) scale(${(0.8 + 0.2 * up).toFixed(2)})`)
      sa(frameB, 'stroke', t < 2.4 ? (blink ? '#3BFF8A' : '#FF4D4D') : '#3A4256')
      sa(frameB, 'stroke-width', t < 2.4 ? 3.5 : 2)
      sa(oN, 'opacity', t < 2.4 && blink ? 0.35 : 1)
      sa(iN, 'opacity', t < 2.4 && !blink ? 0.35 : 1)
      // Off: trudges over slowly, head down, a drop of sweat; on: bounces on the spot, can't wait.
      const meet = ease(seg(t, 0.3, 2.4)),
        five = seg(t, 2.4, 2.75)
      if (t < 2.75) {
        out.face?.('side', -1)
        out.mood('sad')
        out.at(lerp(660, 400, meet), 214 + Math.sin(t * 5) * 1.5, -4, 1.4)
        meet < 1 ? out.run(t * 4.5, 0.2) : out.pose(4, -4, 10, lerp(-10, -165, Math.sin(Math.PI * five)))
      } else {
        out.face?.('front')
        out.mood('sad')
        out.at(lerp(400, 90, ease(seg(t, 2.75, 5.0))), lerp(214, 236, seg(t, 2.75, 5.0)), 0, 1.4)
        out.run(t * 4.5, 0.2)
        out.pose(4, -4, 14, -14)
      }
      sa(sweat, 'opacity', t < 2.4 ? 0.9 : 0)
      sa(sweat, 'transform', `translate(${(lerp(660, 400, meet) - 14).toFixed(1)} ${(170 + ((t * 30) % 14)).toFixed(1)})`)
      if (t < 2.75) {
        inn.face?.('side', 1)
        inn.mood(t > 2.3 ? 'joy' : 'focus')
        inn.at(356, 214 - Math.abs(Math.sin(t * 9)) * 9 * (1 - five), 0, 1.4)
        t < 2.4
          ? inn.pose(4, -4, 20 + Math.sin(t * 9) * 12, -20 - Math.sin(t * 9) * 12)
          : inn.pose(4, -4, 10, lerp(-10, -165, Math.sin(Math.PI * five)))
      } else {
        inn.face?.('back')
        const go = ease(seg(t, 2.75, 4.6))
        inn.mood('joy')
        inn.at(lerp(356, 540, go), lerp(214, 150, go) - Math.sin(Math.PI * seg(t, 2.75, 3.2)) * 40, 0, lerp(1.4, 0.9, go))
        inn.run(t * 14, 1)
      }
      // The high five: a slap and a burst where their hands meet.
      slap(378, 174, seg(t, 2.52, 2.85), 6)
      tt(seg(t, 0.4, 0.8))
    },
  }
}
