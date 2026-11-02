// @ts-nocheck
// The cartoon player of the live pitch on a canvas [Sprint 31 P1]: the same figure as art.ts's player() (its shapes are
// the same SVG paths, through Path2D), with the same posing calls (face, pose, run, idle), drawn by draw(ctx, ...).
// Its shirt, shorts and head are drawn once per facing into a small sprite; only the legs and arms are drawn every frame.
import { HAIR, SKINS, lum, shade } from './art'

const P = {
  boot: new Path2D('M-5.5 27 h10 q4.5 0 4.5 3.2 v1.6 h-14.5 z'),
  shorts: new Path2D('M-13.5 17 H13.5 L15 31 H1.5 L0 27 L-1.5 31 H-15 Z'),
  shirt: new Path2D('M-15 -9 Q0 -15 15 -9 L14.5 21 Q0 24 -14.5 21 Z'),
  fold: new Path2D('M-6 21 Q0 -2 6 21'),
  collar: new Path2D('M-15 -9 Q0 -15 15 -9'),
  hairBack: new Path2D('M-9.6 -21 Q-10 -32 0 -32.5 Q10 -32 9.6 -21 Q7 -24 3 -24.5 Q-4 -25 -9.6 -21 Z'),
  hairFront: new Path2D('M-9.6 -22 Q-10 -32 0 -32.5 Q10 -32 9.6 -22 Q6 -28 0 -28 Q-6 -28 -9.6 -22 Z'),
  hairSide: new Path2D('M-9.6 -19 Q-11 -32 0 -32.5 Q9 -32 9.4 -24 Q4 -27 -1 -25 Q-3 -20 -9.6 -19 Z'),
  mouth: new Path2D('M-2.6 -16.6 Q0 -15 2.6 -16.6'),
  nose: new Path2D('M9 -21 L11.6 -18.6 L9 -17.6'),
}
function rr(c, x, y, w, h, r) {
  c.beginPath(); c.moveTo(x + r, y); c.arcTo(x + w, y, x + w, y + h, r); c.arcTo(x + w, y + h, x, y + h, r); c.arcTo(x, y + h, x, y, r); c.arcTo(x, y, x + w, y, r); c.closePath(); c.fill()
}
const dot = (c, x, y, r, fill) => { c.fillStyle = fill; c.beginPath(); c.arc(x, y, r, 0, Math.PI * 2); c.fill() }
// [X76] A kit pattern over the shirt's box (-15..15 across, -15..24 down), clipped to the shirt by the caller.
export function kitPattern(c, p) {
  if (p === 'stripes') for (let x = -12; x <= 12; x += 8) c.fillRect(x - 2, -16, 4, 42)
  else if (p === 'hoops') for (let y = -8; y <= 22; y += 9) c.fillRect(-16, y - 2.2, 32, 4.4)
  else if (p === 'halves') c.fillRect(0, -16, 16, 42)
  else if (p === 'sash') { c.beginPath(); c.moveTo(-16, -6); c.lineTo(-9, -16); c.lineTo(16, 16); c.lineTo(16, 25); c.closePath(); c.fill() }
}
// The sprite's box in the figure's units, and its resolution.
const BOX = { x: -17, y: -34, w: 34, h: 67 }, RES = 3

