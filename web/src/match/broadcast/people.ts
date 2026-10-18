// @ts-nocheck
// Our match characters (docs/MOMENTS.md 1): rounded cartoon footballers built
// from primitives, every pose a handful of joint angles. No external models.
import * as THREE from 'three'

// ------------------------------------------------------------------ our players (built from primitives, animated in code)
// A V-shaped chest: narrow waist, broad shoulders, rounded top.
const chestProfile = [[0.001, 0], [0.155, 0], [0.165, 0.08], [0.18, 0.2], [0.2, 0.34], [0.215, 0.44], [0.205, 0.5], [0.16, 0.56], [0.07, 0.585], [0.001, 0.59]].map(([x, y]) => new THREE.Vector2(x, y))
const GEO = {
  shorts: new THREE.CylinderGeometry(0.165, 0.185, 0.26, 18), thigh: new THREE.CapsuleGeometry(0.068, 0.34, 4, 12), shin: new THREE.CapsuleGeometry(0.052, 0.36, 4, 12),
  boot: new THREE.CapsuleGeometry(0.048, 0.15, 4, 10), chest: new THREE.LatheGeometry(chestProfile, 24), neck: new THREE.CylinderGeometry(0.052, 0.06, 0.1, 12),
  head: new THREE.SphereGeometry(0.1, 24, 18), jaw: new THREE.SphereGeometry(0.075, 18, 12), nose: new THREE.ConeGeometry(0.016, 0.04, 8), ear: new THREE.SphereGeometry(0.022, 10, 8),
  hair: new THREE.SphereGeometry(0.106, 24, 12, 0, Math.PI * 2, 0, Math.PI * 0.5), eye: new THREE.SphereGeometry(0.011, 8, 6), brow: new THREE.BoxGeometry(0.035, 0.008, 0.01),
  shoulder: new THREE.SphereGeometry(0.072, 14, 10), sleeve: new THREE.CylinderGeometry(0.068, 0.058, 0.15, 14), upper: new THREE.CapsuleGeometry(0.047, 0.22, 4, 10), fore: new THREE.CapsuleGeometry(0.041, 0.2, 4, 10),
  hand: new THREE.SphereGeometry(0.047, 12, 10), collar: new THREE.TorusGeometry(0.068, 0.014, 8, 20), card: new THREE.BoxGeometry(0.075, 0.105, 0.006),
}
const texCache = {}
function shirtTexture(kit, no) {
  const key = [kit.shirt, kit.stripe, kit.bands, kit.text, no].join('|')
  if (texCache[key]) return texCache[key]
  const c = document.createElement('canvas'); c.width = 512; c.height = 256; const g = c.getContext('2d')
  g.fillStyle = kit.shirt; g.fillRect(0, 0, 512, 256)
  if (kit.stripe) { g.fillStyle = kit.stripe; for (let x = 0; x < 512; x += 64) g.fillRect(x, 0, 32, 256) }
  if (kit.bands) { g.fillStyle = kit.bands; g.fillRect(0, 70, 512, 18); g.fillRect(0, 100, 512, 18) }
  // Fabric shading so the shirt is not flat.
  const sh = g.createLinearGradient(0, 0, 0, 256); sh.addColorStop(0, 'rgba(255,255,255,0.08)'); sh.addColorStop(1, 'rgba(0,0,0,0.18)'); g.fillStyle = sh; g.fillRect(0, 0, 512, 256)
  if (no) {
    g.font = '700 120px "Barlow Condensed", "Arial Narrow", sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle'
    g.lineWidth = 8; g.strokeStyle = 'rgba(0,0,0,0.25)'; g.strokeText(String(no), 256, 132)
    g.fillStyle = kit.text; g.fillText(String(no), 256, 132)
  }
  const t = new THREE.CanvasTexture(c); t.encoding = THREE.sRGBEncoding; t.anisotropy = 4
  return (texCache[key] = t)
}
function numberTexture(kit, no) {
  const key = 'n|' + kit.text + '|' + no
  if (texCache[key]) return texCache[key]
  const c = document.createElement('canvas'); c.width = c.height = 128; const g = c.getContext('2d')
  g.font = '700 110px "Barlow Condensed", "Arial Narrow", sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle'
  g.lineWidth = 6; g.strokeStyle = 'rgba(0,0,0,0.25)'; g.strokeText(String(no), 64, 70); g.fillStyle = kit.text; g.fillText(String(no), 64, 70)
  const t = new THREE.CanvasTexture(c); t.encoding = THREE.sRGBEncoding
  return (texCache[key] = t)
}
const std = (color, extra) => new THREE.MeshStandardMaterial(Object.assign({ color, roughness: 0.75, metalness: 0.02 }, extra))

