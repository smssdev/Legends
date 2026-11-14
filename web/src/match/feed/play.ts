// [Sprint 57 W4] Open play: the build-up and the shot that most scenes (goal, save, miss, VAR) share.
import { dizzy, popEyes } from './effects'
import { ball, dive, drawTrail, keeper, player, put, ready, trail } from './figures'
import { K, type SceneData, bez, clamp, ease, el, inout, lerp, other, rnd, sa, seg } from './kit'
import { LINE, POSTS, cam, goalFrame, persp, ref, stage } from './stage'

export function openPlay(e: SceneData, outcome: string, KT: number) {
  const R = rnd(e.v ?? Number(e.no ?? 9) * 977),
    pick = <T>(a: T[]): T => a[Math.floor(R() * a.length)]
  const svg = stage(e.side),
    w = svg.world,
    atk = K(e.side).kit,
    dfk = K(other(e.side)).kit
  const q =
    e.quality && ['big', 'normal', 'half', 'long', 'header'].includes(e.quality)
      ? e.quality
      : pick(['normal', 'normal', 'half', 'long', 'big'])
  const lane = e.lane && ['left', 'center', 'right'].includes(e.lane) ? e.lane : pick(['left', 'center', 'right'])
  const lx = ({ left: 248, center: 320, right: 392 } as Record<string, number>)[lane] + (R() - 0.5) * 26,
    side = lx < 320 ? -1 : 1
  const spot =
    q === 'header'
      ? [320 + side * 18 + (R() - 0.5) * 20, 194]
      : q === 'big'
        ? [lerp(lx, 320, 0.4), 198]
        : q === 'long'
          ? [lx, 292]
          : q === 'half'
            ? [lx + side * 22, 226]
            : [lx, 250]
  const F = ({ big: 0.36, header: 0.4, normal: 0.5, half: 0.46, long: 0.72 } as Record<string, number>)[q],
    tS = KT - F
  const tP0 = 0.45,
    tP1 = q === 'big' ? 0.9 : tS - 0.6

  const G = goalFrame(svg)
  const kp = keeper(svg, other(e.side), Math.floor(R() * 40))
  // Who else is in the picture: the marker on the shooter, a covering centre back, a team-mate arriving.
  // Shirt numbers: the engine's players where it names them, never two the same.
  const free = [7, 10, 11, 8, 17, 6, 14, 20].filter((n) => String(n) !== String(e.no))
  const passNo = e.passNo && String(e.passNo) !== String(e.no) ? e.passNo : free.shift()
  const mateNo = free.filter((n) => String(n) !== String(passNo))[Math.floor(R() * 4)]
  const cover = player(w, dfk, '', 1, { look: Math.floor(R() * 40) })
  const mate = player(w, atk, mateNo, 1, { look: Math.floor(R() * 40) })
  const passer = player(w, atk, passNo, 1, { look: Math.floor(R() * 40) })
  const marker = player(w, dfk, e.defNo ?? '', 1, { look: Math.floor(R() * 40) })
  const sh = player(w, atk, e.no, 1, { look: Math.floor(R() * 40) })
  const b = ball(svg),
    trl = trail(svg, w, outcome === 'save' ? '#FF9A3D' : undefined)

  // Where the move starts, and the pass that sets the shooter up.
  const pFrom =
    q === 'header'
      ? [side > 0 ? 548 : 92, 214]
      : q === 'big'
        ? [Math.max(110, Math.min(530, lx - side * 150)), 290]
        : [Math.max(110, Math.min(530, spot[0] - side * (130 + R() * 40))), Math.min(300, spot[1] + 18)]
  const sFrom = q === 'header' ? [spot[0] + side * 26, 238] : q === 'big' ? [spot[0] + side * 20, 300] : [spot[0] + side * 34, spot[1] + 46]
  const recv =
    q === 'header'
      ? spot
      : q === 'big'
        ? [lerp(sFrom[0], spot[0], 0.35), lerp(sFrom[1], spot[1], 0.35)]
        : [spot[0] + side * 6, spot[1] + 10]

  // Where the ball ends: chosen from the outcome, then the keeper's answer to it.
  const corner = (far: boolean) => [
    side * (far ? -1 : 1) > 0 ? POSTS[1] - 9 - R() * 10 : POSTS[0] + 9 + R() * 10,
    pick([84, 92, 136, 142, 140]),
  ]
  let target,
    kGoal,
    kWrong = false,
    after = 'net'
  // [Sprint 35 C2] How a one-on-one ends: a chip over the keeper coming out, or round him into the empty net.
  const finish = outcome === 'goal' && q === 'big' ? pick(['shot', 'shot', 'chip', 'round']) : 'shot'
  if (outcome === 'goal' && finish === 'chip') {
    target = [320 + side * (8 + R() * 20), 140]
    kGoal = [lerp(320, target[0], 0.4), 150]
  } else if (outcome === 'goal' && finish === 'round') {
    target = [320 - side * (20 + R() * 20), 144]
    kGoal = [320 + side * 40, 170]
  } else if (outcome === 'goal') {
    target = q === 'big' && R() < 0.4 ? [320 + side * (30 + R() * 25), 144] : corner(R() < 0.6)
    kWrong = q !== 'big' && R() < 0.3
    const reach = q === 'long' && target[1] < 100 ? 0.5 : 0.72
    kGoal = kWrong ? [640 - target[0], target[1] + 6] : [lerp(320, target[0], reach), lerp(110, target[1], reach)]
  } else if (outcome === 'save') {
    const high = R() < 0.45
    target = [320 + (R() < 0.5 ? -1 : 1) * (q === 'big' ? 14 + R() * 18 : 20 + R() * 46), high ? 86 + R() * 16 : 118 + R() * 24]
    after = e.corner ? (target[1] < 104 ? 'tip' : 'parry') : Math.abs(target[0] - 320) < 30 ? 'hold' : pick(['hold', 'parry'])
    // [Sprint 35 C2] Different saves: a high ball near him punched clear with both fists, a low one near him blocked
    // with his foot (a one-on-one), a high one wide tipped over.
    if (!e.corner && high && Math.abs(target[0] - 320) < 34 && R() < 0.6) after = 'punch'
    else if (!e.corner && !high && q === 'big' && R() < 0.6) {
      after = 'foot'
      target = [320 + side * (10 + R() * 14), 142]
    } else if (!e.corner && high && Math.abs(target[0] - 320) > 40 && R() < 0.4) after = 'tip'
    kGoal = target
  } else if (outcome === 'miss') {
    const how = e.how ?? 'wide'
    target =
      how === 'over'
        ? [300 + R() * 40, 54]
        : how === 'post'
          ? [side > 0 ? POSTS[1] : POSTS[0], 96 + R() * 34]
          : [side > 0 ? POSTS[1] + 16 + R() * 18 : POSTS[0] - 16 - R() * 18, 112 + R() * 30]
    after = how
    kGoal = [lerp(320, target[0], how === 'over' ? 0.15 : 0.6), lerp(110, Math.max(80, target[1]), 0.6)]
  } else {
    // Blocked: the marker throws himself in the way a few steps from the shooter.
    target = [lerp(spot[0], 320, 0.2), lerp(spot[1], LINE, 0.2) - 6]
    after = 'block'
    kGoal = [320, 120]
  }
  const strike = [spot[0] - 3, spot[1] + 2]
  const loft =
    finish === 'chip'
      ? 110
      : ({ big: 28, normal: 48, half: 34, long: 70, header: 14 } as Record<string, number>)[q] + (target[1] < 100 ? 22 : 0)
  const path = [strike, [(strike[0] + target[0]) / 2 + side * (R() - 0.3) * 40, Math.min(strike[1], target[1]) - loft], target]
  const groundOf = (f: number) => lerp(strike[1], outcome === 'blocked' ? target[1] + 6 : LINE + 2, f)
  const kRush = q === 'big' ? (finish === 'shot' ? 22 : 46) : 0,
    kx0 = () => 320 + (lx - 320) * 0.18
  // [Sprint 42 H2] Ten celebrations: the five before, and a jump with a spin, the aeroplane, a backflip, a dance, and
  // a finger to the lips towards the other side's fans.
  const party = outcome === 'goal' ? pick(['corner', 'slide', 'leap', 'crowd', 'pile', 'spin', 'plane', 'flip', 'dance', 'shush']) : null
  // [Sprint 42 F] The server's telling of the move (e.drama): a nutmeg on the marker before the shot, a no-look pass
  // that pops the defenders' eyes out, a bicycle kick from the cross; a double save keeps the ball alive (a parry).
  const drama = e.drama,
    nut = drama === 'nutmeg' && (q === 'big' || q === 'normal'),
    look = drama === 'nolook',
    bike = drama === 'bicycle' && q === 'header'
  if (drama === 'double' && outcome === 'save') after = 'parry'
  const tN = lerp(tP1, tS, 0.45)
  const aura = nut
    ? el('circle', { r: 22, fill: 'none', stroke: '#FFD36B', 'stroke-width': 3, opacity: 0, filter: ref(svg, 'glow') }, w)
    : null
  const daze = nut ? dizzy(svg) : null
  const pop = look ? [popEyes(svg), popEyes(svg)] : null
  const out = side > 0 ? 1 : -1
  let landed = null

  return {
    svg,
    go: (t: number) => {
      // The camera closes in as the chance builds, and stays on the goal for the outcome.
      cam(svg, 1.02 + 0.16 * inout(seg(t, tP0, tS + 0.1)) - (outcome === 'goal' ? 0.08 * inout(seg(t, KT + 0.9, KT + 2)) : 0), 320, 168)

      // The team-mate and the covering defender.
      const mt = ease(seg(t, 0.2, KT + 0.4))
      put(mate, lerp(640 - lx + side * 30, 640 - lx - side * 10, mt), lerp(262, 214, mt))
      mate.run(t * 13, mt < 1 ? 0.8 : 0.1)
      const ct = ease(seg(t, 0.3, tS))
      put(cover, lerp(320 - side * 40, lerp(spot[0], 320, 0.55), ct), lerp(204, 196, ct))
      cover.run(t * 12, ct < 1 ? 0.7 : 0.15)

      // The passer: the ball at his feet, then the pass (on the ground, or the cross in the air).
      // ... and after it he follows the move up the pitch.
      const pt = seg(t, 0, tP0),
        fw = ease(seg(t, tP0 + 0.25, KT + 1)) * 0.35
      put(passer, lerp(lerp(pFrom[0] + side * 18, pFrom[0], ease(pt)), spot[0], fw), lerp(pFrom[1], spot[1] + 20, fw))
      if (t < tP0 - 0.15) passer.run(t * 12)
      else if (t < tP0 + 0.25) passer.kick(seg(t, tP0 - 0.15, tP0 + 0.15))
      else passer.run(t * 12, fw < 0.35 ? 0.8 : 0.1)
      // The no-look pass: he looks hard the other way while the ball goes this way.
      if (look) passer.face?.(t < tP0 + 0.4 ? 'side' : 'back', recv[0] > pFrom[0] ? -1 : 1)

      // The shooter: runs onto it, a touch to set himself, the strike (or the leap for a header).
      let sx,
        sy,
        lift = 0
      if (t < tP1) {
        const f = inout(seg(t, 0.1, tP1))
        sx = lerp(sFrom[0], recv[0], f)
        sy = lerp(sFrom[1], recv[1], f)
      } else {
        const f = inout(seg(t, tP1, tS))
        sx = lerp(recv[0], spot[0], f)
        sy = lerp(recv[1], spot[1], f)
      }
      if (q === 'header') lift = (bike ? 44 : 26) * Math.sin(Math.PI * seg(t, tS - (bike ? 0.45 : 0.32), tS + 0.3))
      // [Sprint 42 C1] A dangerous run: he weaves past his man in a zig-zag before the shot.
      if ((q === 'big' || q === 'normal') && t > tP1 - 0.1 && t < tS)
        sx += Math.sin((t - tP1) * 15) * 10 * seg(t, tP1 - 0.1, tP1 + 0.15) * (1 - seg(t, tS - 0.3, tS - 0.08))
      // Round the keeper: a touch past him to the side, then the finish.
      if (finish === 'round') sx -= side * 36 * ease(seg(t, tS - 0.5, tS - 0.05))
      // The bicycle kick: he turns right over in the air, his back to the goal, and lands.
      const flip = bike ? 190 * inout(seg(t, tS - 0.45, tS)) * (1 - inout(seg(t, tS + 0.1, tS + 0.45))) : 0
      put(sh, sx, sy, bike ? -side * flip : q === 'header' ? -side * 8 * seg(t, tS - 0.3, tS) : 0, 1, lift)
      if (t > KT + 0.5 && outcome === 'goal') {
        // [Sprint 36 F1] The celebration, one of five (from the scene's seed): away to the corner flag arms out, a
        // slide on his knees, a leap punching the air, arms wide towards the crowd, or his team-mates piling on him.
        const c = ease(seg(t, KT + 0.5, KT + 2.6))
        if (party === 'spin') {
          const j = seg(t, KT + 0.9, KT + 1.5),
            up = Math.sin(Math.PI * j) * 34
          put(sh, lerp(spot[0], spot[0] + out * 70, c), spot[1] + 14, 0, 1, up)
          sh.face?.(j > 0 && j < 1 ? (Math.floor(j * 4) % 2 ? 'side' : 'front') : j >= 1 ? 'front' : 'back', out)
          sh.mood('joy')
          j >= 1 ? sh.pose(26, -26, 50, -50) : sh.pose(6, -6, 30, -30)
        } else if (party === 'plane') {
          put(
            sh,
            lerp(spot[0], spot[0] + out * 160, c),
            lerp(spot[1], spot[1] + 34, c) + Math.sin((t - KT) * 6) * 10,
            Math.sin((t - KT) * 6) * 16,
          )
          sh.pose(6, -6, 92, -92)
        } else if (party === 'flip') {
          const j = seg(t, KT + 0.9, KT + 1.5),
            up = Math.sin(Math.PI * j) * 40
          put(sh, spot[0] + out * 40 * c, spot[1] + 14, -out * 360 * inout(j), 1, up)
          j < 1 && j > 0 ? sh.pose(60, 60, 120, -120) : sh.pose(6, -6, 160, -160)
        } else if (party === 'dance') {
          put(sh, spot[0] + out * 50 * c, spot[1] + 16, Math.sin((t - KT) * 10) * 10)
          sh.face?.('front')
          sh.mood('joy')
          const d = Math.sin((t - KT) * 10)
          sh.pose(10 * d, -10 * d, 60 + 40 * d, -60 + 40 * d, Math.max(0, d) * 0.4, Math.max(0, -d) * 0.4)
        } else if (party === 'shush') {
          put(sh, lerp(spot[0], 320 - out * 40, c), lerp(spot[1], 290, c), 0, 1.1)
          sh.face?.('front')
          sh.mood('focus')
          sh.pose(4, -4, 14, 158)
        } else if (party === 'slide') {
          const sl = ease(seg(t, KT + 0.7, KT + 1.6))
          put(sh, lerp(spot[0], spot[0] + out * 120, c), lerp(spot[1], spot[1] + 40, c), -out * 18 * sl, 1, -10 * sl)
          sh.pose(70, 70, 140, -140)
        } else if (party === 'leap') {
          const up = Math.abs(Math.sin((t - KT) * 5)) * 22 * seg(t, KT + 0.6, KT + 0.9)
          put(sh, lerp(spot[0], spot[0] + out * 40, c), spot[1] + 10, 0, 1, up)
          sh.pose(10, -10, 175, -20)
        } else if (party === 'crowd') {
          put(sh, lerp(spot[0], 320 + out * 30, c), lerp(spot[1], 300, c), 0, 1.15)
          sh.face?.('front')
          sh.mood?.('joy')
          sh.pose(6, -6, 95, -95)
        } else if (party === 'pile') {
          put(sh, lerp(spot[0], spot[0] + out * 60, c), lerp(spot[1], spot[1] + 20, c))
          sh.celebrate(t)
        } else {
          put(sh, lerp(spot[0], spot[0] + out * 150, c), lerp(spot[1], spot[1] + 30, c))
          sh.celebrate(t)
        }
        // The team-mates: the one nearest runs to him, and in a pile-on the passer too, arms around him.
        const near = party === 'pile' ? 0.92 : 0.8
        put(mate, lerp(640 - lx - side * 10, lerp(spot[0], spot[0] + out * 150, c) - out * 18 * (1 - near), c), lerp(214, spot[1] + 30, c))
        mate.celebrate(t + 0.4)
        if (party === 'pile') {
          const pc = ease(seg(t, KT + 0.8, KT + 2.4))
          put(passer, lerp(spot[0] - side * 60, spot[0] + out * 66, pc), lerp(spot[1] + 30, spot[1] + 26, pc))
          passer.pose(6, -6, 120, -60)
        }
      } else if (t > KT + 0.3 && outcome !== 'goal') sh.despair()
      else if (bike && t > tS - 0.45 && t < tS + 0.45) sh.pose(30, -150 * Math.sin(Math.PI * seg(t, tS - 0.3, tS + 0.1)), 120, -120, 0.2, 0)
      else if (q === 'header' && t > tS - 0.35) sh.pose(10, -10, 60, -60, 0.4, 0.4)
      else if (t > tS - 0.32 && t < tS + 0.3) sh.kick(seg(t, tS - 0.32, tS + 0.12))
      else sh.run(t * 13, t < tS ? 1 : 0.2)

      // The marker chases from behind; on a block he slides across the shot.
      const mk = ease(seg(t, 0.1, tS))
      let mx = lerp(sFrom[0] + side * 30, sx + side * 16, mk),
        my = lerp(sFrom[1] - 12, sy - 8, mk),
        mr = 0
      let low = 0
      if (outcome === 'blocked') {
        const sl = ease(seg(t, tS - 0.3, KT))
        mx = lerp(mx, target[0] + side * 10, sl)
        my = lerp(my, target[1] + 6, sl)
        mr = -side * 72 * sl
        low = -30 * persp(my) * sl
      }
      // The nutmeg: the marker squares up in front of him, the ball goes through his legs, his legs twist round in a
      // corkscrew and he goes down on his back with stars round his head.
      if (nut && t > tN - 0.45) {
        const st = ease(seg(t, tN - 0.45, tN - 0.2))
        mx = lerp(mx, sx - side * 16, st)
        my = lerp(my, sy - 16, st)
      }
      // The close-up on the feet for the nutmeg, then back out for the shot.
      if (nut) {
        const z = ease(seg(t, tN - 0.4, tN - 0.15)) * (1 - ease(seg(t, tN + 0.55, tN + 0.85)))
        if (z > 0) cam(svg, lerp(1.18, 1.9, z), lerp(320, sx, z), lerp(168, sy - 14, z))
      }
      const twist = nut ? seg(t, tN, tN + 0.35) : 0,
        down = nut ? ease(seg(t, tN + 0.3, tN + 0.55)) : 0
      put(marker, mx, my, nut ? -side * (twist * 540 * (1 - down) + 90 * down) : mr, 1, nut ? -24 * persp(my) * down : low)
      if (nut && t > tN) marker.pose(-20 + 40 * Math.sin(t * 30) * (1 - down), 20 - 40 * Math.sin(t * 30) * (1 - down), 60, -60)
      else {
        outcome === 'blocked' && t > tS - 0.3 ? marker.pose(30, -30, 80, -40) : marker.run(t * 12.5, mk < 1 ? 1 : 0.3)
      }
      if (outcome === 'goal' && t > KT + 0.4 && !nut) marker.despair()
      if (nut) {
        daze!(mx + side * 14 * persp(my), my - 20 * persp(my), t, t > tN + 0.5)
        const on = seg(t, tN - 0.05, tN + 0.1) * (1 - seg(t, tS - 0.1, tS + 0.2)),
          s0 = persp(sy)
        sa(aura!, 'opacity', on)
        if (on > 0)
          sa(
            aura!,
            'transform',
            `translate(${sx.toFixed(1)} ${(sy - 30 * s0).toFixed(1)}) scale(${(s0 * (1.6 + 0.15 * Math.sin(t * 16))).toFixed(2)} ${(s0 * 2.4).toFixed(2)})`,
          )
      }
      // The no-look pass: both defenders' eyes pop out on stalks, following the ball the wrong way.
      if (look) {
        const f = seg(t, tP0, tP0 + 0.12) * (1 - seg(t, tP0 + 0.85, tP0 + 1.0)),
          dir = recv[0] > pFrom[0] ? 1 : -1
        const cx = lerp(320 - side * 40, lerp(spot[0], 320, 0.55), ease(seg(t, 0.3, tS))),
          cy = lerp(204, 196, ease(seg(t, 0.3, tS)))
        pop![0](cx, cy - 80 * persp(cy), f, dir)
        pop![1](mx, my - 80 * persp(my), f, dir)
      }

      // The keeper: on his line (or rushing out one on one), then the dive.
      const ky = LINE + 2 + kRush * ease(seg(t, tP0, tS))
      const k0 = lerp(320, kx0(), ease(seg(t, 0, tS)))
      let glove = null
      const tD = tS + (kWrong ? 0.02 : 0.1)
      if (t < tD) ready(kp, k0 + (sx - 320) * 0.08, ky, t, q === 'big' ? 1.4 : 1)
      else {
        const f = seg(t, tD, KT),
          a = seg(t, KT + 0.25, KT + 0.9)
        if (after === 'punch') {
          const j = Math.sin(Math.PI * Math.min(1, f * 1.2))
          put(kp, lerp(k0, target[0], f), ky, 0, 1, 26 * j)
          kp.pose(10, -10, 172, -172, 0.3, 0.3)
          glove = [target[0], target[1]]
        } else if (after === 'foot') {
          put(kp, lerp(k0, target[0] - side * 8, f), ky + 6 * f)
          kp.pose(6, -64 * f * side, 40, -40)
          glove = [target[0], target[1]]
        } else glove = after === 'block' ? (ready(kp, k0, ky, t), null) : dive(kp, k0, ky, kGoal[0], kGoal[1], f, a)
        if (outcome === 'goal' && t > KT + 1.6) kp.pose(4, -4, 150, -150)
      }

      // The ball.
      let bx,
        by,
        gr,
        turn = t * 900,
        op = 1
      if (t < tP0) {
        bx = pFrom[0] - 2
        by = pFrom[1] + 1
        gr = by
      } else if (t < tP1) {
        const f = seg(t, tP0, tP1)
        if (q === 'header') {
          const p = bez([pFrom, [lerp(pFrom[0], recv[0], 0.5), 96], [recv[0], recv[1] - 46]], f)
          bx = p[0]
          by = p[1]
          gr = lerp(pFrom[1], recv[1], f)
        } else {
          bx = lerp(pFrom[0], recv[0], ease(f))
          by = lerp(pFrom[1] + 1, recv[1] + 1, ease(f))
          gr = by
        }
      } else if (t < tS) {
        if (q === 'header') {
          bx = recv[0]
          by = recv[1] - 46
          gr = recv[1]
        } else {
          bx = sx + side * -3 + Math.sin(t * 13) * 2
          by = sy + 2
          gr = by
        }
        // Through his legs, and collected on the other side.
        if (nut && t > tN - 0.15 && t < tN + 0.25) {
          const f = seg(t, tN - 0.15, tN + 0.25)
          by = lerp(sy + 2, sy - 30, Math.sin(Math.PI * f) * 0.9)
          gr = by
        }
      } else if (t < KT) {
        const f = seg(t, tS, KT),
          from = q === 'header' ? [spot[0], spot[1] - 46] : strike
        const p = bez([from, path[1], target], f)
        bx = p[0]
        by = p[1]
        gr = groundOf(f)
        drawTrail(trl, [from, path[1], target], f, 0.55)
        turn = t * 2400
      } else {
        // What happens once it gets there.
        const a = t - KT
        sa(trl, 'opacity', Math.max(0, 0.55 - a * 1.5))
        if (after === 'net') {
          const f = ease(clamp(a / 0.18)),
            d = clamp((a - 0.18) / 0.5)
          bx = target[0] + (target[0] - 320) * 0.05 * f
          by = lerp(target[1] - 10 * f, 146, d * d) - Math.abs(Math.sin(d * 9)) * 4 * (1 - d)
          gr = LINE - 8
        } else if (after === 'hold') {
          landed ??= glove
          bx = (glove ?? landed)[0]
          by = (glove ?? landed)[1]
          gr = LINE + 2
          turn = 0
        } else if (after === 'parry') {
          const f = ease(clamp(a / 0.8)),
            dx = Math.sign(target[0] - 320) || 1
          const p = bez([target, [target[0] + dx * 70, target[1] - 26], [target[0] + dx * (e.corner ? 150 : 96), 196]], f)
          bx = p[0]
          by = p[1] - Math.abs(Math.sin(f * 7)) * 8 * (1 - f)
          gr = lerp(LINE, 196, f)
        } else if (after === 'punch') {
          const f = ease(clamp(a / 0.8))
          const p = bez(
            [target, [target[0] + (target[0] - 320) * 2, target[1] - 40], [target[0] + (target[0] >= 320 ? 120 : -120), 230]],
            f,
          )
          bx = p[0]
          by = p[1]
          gr = lerp(LINE, 230, f)
        } else if (after === 'foot') {
          const f = ease(clamp(a / 0.8))
          const p = bez([target, [target[0] - side * 50, target[1] + 10], [target[0] - side * 150, 220]], f)
          bx = p[0]
          by = p[1]
          gr = lerp(LINE + 4, 220, f)
        } else if (after === 'tip') {
          const f = ease(clamp(a / 0.7))
          bx = target[0] + Math.sign(target[0] - 320) * 26 * f
          by = lerp(target[1], 30, f)
          gr = LINE - 10 * f
          op = 1 - seg(a, 0.45, 0.7)
        } else if (after === 'post') {
          const f = ease(clamp(a / 0.9))
          const p = bez([target, [lerp(target[0], 320, 0.3), target[1] + 10], [lerp(target[0], 320, 0.55), 212]], f)
          bx = p[0]
          by = p[1] - Math.abs(Math.sin(f * 6)) * 10 * (1 - f)
          gr = lerp(LINE, 212, f)
        } else if (after === 'block') {
          const f = ease(clamp(a / 0.9))
          const p = bez([target, [target[0] + side * 60, target[1] - 40], [target[0] + side * 160, target[1] + 40]], f)
          bx = p[0]
          by = p[1]
          gr = lerp(target[1] + 6, target[1] + 40, f)
        } else {
          const f = clamp(a / 0.7)
          bx = target[0] + (target[0] - strike[0]) * 0.18 * f
          by = target[1] - 30 * f
          gr = LINE - 20 * f
          op = 1 - f
        }
      }
      b.set(bx, by, gr, turn, op)
      // [Sprint 42 C2] The net stretches far back, as in a cartoon; the woodwork wobbles hard.
      if (after === 'net') G.bulge(target[0], target[1] - 8, 1.9 * seg(t, KT, KT + 0.1) * (1 - seg(t, KT + 0.3, KT + 1.3)))
      if (after === 'post') {
        const wob = seg(t, KT, KT + 0.05) * (1 - seg(t, KT + 0.1, KT + 1.0))
        sa(G.frame, 'transform', `translate(${(Math.sin(t * 70) * 4.5 * wob).toFixed(1)} ${(Math.cos(t * 55) * 1.5 * wob).toFixed(1)})`)
      }
      return { target, sx, sy, tS, tN, dir: [spot[0] - sFrom[0], spot[1] - sFrom[1]], ball: [bx, by], sh, kp, glove, after, b, mate, trl }
    },
  }
}