export function figure(kit, no, o = {}) {
  const light = lum(kit) > 150, ink = light ? '#0A1F42' : '#fff', look = o.look ?? 0
  const skin = SKINS[look % SKINS.length], hair = HAIR[Math.floor(look / 7) % HAIR.length], shorts = o.shorts ?? (light ? '#1C2B48' : shade(kit, -80))
  const socks = o.socks ?? (light ? kit : shade(kit, 25)), trim = o.trim ?? shade(kit, light ? -45 : 45)
  const sprites = {}
  // The shirt, shorts and head for one facing, drawn once.
  function sprite(f) {
    if (sprites[f]) return sprites[f]
    const cv = document.createElement('canvas')
    cv.width = BOX.w * RES; cv.height = BOX.h * RES
    const c = cv.getContext('2d')
    c.scale(RES, RES); c.translate(-BOX.x, -BOX.y)
    c.save()
    if (f === 'side') c.scale(0.72, 1)
    c.fillStyle = shorts; c.fill(P.shorts)
    c.fillStyle = kit; c.fill(P.shirt)
    // [X76] The club's pattern on the shirt, in its trim colour.
    if (o.pattern) { c.save(); c.clip(P.shirt); c.fillStyle = o.patternColour ?? trim; kitPattern(c, o.pattern); c.restore() }
    c.fillStyle = 'rgba(0,0,0,.08)'; c.fill(P.fold)
    c.strokeStyle = trim; c.lineWidth = 2; c.stroke(P.collar)
    c.fillStyle = ink; c.textAlign = 'center'
    // [Sprint 34 V3] His surname over the number on his back, as on a real shirt.
    if (f === 'back' && o.name) { c.font = '700 4.6px "Barlow Condensed", sans-serif'; c.fillText(String(o.name).toUpperCase().slice(0, 12), 0, 1.2) }
    if (f === 'back') { c.font = `800 ${o.name ? 15 : 18}px "Barlow Condensed", Amin, sans-serif`; c.fillText(String(no ?? ''), 0, o.name ? 14.5 : 12) }
    if (f === 'front') { c.font = '800 8px "Barlow Condensed", Amin, sans-serif'; c.fillText(String(no ?? ''), 6, 4) }
    c.restore()
    c.fillStyle = skin; c.fillRect(-3.4, -15, 6.8, 7); dot(c, 0, -21, 9.4, skin)
    // [Sprint 33 V1] Ears from the front, then his hair in its style, then the face.
    if (f === 'front') { dot(c, -9.4, -20.5, 2, skin); dot(c, 9.4, -20.5, 2, skin) }
    hairOf(c, f)
    if (f === 'front') {
      dot(c, -3.4, -21, 1.3, '#141414'); dot(c, 3.4, -21, 1.3, '#141414')
      c.strokeStyle = shade(hair, 10); c.lineWidth = 1.1; c.lineCap = 'round'
      c.beginPath(); c.moveTo(-5.2, -24.2); c.lineTo(-1.9, -24.7); c.moveTo(1.9, -24.7); c.lineTo(5.2, -24.2); c.stroke()
      c.strokeStyle = 'rgba(60,20,10,.35)'; c.lineWidth = 0.8; c.beginPath(); c.moveTo(0, -20.5); c.lineTo(-0.8, -18.4); c.lineTo(0.4, -18.2); c.stroke()
      c.strokeStyle = 'rgba(60,20,10,.6)'; c.lineWidth = 1; c.stroke(P.mouth)
    }
    if (f === 'side') { dot(c, 4.6, -22, 1.3, '#141414'); c.strokeStyle = shade(hair, 10); c.lineWidth = 1; c.beginPath(); c.moveTo(2.8, -24.6); c.lineTo(6.4, -24.4); c.stroke(); dot(c, -2.4, -20.5, 2, shade(skin, -12)); c.fillStyle = skin; c.fill(P.nose) }
    return (sprites[f] = cv)
  }
  // [Sprint 33 V1] His hair style from the caller (his id): short, cropped, curly, long or shaved.
  const style = ['short', 'crop', 'curly', 'long', 'shaved'][o.hair ?? 0] ?? 'short'
  function hairOf(c, f) {
    c.fillStyle = hair
    if (style === 'shaved') { c.fillStyle = 'rgba(255,255,255,.18)'; c.beginPath(); c.ellipse(-2.5, -27, 3.4, 1.6, -0.4, 0, Math.PI * 2); c.fill(); return }
    if (style === 'crop') { c.globalAlpha = 0.75; c.beginPath(); c.arc(0, -21, 9.7, Math.PI * (f === 'back' ? 0.95 : 1.08), Math.PI * (f === 'back' ? 2.05 : 1.92)); c.closePath(); c.fill(); c.globalAlpha = 1; return }
    if (style === 'curly') {
      const top = f === 'back' ? [[-7, -27], [-3.5, -30], [0.5, -31], [4.5, -29.5], [7.5, -26], [-8.5, -22.5], [8.5, -22.5], [0, -26]] : [[-7, -27], [-3.5, -30], [0.5, -31], [4.5, -29.5], [7.5, -26], [f === 'side' ? -8.5 : -8.8, -23.5]]
      for (const [x, y] of top) dot(c, x, y, 3.6, hair)
      return
    }
    c.fill(f === 'back' ? P.hairBack : f === 'front' ? P.hairFront : P.hairSide)
    if (style === 'long') {
      if (f === 'back') rr(c, -8.5, -24, 17, 13, 4)
      else if (f === 'front') { rr(c, -10.6, -26, 3.6, 13, 1.8); rr(c, 7, -26, 3.6, 13, 1.8) }
      else rr(c, -10, -25, 6, 13, 2.5)
      c.fillStyle = hair
    }
  }
  // [Sprint 31 D2] His build (slim, medium or strong: the shirt's width) and height, from the caller (his id).
  const bw = [0.88, 1, 1.14][o.build ?? 1] ?? 1, bh = o.tall ?? 1
  let facing = 'back', mirror = 1, card = null
  const legs = [{ x: -6, r: 3, lift: 0 }, { x: 6, r: -3, lift: 0 }], arms = [{ x: -14.5, r: 10 }, { x: 14.5, r: -10 }]
  function leg(c, l) {
    c.save(); c.translate(l.x * bw * (facing === 'side' ? 0.45 : 1), 25); c.rotate((l.r * Math.PI) / 180); c.scale(1, 1 - 0.45 * l.lift)
    c.fillStyle = skin; rr(c, -4.5, 0, 9, 15, 3.5)
    c.fillStyle = socks; rr(c, -4.6, 12, 9.2, 16, 3.5)
    c.fillStyle = '#0B0F1A'; c.fill(P.boot)
    c.restore()
  }
  function arm(c, a) {
    c.save(); c.translate(a.x * bw * (facing === 'side' ? 0.12 : 1), -7); c.rotate((a.r * Math.PI) / 180)
    c.fillStyle = kit; rr(c, -4, 0, 8, 12, 3.5)
    c.fillStyle = o.gloves ? kit : skin; rr(c, -3.4, 10, 6.8, 13, 3.4)
    if (o.gloves) { c.fillStyle = o.gloves; rr(c, -5, 20, 10, 9, 3.5) }
    // [Sprint 31 D1] An assistant referee's flag in his right hand.
    // [Sprint 34 V3] The captain's armband on his left arm.
    if (o.captain && a === arms[0]) { c.fillStyle = '#F5B82E'; c.fillRect(-4.3, 4, 8.6, 3.2); c.fillStyle = '#071733'; c.font = '800 2.8px sans-serif'; c.textAlign = 'center'; c.fillText('C', 0, 6.6) }
    // [Sprint 33 L2] The referee's card held up in his right hand.
    if (card && a === arms[1]) { c.fillStyle = card; c.fillRect(-3, 22, 6, 8.5); c.strokeStyle = 'rgba(0,0,0,.4)'; c.lineWidth = 0.6; c.strokeRect(-3, 22, 6, 8.5) }
    if (o.flag && a === arms[1]) { c.fillStyle = '#2B2B2B'; c.fillRect(-0.7, 18, 1.4, 16); c.fillStyle = o.flag; c.fillRect(0.7, 18, 9, 7); c.fillStyle = '#D3122F'; c.fillRect(0.7, 18, 4.5, 3.5); c.fillRect(5.2, 21.5, 4.5, 3.5) }
    c.restore()
  }
  const api = {
    get facing() { return facing },
    face(f = 'back', m = 1) { facing = f; mirror = f === 'side' ? (m < 0 ? -1 : 1) : 1 },
    pose(l1 = 3, l2 = -3, a1 = 10, a2 = -10, lift1 = 0, lift2 = 0) { legs[0].r = l1; legs[1].r = l2; legs[0].lift = lift1; legs[1].lift = lift2; arms[0].r = a1; arms[1].r = a2 },
    run(ph, amp = 1) {
      const q = Math.sin(ph)
      if (facing === 'side') { const st = 30 * q * amp; api.pose(st, -st, -st * 1.1, st * 1.1, Math.max(0, -q) * amp * 0.5, Math.max(0, q) * amp * 0.5); return }
      api.pose(4, -4, 16 + 24 * q * amp, -16 + 24 * q * amp, Math.max(0, q) * amp, Math.max(0, -q) * amp)
    },
    idle(b) { const w = Math.sin(b) * 3; api.pose(3, -3, 10 + w, -10 - w) },
    // [Sprint 32 A1] The moves of the live pitch (f 0..1 through each). A strike with the right foot: the leg swings
    // back, then through the ball.
    kick(f) { const r = f < 0.55 ? -4 + (-38 + 4) * (f / 0.55) : -38 + 90 * (1 - Math.pow(1 - (f - 0.55) / 0.45, 3)); api.pose(6, r, 34, -48, 0, f < 0.55 ? 0.55 : 0.15) },
    // A header: a jump with the knees bent and the arms out.
    header(f) { const a = 40 + 50 * Math.sin(f * Math.PI); api.pose(16, -16, a, -a, 0.35, 0.35) },
    // A slide: one leg out straight, the other folded, the arms back for balance (the caller tilts him down).
    slide() { api.pose(78, 18, -50, 30, 0, 0.4) },
    // A keeper's dive: the arms stretched over the head (the caller lays him out towards the ball).
    dive(f) { const a = 60 + 110 * Math.min(1, f * 1.6); api.pose(10, -24, a, -a, 0, 0.2) },
    // [Sprint 33 L1] The keeper: the ball gathered into the chest, then thrown out overarm.
    gather() { api.pose(12, -12, 70, -70) },
    throwOut(f) { const a = f < 0.5 ? 160 : 160 - 220 * (f - 0.5); api.pose(4, -18, 20, -a, 0, 0.2) },
    // [Sprint 33 L2] Down after a foul (the caller lays him on the grass), and the referee's arm raised with a card.
    fallen() { api.pose(30, 50, 120, -40, 0, 0) },
    showCard(colour) { card = colour; api.pose(3, -3, 12, colour ? -168 : -10) },
    // [Sprint 33 L4] Hands on the head after a chance missed, and the head down after a goal conceded.
    handsOnHead() { api.pose(3, -3, 150, -150) },
    hangHead() { api.pose(2, -2, 4, -4) },
    // Arms up, waving.
    celebrate(t) { const w = Math.sin(t * 9) * 12; api.pose(8, -8, 150 + w, -150 - w) },
    /** The figure with its centre at (x, y), turned r degrees, at scale k; shadow false leaves out its own shadow. */
    draw(c, x, y, r, k, shadow = true) {
      c.save(); c.translate(x, y); if (r) c.rotate((r * Math.PI) / 180); c.scale(k * mirror, k)
      // Taller or shorter, his feet stay on the same spot.
      if (bh !== 1) { c.translate(0, 58 * (1 - bh)); c.scale(1, bh) }
      if (shadow) { c.fillStyle = 'rgba(0,0,0,.42)'; c.beginPath(); c.ellipse(0, 58, 17, 4.5, 0, 0, Math.PI * 2); c.fill() }
      leg(c, legs[0]); leg(c, legs[1])
      if (facing === 'side') arm(c, arms[0])
      c.drawImage(sprite(facing), BOX.x * bw, BOX.y, BOX.w * bw, BOX.h)
      if (facing !== 'side') arm(c, arms[0])
      arm(c, arms[1])
      c.restore()
    },
  }
  return api
}
