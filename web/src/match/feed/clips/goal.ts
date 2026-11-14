// [Sprint 57 W4] The goal scene (art.ts's SCENES.goal).
import { t as tr } from '../../../lib/i18n'
import { confetti, danger, flame, shakeIt } from '../effects'
import { bigNumber, flash, flashes, title } from '../figures'
import { K, type SceneData, type SvgNode, el, sa, seg } from '../kit'
import { openPlay } from '../play'

export function goal(e: SceneData) {
  const KT = 3.0, { svg, go } = openPlay(e, 'goal', KT), dg = danger(svg), cf2 = confetti(svg)
  const bike = e.drama === 'bicycle' && e.quality === 'header', dark = e.drama === 'blackout'
  // [Sprint 42 F5] The bicycle kick in slow motion: the build-up quicker, the flip and the strike slower, the ball in
  // at the same instant (KT), with a trail of fire and black bars as at the cinema.
  const warp = (t: number) => { if (!bike || t <= 0.4 || t >= KT) return t; const s = (t - 0.4) / (KT - 0.4); return 0.4 + (KT - 0.4) * (s < 0.5 ? s * 1.3 : 0.65 + (s - 0.5) * 0.7) }
  const fire = bike ? flame(svg) : null, bars = bike ? el('g', { opacity: 0 }, svg) : null
  if (bars) bars.innerHTML = '<rect width="640" height="38" fill="#000"/><rect y="302" width="640" height="38" fill="#000"/>'
  // [Sprint 42 F9] The blackout: the lights go just before the shot, only eyes in the dark, a click, and the lights
  // come back with the ball in the net.
  const black = dark ? el('g', { opacity: 0 }, svg) : null
  if (black!) black!.innerHTML = '<rect width="640" height="340" fill="#02030A"/>' + [[320, 120], [250, 210], [400, 200], [180, 250], [470, 260], [330, 230]].map(([x, y], i) => `<g data-eyes="${i}" transform="translate(${x} ${y})"><ellipse cx="-6" rx="4.5" ry="5.5" fill="#fff"/><ellipse cx="6" rx="4.5" ry="5.5" fill="#fff"/><circle data-p="1" cx="-6" r="2" fill="#000"/><circle data-p="1" cx="6" r="2" fill="#000"/></g>`).join('') + '<text data-click="1" x="320" y="70" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="34" fill="#FFD400" opacity="0">*CLICK*</text>'
  const pupils = black ? [...black.querySelectorAll<SvgNode>('[data-p]')] : [], click = (black ? black.querySelector<SvgNode>('[data-click]') : null)!
  const num = bigNumber(svg, e.no, K(e.side).kit), fl = flash(svg), cf = flashes(svg), tt = title(svg, tr('هدف!'))
  let last: number[] | null = null
  return { dur: 6.0, svg, update(t: number) {
    const u = warp(t), r = go(u); dg(u, r); num(seg(t, KT + 0.6, KT + 1.4)); cf(t, t > KT)
    fl(seg(t, KT - 0.01, KT + 0.05) * (1 - seg(t, KT + 0.05, KT + 0.25)) * 0.16)
    // [Sprint 42 C2] The net stretches, the screen shakes, and the confetti rains on the celebration.
    shakeIt(svg, 7 * seg(t, KT, KT + 0.04) * (1 - seg(t, KT + 0.05, KT + 0.6)), t)
    cf2(t - KT - 0.3)
    if (bike) {
      sa(bars!, 'opacity', seg(t, 1.6, 1.9) * (1 - seg(t, KT + 0.2, KT + 0.5)))
      fire!(r.ball[0], r.ball[1], last ? r.ball[0] - last[0] : 1, last ? r.ball[1] - last[1] : 0, u > r.tS && u < KT)
      last = r.ball
    }
    if (dark) {
      const off = seg(t, r.tS - 0.25, r.tS - 0.15) * (1 - seg(t, KT + 0.6, KT + 1.0))
      sa(black!, 'opacity', off.toFixed(2))
      // The eyes blink and dart about in the dark.
      pupils.forEach((p, i) => sa(p, 'transform', `translate(${(Math.sin(t * 5 + i) * 2).toFixed(1)} 0)`))
      sa(click, 'opacity', seg(t, KT + 0.4, KT + 0.45) * (1 - seg(t, KT + 0.8, KT + 1.0)))
    }
    tt(seg(t, dark ? KT + 0.9 : KT + 0.2, dark ? KT + 1.3 : KT + 0.6))
  } }
}
