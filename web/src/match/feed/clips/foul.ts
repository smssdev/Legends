// [Sprint 57 W4] The foul scene (art.ts's SCENES.foul).
import { t as tr } from '../../../lib/i18n'
import { bubbleOf, burst, dust, headOf, referee, tackle } from '../effects'
import { player, title } from '../figures'
import { K, type SceneData, ease, el, lerp, other, rnd, sa, seg } from '../kit'
import { cam, stage } from '../stage'

// [Sprint 42 D2] A foul as its own scene (tick.moment.drama). tackle: the slide, the flip, the dust, the agony, the
// referee's whistle and his arm out for the free kick. dive: he runs past the defender untouched, takes off like a
// diver, rolls five times screaming, opens one eye to see, and the referee gives it all the same.
export function foul(e: SceneData) {
  const svg = stage(e.side),
    w = svg.world,
    R = rnd(e.v ?? Number(e.no ?? 5) * 41),
    k = 1.4,
    dive = e.drama === 'dive'
  const vi = player(w, K(other(e.side)).kit, e.victimNo ?? '', k, { look: Math.floor(R() * 40) })
  const pl = player(w, K(e.side).kit, e.no, k, { look: Math.floor(R() * 40) }),
    rf = referee(w, k)
  const fx = { dust: dust(svg), slide: dust(svg, w, 5), ouch: bubbleOf(svg, w, '!!!') }
  const scream = bubbleOf(svg, w, 'AAAAH!'),
    huh = bubbleOf(svg, w, '?!', '#0A1F42'),
    blow = burst(svg, w),
    roll = dust(svg, w, 6)
  const q = el(
    'text',
    {
      'font-family': 'Barlow Condensed, sans-serif',
      'font-weight': 800,
      'font-size': 18,
      fill: '#FFD400',
      stroke: '#040B1C',
      'stroke-width': 3,
      'paint-order': 'stroke',
      opacity: 0,
    },
    w,
  )
  q.textContent = '?'
  const tt = title(svg, dive ? tr('سقوط مثير!') : tr('خطأ'), '#F2994A')
  return {
    dur: 5.2,
    svg,
    update(t: number) {
      roll(0, 0, 0)
      let zoom = 0,
        zx = 320,
        zy = 205
      if (!dive) {
        tackle(svg, t, 1.5, pl, vi, k, fx)
        if (t > 2.4) {
          pl.mood('sad')
          pl.pose(3, -3, 60, -60)
        }
      } else {
        // The defender stands his ground (a half-hearted leg out), then throws his arms up: never touched him!
        pl.face?.(t < 1.9 ? 'side' : 'front', -1)
        pl.mood(t < 1.9 ? 'focus' : 'angry')
        pl.at(236, 176, 0, k)
        t < 1.9
          ? pl.pose(3, -3 - 18 * Math.sin(Math.PI * seg(t, 1.1, 1.6)), 14, -14)
          : pl.pose(3, -3, 160 + Math.sin(t * 10) * 8, -160 - Math.sin(t * 10) * 8)
        huh(236, 108, seg(t, 4.15, 4.3), 0.8)
        if (t < 1.25) {
          vi.face?.('side', 1)
          vi.mood('focus')
          vi.at(lerp(90, 310, seg(t, 0.1, 1.25)), 222, 0, k)
          vi.run(t * 14, 1)
        } else if (t < 1.6) {
          const f = seg(t, 1.25, 1.6)
          vi.face?.('side', 1)
          vi.mood('joy')
          vi.at(lerp(310, 380, f), lerp(222, 266, f) - Math.sin(Math.PI * f) * 56, f * 80, k)
          vi.pose(10, -10, -165, -165)
        } else if (t < 2.9) {
          const f = seg(t, 1.6, 2.9)
          vi.face?.('side', 1)
          vi.mood('shock')
          vi.at(lerp(380, 540, f), 266, 80 + f * 1800, k)
          vi.pose(30, -30, 90, -90, 0.4, 0.4)
          roll(lerp(380, 540, f) - 20, 283, ((t - 1.6) % 0.26) / 0.26)
        } else if (t < 4.5) {
          vi.face?.('front')
          vi.mood(t > 3.2 ? 'peek' : 'sad')
          vi.at(540, 268, 90, k)
          vi.pose(10, -10, 40, -40)
        } else {
          const f = ease(seg(t, 4.5, 4.75))
          vi.face?.('front')
          vi.mood('joy')
          vi.at(540, lerp(268, 200, f), lerp(90, 0, f), k)
          vi.pose(4, -4, lerp(40, 130, f), -lerp(40, 130, f))
        }
        scream(lerp(400, 560, seg(t, 1.6, 2.9)), 210, seg(t, 1.6, 1.75) * (1 - seg(t, 2.85, 3.0)), 0.9, Math.sin(t * 45) * 2)
        // The close-up on his face: one eye opens to see what the referee does.
        zoom = ease(seg(t, 2.95, 3.25)) * (1 - ease(seg(t, 3.95, 4.25)))
        zx = 570
        zy = 262
        sa(q, 'opacity', seg(t, 3.35, 3.45) * (1 - seg(t, 3.9, 4.0)))
        sa(q, 'x', 586)
        sa(q, 'y', 252 - ((t * 10) % 4))
      }
      cam(svg, lerp(1.06, 2.6, zoom), lerp(320, zx, zoom), lerp(205, zy, zoom))
      // The referee: in from behind, the whistle, the arm out for the free kick.
      const tIn = dive ? [3.4, 4.0] : [2.2, 2.9],
        rIn = ease(seg(t, tIn[0], tIn[1])),
        rx = dive ? lerp(-40, 130, rIn) : lerp(700, 560, rIn)
      if (t < tIn[1]) {
        rf.face?.('side', dive ? 1 : -1)
        rf.run(t * 15, 1)
      } else {
        rf.face?.('front')
        rf.mood('focus')
        rf.pose(3, -3, t > tIn[1] + 0.3 ? (dive ? 12 : 92) : 12, t > tIn[1] + 0.3 && dive ? -92 : t < tIn[1] + 0.3 ? -150 : -12)
      }
      rf.at(rx, dive ? 190 : 196, 0, k)
      const [hx, hy] = headOf(rx, dive ? 190 : 196, k)
      blow(hx + 5, hy + 4, seg(t, tIn[1], tIn[1] + 0.45))
      tt(seg(t, dive ? 4.3 : 2.4, dive ? 4.7 : 2.8))
    },
  }
}
