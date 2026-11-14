// [Sprint 57 W4] The penalty scene (art.ts's SCENES.penalty).
import { t as tr } from '../../../lib/i18n'
import { burst, referee, shakeIt } from '../effects'
import { ball, dive, drawTrail, flash, flashes, keeper, player, put, ready, title, trail } from '../figures'
import { K, SMOOTH, type SceneData, bez, clamp, ease, el, inout, keeperKit, lerp, other, rnd, sa, seg } from '../kit'
import { LINE, cam, goalFrame, persp, ref, stage } from '../stage'

export function penalty(e: SceneData) {
  const R = rnd(e.v ?? Number(e.no ?? 9) * 31),
    svg = stage(e.side),
    w = svg.world,
    G = goalFrame(svg)
  const kp = keeper(svg, other(e.side), Math.floor(R() * 40)),
    tk = player(w, K(e.side).kit, e.no, 1, { look: Math.floor(R() * 40) }),
    b = ball(svg),
    trl = trail(svg)
  const hush = el(
    'text',
    {
      x: 320,
      y: 30,
      'text-anchor': 'middle',
      'font-family': 'Tajawal, sans-serif',
      'font-weight': 600,
      'font-size': 15,
      fill: '#C9D2E1',
      opacity: 0,
    },
    svg,
  )
  hush.textContent = tr('صمت في المدرجات...')
  const tt = title(svg, e.scored ? tr('هدف!') : tr('تصدٍّ!'), e.scored ? undefined : '#2BB673'),
    fl = flash(svg),
    cf = flashes(svg)
  const KT = 2.85,
    tS = 2.45,
    dir = R() < 0.5 ? -1 : 1,
    wobbly = rnd((e.v ?? 5) * 3 + 2)() < 0.5
  // [Sprint 36 F2] The face-off before the kick, as on TV: the taker and the keeper in two panels, eye to eye.
  const vs = el('g', { opacity: 0 }, svg)
  vs.innerHTML =
    `<rect x="0" y="50" width="320" height="250" fill="${K(e.side).kit}" opacity=".9"/><rect x="320" y="50" width="320" height="250" fill="${keeperKit(other(e.side))}" opacity=".9"/>` +
    `<path d="M300 50 L340 50 L320 300 L280 300 Z" fill="#071733"/><text x="310" y="186" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-style="italic" font-weight="800" font-size="44" fill="#F5B82E">VS</text>`
  const fT = player(vs, K(e.side).kit, e.no, 2.2, { look: Math.floor(R() * 40) }),
    fK = player(vs, keeperKit(other(e.side)), 1, 2.2, { gloves: '#E4FF5A', look: Math.floor(R() * 40), shorts: '#111827' })
  fT.mood('focus')
  fK.mood('angry')
  const target = e.scored ? [320 + dir * (48 + R() * 12), R() < 0.5 ? 140 : 90] : [320 + dir * (30 + R() * 20), 110 + R() * 30]
  const kAim = e.scored ? (R() < 0.6 ? [640 - target[0], target[1]] : [lerp(320, target[0], 0.7), target[1] + 8]) : target
  const spot = [320, 207],
    path = [[spot[0], spot[1]], [lerp(spot[0], target[0], 0.5), Math.min(spot[1], target[1]) - 18], target]
  // [Sprint 42 C5] Before it all (1.2 s): the referee blows hard and points straight at the spot, which glows.
  const PRE = 1.2,
    rf = referee(w, 1),
    blow = burst(svg, w, '#FFFFFF'),
    spotRing = el(
      'ellipse',
      {
        cx: spot[0],
        cy: spot[1],
        rx: 10,
        ry: 3.5,
        fill: 'none',
        stroke: '#F5B82E',
        'stroke-width': 2,
        opacity: 0,
        filter: ref(svg, 'glow'),
      },
      w,
    )
  // ... and in the face-off, a close-up of their eyes, staring each other down.
  const eyes = el('g', { opacity: 0 }, vs)
  const eyePair = (cx: number, look: number, brow: string) =>
    `<g transform="translate(${cx} 176)">${[-38, 38].map((dx) => `<g transform="translate(${dx} 0)"><path d="M-30 0 Q0 -20 30 0 Q0 16 -30 0 Z" fill="#F7F3EA" stroke="#1A1A1A" stroke-width="2.5"/><circle data-iris="1" cx="${look}" cy="0" r="9" fill="#3B2414"/><circle cx="${look}" cy="0" r="4.2" fill="#0A0A0A"/><circle cx="${look + 3}" cy="-3" r="1.8" fill="#fff"/><path d="${brow}" stroke="#1A1A1A" stroke-width="5" stroke-linecap="round" fill="none"/></g>`).join('')}</g>`
  eyes.innerHTML =
    `<rect x="0" y="134" width="640" height="84" fill="#0A0F1C"/><rect x="0" y="134" width="640" height="2" fill="#F5B82E"/><rect x="0" y="216" width="640" height="2" fill="#F5B82E"/>` +
    eyePair(160, 9, 'M-30 -18 L26 -8') +
    eyePair(480, -9, 'M-26 -8 L30 -18') +
    `<path d="M319 140 V212" stroke="#F5B82E" stroke-width="2" stroke-dasharray="4 4"/>`
  const old = (t: number) => {
    cam(svg, 1.15 + 0.1 * inout(seg(t, 0.3, tS)), 320, 160)
    sa(eyes, 'opacity', SMOOTH ? 0 : seg(t, 0.5, 0.6) * (1 - seg(t, 1.05, 1.15)))
    if (t > 0.5 && t < 1.15)
      sa(eyes, 'transform', `translate(320 176) scale(${(1 + 0.12 * seg(t, 0.5, 1.15)).toFixed(3)}) translate(-320 -176)`)
    sa(hush, 'opacity', seg(t, 0.2, 0.6) * (1 - seg(t, 2, 2.3)))
    const v = SMOOTH ? 0 : seg(t, 0.05, 0.25) * (1 - seg(t, 1.0, 1.2))
    sa(vs, 'opacity', v)
    if (v > 0) {
      fT.face?.('side', 1)
      fT.at(170 + (1 - ease(seg(t, 0.05, 0.4))) * -60, 180, 0, 1.9)
      fT.pose(4, -4, 14, -14)
      fK.face?.('side', -1)
      fK.at(470 + (1 - ease(seg(t, 0.05, 0.4))) * 60, 180, 0, 1.9)
      fK.pose(12, -12, 50, -50)
    }
    // The run-up from the edge of the box, a stutter, then the kick.
    const f = inout(seg(t, 1.1, tS))
    put(tk, lerp(352, 324, f), lerp(256, spot[1] + 6, f))
    if (t < 1.1) tk.pose(4, -4, 8, -8)
    else if (t < tS - 0.3) tk.run(t * 11, 0.8)
    else tk.kick(seg(t, tS - 0.3, tS + 0.12))
    if (t > KT + 0.6 && e.scored) tk.celebrate(t)
    if (t > KT + 0.4 && !e.scored) tk.despair()
    // The keeper bounces on his line, then goes.
    // [Sprint 42 H2] One keeper in two puts the taker off with his spaghetti legs, arms waving, on his line.
    if (t < tS && wobbly && t > 1.2) {
      const q = Math.sin(t * 14)
      ready(kp, 320 + Math.sin(t * 5) * 14, LINE + 2, t, 1.1)
      kp.pose(36 * q, -36 * q, 120 + 40 * q, -120 + 40 * q, Math.max(0, q) * 0.5, Math.max(0, -q) * 0.5)
    } else if (t < tS) {
      ready(kp, 320 + Math.sin(t * 2.4) * 6, LINE + 2, t, 1.3)
      kp.pose(14, -14, 52 + Math.sin(t * 6) * 8, -52 - Math.sin(t * 6) * 8)
    } else dive(kp, 320, LINE + 2, kAim[0], kAim[1], seg(t, tS + 0.03, KT), seg(t, KT + 0.2, KT + 0.85))
    let p,
      gr = LINE + 2
    if (t < tS) {
      p = spot
      gr = spot[1]
    } else if (t < KT) {
      const g = seg(t, tS, KT)
      p = bez(path, g)
      gr = lerp(spot[1], LINE + 2, g)
      drawTrail(trl, path, g, 0.55)
    } else if (e.scored) {
      const a = t - KT,
        d = clamp((a - 0.15) / 0.5)
      p = [target[0], lerp(target[1] - 8 * ease(clamp(a / 0.15)), 146, d * d)]
      gr = LINE - 8
      sa(trl, 'opacity', 0)
    } else {
      const a = ease(clamp((t - KT) / 0.8))
      p = bez([target, [target[0] - dir * 30, target[1] - 30], [target[0] + dir * 110, 200]], a)
      gr = lerp(LINE, 200, a)
      sa(trl, 'opacity', 0)
    }
    b.set(p[0], p[1], gr, t > tS ? t * 2000 : 0)
    if (e.scored) {
      G.bulge(target[0], target[1] - 8, 1.9 * seg(t, KT, KT + 0.1) * (1 - seg(t, KT + 0.3, KT + 1.3)))
      fl(seg(t, KT - 0.01, KT + 0.05) * (1 - seg(t, KT + 0.05, KT + 0.25)) * 0.16)
      cf(t, t > KT)
      shakeIt(svg, 6 * seg(t, KT, KT + 0.04) * (1 - seg(t, KT + 0.05, KT + 0.6)), t)
    }
    tt(seg(t, KT + 0.2, KT + 0.6))
  }
  return {
    dur: 5.6 + PRE,
    svg,
    update(t: number) {
      old(Math.max(0, t - PRE))
      // The referee: runs in, blows (0.15), points at the spot, then steps away as the taker places the ball.
      const away = ease(seg(t, PRE - 0.25, PRE + 0.4))
      sa(rf.g, 'opacity', 1 - away)
      if (away < 1) {
        const inn = ease(seg(t, 0, 0.3))
        rf.face?.('front')
        rf.mood(t > 0.12 ? 'angry' : 'focus')
        put(rf, lerp(500, 430, inn) + away * 80, 236)
        const pt = ease(seg(t, 0.25, 0.45))
        rf.pose(3, -3, lerp(10, 78, pt), t < 0.3 ? -150 : -12)
        const [hx, hy] = [lerp(500, 430, inn), 236 - 58 * persp(236) - 21 * persp(236)]
        blow(hx + 6, hy + 4, seg(t, 0.1, 0.5))
      }
      sa(spotRing, 'opacity', seg(t, 0.35, 0.5) * (1 - seg(t, PRE, PRE + 0.4)) * (0.6 + 0.4 * Math.sin(t * 18)))
      sa(
        spotRing,
        'transform',
        `translate(${spot[0]} ${spot[1]}) scale(${(1 + 0.6 * seg(t, 0.35, PRE)).toFixed(2)}) translate(${-spot[0]} ${-spot[1]})`,
      )
    },
  }
}