export function makePerson(kit, o = {}) {
  const root = new THREE.Group(), body = new THREE.Group(); root.add(body)
  const skin = std(o.skin, { roughness: 0.6 }), M = {
    shirt: std('#ffffff', { map: shirtTexture(kit, null) }), sleeve: std(kit.shirt), shorts: std(kit.shorts), socks: std(kit.socks),
    boot: std(o.boot || '#111111', { roughness: 0.4 }), hair: std(o.hair, { roughness: 0.9 }), trim: std(kit.trim || kit.text), dark: std('#151515'),
  }
  const detail = []
  const mesh = (geo, mat, parent, x = 0, y = 0, z = 0) => { const m = new THREE.Mesh(geo, mat); m.position.set(x, y, z); m.castShadow = geo !== GEO.eye && geo !== GEO.brow && geo !== GEO.nose && geo !== GEO.ear && geo !== GEO.hand && geo !== GEO.collar; if (!m.castShadow) detail.push(m); parent.add(m); return m }
  const hips = new THREE.Group(); hips.position.y = 0.93; body.add(hips)
  mesh(GEO.shorts, M.shorts, hips, 0, -0.03).scale.z = 0.78
  const legs = {}, knees = {}
  for (const [side, x] of [['L', 0.095], ['R', -0.095]]) {
    const leg = new THREE.Group(); leg.position.set(x, -0.05, 0); hips.add(leg)
    mesh(GEO.thigh, o.suit ? M.shorts : skin, leg, 0, -0.215)
    const knee = new THREE.Group(); knee.position.y = -0.43; leg.add(knee)
    mesh(GEO.shin, o.suit ? M.shorts : M.socks, knee, 0, -0.215)
    mesh(GEO.boot, M.boot, knee, 0, -0.45, 0.045).rotation.x = Math.PI / 2
    legs[side] = leg; knees[side] = knee
  }
  const torso = new THREE.Group(); torso.position.y = 0.0; hips.add(torso)
  const chest = mesh(GEO.chest, M.shirt, torso, 0, 0); chest.scale.z = 0.62
  if (o.no) { const num = new THREE.Mesh(new THREE.PlaneGeometry(0.2, 0.2), new THREE.MeshStandardMaterial({ map: numberTexture(kit, o.no), transparent: true, roughness: 0.8 })); num.position.set(0, 0.34, -0.136); num.rotation.y = Math.PI; torso.add(num) }
  mesh(GEO.collar, M.trim, torso, 0, 0.575).rotation.x = Math.PI / 2
  if (o.scarf) { mesh(new THREE.BoxGeometry(0.07, 0.42, 0.03), std(o.scarf), torso, 0.05, 0.36, 0.135); mesh(new THREE.BoxGeometry(0.07, 0.42, 0.03), std(o.scarf2 || o.scarf), torso, -0.05, 0.36, 0.135) }
  mesh(GEO.neck, skin, torso, 0, 0.62)
  const head = new THREE.Group(); head.position.y = 0.745; torso.add(head)
  mesh(GEO.head, skin, head).scale.set(0.92, 1.05, 1)
  mesh(GEO.jaw, skin, head, 0, -0.045, 0.018).scale.set(0.95, 0.85, 1)
  mesh(GEO.nose, skin, head, 0, -0.005, 0.1).rotation.x = Math.PI / 2
  for (const ex of [-0.09, 0.09]) mesh(GEO.ear, skin, head, ex, 0, 0).scale.set(0.5, 1, 0.8)
  const hair = mesh(GEO.hair, M.hair, head, 0, 0.018, -0.01); hair.scale.set(0.97, 1.0, 1.04)
  for (const ex of [-0.034, 0.034]) { mesh(GEO.eye, M.dark, head, ex, 0.018, 0.088); mesh(GEO.brow, M.hair, head, ex, 0.042, 0.088) }
  const arms = {}, elbows = {}, hands = {}
  for (const [side, x] of [['L', 0.205], ['R', -0.205]]) {
    mesh(GEO.shoulder, M.sleeve, torso, x * 0.98, 0.49).scale.set(1, 0.9, 0.85)
    const arm = new THREE.Group(); arm.position.set(x, 0.49, 0); torso.add(arm)
    mesh(GEO.sleeve, M.sleeve, arm, 0, -0.07)
    mesh(GEO.upper, o.longSleeve ? M.sleeve : skin, arm, 0, -0.16)
    const elbow = new THREE.Group(); elbow.position.y = -0.29; arm.add(elbow)
    mesh(GEO.fore, o.longSleeve ? M.sleeve : skin, elbow, 0, -0.13)
    const hand = new THREE.Group(); hand.position.y = -0.27; elbow.add(hand)
    mesh(GEO.hand, o.gloves ? std(o.gloves) : skin, hand)
    arms[side] = arm; elbows[side] = elbow; hands[side] = hand
  }
  const card = mesh(GEO.card, std('#FFD400', { emissive: '#FFD400', emissiveIntensity: 0.6 }), hands.R, 0, -0.07, 0.02); card.visible = false
  const flag = new THREE.Group(); hands.L.add(flag); flag.visible = false
  mesh(new THREE.CylinderGeometry(0.008, 0.008, 0.55), std('#dddddd'), flag, 0, -0.2)
  const cloth = mesh(new THREE.PlaneGeometry(0.34, 0.24), std('#F2C230', { side: THREE.DoubleSide }), flag, 0.17, -0.38); cloth.rotation.y = Math.PI / 2
  return { root, body, hips, torso, head, legs, knees, arms, elbows, hands, card, flag, M, detail, near: true, phase: 0 }
}

