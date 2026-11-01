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
    c.fillStyle = 'rgba(0,0,0,.08)'; c.fill(P.fold)
    c.strokeStyle = trim; c.lineWidth = 2; c.stroke(P.collar)
    c.fillStyle = ink; c.textAlign = 'center'
    if (f === 'back') { c.font = '800 18px "Barlow Condensed", Amin, sans-serif'; c.fillText(String(no ?? ''), 0, 12) }
    if (f === 'front') { c.font = '800 8px "Barlow Condensed", Amin, sans-serif'; c.fillText(String(no ?? ''), 6, 4) }
    c.restore()
    c.fillStyle = skin; c.fillRect(-3.4, -15, 6.8, 7); dot(c, 0, -21, 9.4, skin)
    c.fillStyle = hair
    if (f === 'back') c.fill(P.hairBack)
    if (f === 'front') { c.fill(P.hairFront); dot(c, -3.4, -21, 1.3, '#141414'); dot(c, 3.4, -21, 1.3, '#141414'); c.strokeStyle = 'rgba(60,20,10,.6)'; c.lineWidth = 1; c.stroke(P.mouth) }
    if (f === 'side') { c.fill(P.hairSide); dot(c, 4.6, -22, 1.3, '#141414'); c.fillStyle = skin; c.fill(P.nose) }
    return (sprites[f] = cv)
  }
  let facing = 'back', mirror = 1
  const legs = [{ x: -6, r: 3, lift: 0 }, { x: 6, r: -3, lift: 0 }], arms = [{ x: -14.5, r: 10 }, { x: 14.5, r: -10 }]
  function leg(c, l) {
    c.save(); c.translate(l.x * (facing === 'side' ? 0.45 : 1), 25); c.rotate((l.r * Math.PI) / 180); c.scale(1, 1 - 0.45 * l.lift)
    c.fillStyle = skin; rr(c, -4.5, 0, 9, 15, 3.5)
    c.fillStyle = socks; rr(c, -4.6, 12, 9.2, 16, 3.5)
    c.fillStyle = '#0B0F1A'; c.fill(P.boot)
    c.restore()
  }
  function arm(c, a) {
    c.save(); c.translate(a.x * (facing === 'side' ? 0.12 : 1), -7); c.rotate((a.r * Math.PI) / 180)
    c.fillStyle = kit; rr(c, -4, 0, 8, 12, 3.5)
    c.fillStyle = o.gloves ? kit : skin; rr(c, -3.4, 10, 6.8, 13, 3.4)
    if (o.gloves) { c.fillStyle = o.gloves; rr(c, -5, 20, 10, 9, 3.5) }
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
    /** The figure with its centre at (x, y), turned r degrees, at scale k; shadow false leaves out its own shadow. */
    draw(c, x, y, r, k, shadow = true) {
      c.save(); c.translate(x, y); if (r) c.rotate((r * Math.PI) / 180); c.scale(k * mirror, k)
      if (shadow) { c.fillStyle = 'rgba(0,0,0,.42)'; c.beginPath(); c.ellipse(0, 58, 17, 4.5, 0, 0, Math.PI * 2); c.fill() }
      leg(c, legs[0]); leg(c, legs[1])
      if (facing === 'side') arm(c, arms[0])
      c.drawImage(sprite(facing), BOX.x, BOX.y, BOX.w, BOX.h)
      if (facing !== 'side') arm(c, arms[0])
      arm(c, arms[1])
      c.restore()
    },
  }
  return api
}