// Every pose is a few joint angles. Legs point down; +x on a leg swings the foot back, -x forward.
export function animate(p, speed, phase, pose, pt, side, cardColor) {
  const { legs, knees, arms, elbows, torso, body, root, hips } = p
  for (const g of [legs.L, legs.R, knees.L, knees.R, arms.L, arms.R, elbows.L, elbows.R, torso, body]) g.rotation.set(0, 0, 0)
  body.position.set(0, 0, 0); hips.position.y = 0.93
  p.card.visible = false; p.flag.visible = false
  let A = speed > 3 ? Math.min(1, 0.6 + speed * 0.05) : speed > 0.5 ? 0.42 : 0
  if (pose === 'walk') A = 0.38
  const s = Math.sin(phase)
  legs.L.rotation.x = s * A * 0.95; legs.R.rotation.x = -s * A * 0.95
  knees.L.rotation.x = A * 1.25 * (0.5 + 0.5 * Math.sin(phase + 2.2)); knees.R.rotation.x = A * 1.25 * (0.5 - 0.5 * Math.sin(phase + 2.2))
  arms.L.rotation.x = -s * A * 0.85; arms.R.rotation.x = s * A * 0.85; arms.L.rotation.z = 0.1; arms.R.rotation.z = -0.1
  elbows.L.rotation.x = elbows.R.rotation.x = -1.0 * A - 0.15
  torso.rotation.x = 0.16 * A; hips.position.y = 0.93 + Math.abs(Math.cos(phase)) * 0.045 * A
  const up = (l, r) => { arms.L.rotation.set(0, 0, l); arms.R.rotation.set(0, 0, -r); elbows.L.rotation.set(0, 0, 0); elbows.R.rotation.set(0, 0, 0) }
  switch (pose) {
    case 'kick': { const k = Math.sin(Math.min(1, pt / 0.22) * Math.PI); legs.R.rotation.x = -1.45 * k + 0.35 * (1 - k); knees.R.rotation.x = 0.2 + 0.6 * (1 - k); legs.L.rotation.x = 0.2; knees.L.rotation.x = 0.25; arms.L.rotation.set(-0.7, 0, 0.5); arms.R.rotation.set(0.3, 0, -0.7); torso.rotation.x = -0.12 * k; break }
    case 'celebrate': { const w = Math.sin(pt * 7) * 0.22; up(2.75 + w, 2.75 - w); body.position.y = Math.abs(Math.sin(pt * 6)) * 0.28; break }
    case 'run-arms': up(2.6, 2.6); break
    case 'head': up(2.55, 2.55); elbows.L.rotation.z = -2.1; elbows.R.rotation.z = 2.1; torso.rotation.x = 0.1; break
    case 'argue': arms.L.rotation.set(-0.6, 0, 1.1); arms.R.rotation.set(-0.6, 0, -1.1); elbows.L.rotation.x = elbows.R.rotation.x = -0.5; break
    case 'shout': arms.R.rotation.set(-1.55 + Math.sin(pt * 10) * 0.15, 0, -0.1); elbows.R.rotation.x = 0; arms.L.rotation.set(0, 0, 0.15); torso.rotation.x = 0.12; break
    case 'point': arms.R.rotation.set(-1.5, 0, -0.25); elbows.R.rotation.x = 0; arms.L.rotation.set(0, 0, 0.1); elbows.L.rotation.x = 0; break
    case 'clap': { const c = Math.abs(Math.sin(pt * 9)) * 0.35; arms.L.rotation.set(-1.15, 0, -0.25 + c); arms.R.rotation.set(-1.15, 0, 0.25 - c); elbows.L.rotation.x = elbows.R.rotation.x = -0.5; break }
    case 'ear': arms.R.rotation.set(0, 0, -2.4); elbows.R.rotation.set(0, 0, 2.3); arms.L.rotation.set(0, 0, 0.12); elbows.L.rotation.x = 0; break
    case 'card': arms.R.rotation.set(0, 0, -3.02); elbows.R.rotation.set(0, 0, 0); arms.L.rotation.set(0, 0, 0.12); elbows.L.rotation.x = 0; p.card.visible = true; p.card.material.color.set(cardColor); p.card.material.emissive.set(cardColor); break
    case 'flag': arms.L.rotation.set(0, 0, 2.7); elbows.L.rotation.set(0, 0, 0); p.flag.visible = true; break
    case 'jump': { const k = Math.sin(Math.min(1, pt / 0.45) * Math.PI); body.position.y = k * 0.55; legs.L.rotation.x = -0.3; legs.R.rotation.x = 0.2; knees.L.rotation.x = knees.R.rotation.x = 0.7; up(1.2, 1.2); torso.rotation.x = -0.25 * k; break }
    case 'slide': body.rotation.x = -0.9; body.position.y = 0.18; legs.R.rotation.x = -1.35; knees.R.rotation.x = 0.1; legs.L.rotation.x = -0.4; knees.L.rotation.x = 1.3; arms.L.rotation.set(0.4, 0, 0.9); arms.R.rotation.set(0.4, 0, -0.9); break
    case 'fall': { const k = Math.min(1, pt * 4); body.rotation.x = 1.42 * k; body.position.y = 0.12 * k; arms.L.rotation.set(-2.4 * k, 0, 0.3); arms.R.rotation.set(-2.4 * k, 0, -0.3); legs.L.rotation.x = legs.R.rotation.x = 0.2; break }
    case 'dive': case 'down': {
      const k = pose === 'dive' ? Math.min(1, pt / 0.32) : 1
      body.rotation.z = side * 1.38 * k
      body.position.y = pose === 'dive' ? Math.sin(Math.min(1, pt / 0.75) * Math.PI) * 0.75 + 0.22 * k : 0.2
      up(2.9, 2.9); legs.L.rotation.set(0, 0, 0.15); legs.R.rotation.set(0, 0, -0.1); knees.L.rotation.x = 0.2; break
    }
  }
}


/** Hides the small face and hand parts when the camera is far: fewer draw calls on phones. */
export function setNear(p, near) {
  if (p.near === near) return
  p.near = near
  for (const m of p.detail) if (m !== p.card) m.visible = near
}
