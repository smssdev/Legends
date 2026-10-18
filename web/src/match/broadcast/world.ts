// @ts-nocheck
// The 3D stadium for the match broadcast (docs/MOMENTS.md 3): pitch, goals with
// rippling nets, stands with an instanced crowd in the clubs' colours, flares,
// flags, floodlights and the offside lines used by the freeze shots.
import * as THREE from 'three'

THREE.ColorManagement.legacyMode = false

export function createWorld(stage) {
  const col = h => new THREE.Color(h)
  let kits = { home: { shirt: '#ffffff', trim: '#cccccc' }, away: { shirt: '#222222', trim: '#999999' } }
// ---------------------------------------------------------------- scene
const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' })
renderer.setPixelRatio(Math.min(window.innerWidth < 800 ? 1.5 : 2, window.devicePixelRatio || 1))
renderer.shadowMap.enabled = true; renderer.shadowMap.type = THREE.PCFSoftShadowMap
renderer.outputEncoding = THREE.sRGBEncoding; renderer.toneMapping = THREE.ACESFilmicToneMapping; renderer.toneMappingExposure = 1.05
stage.prepend(renderer.domElement)
const scene = new THREE.Scene(); scene.background = col('#050B1C'); scene.fog = new THREE.Fog('#050B1C', 120, 260)
const camera = new THREE.PerspectiveCamera(32, 16 / 9, 0.1, 600)
function resize() { const w = stage.clientWidth, h = stage.clientHeight; renderer.setSize(w, h, false); camera.aspect = w / h; camera.updateProjectionMatrix() }
const ro = new ResizeObserver(resize); ro.observe(stage); resize()

scene.add(new THREE.HemisphereLight(0xcfdcff, 0x1b3a20, 0.55))
const sun = new THREE.DirectionalLight(0xfff4e0, 1.35); sun.position.set(-30, 70, 40); sun.castShadow = true
sun.shadow.mapSize.set(2048, 2048); Object.assign(sun.shadow.camera, { left: -70, right: 70, top: 50, bottom: -50, near: 10, far: 200 }); sun.shadow.bias = -0.0004
scene.add(sun)
const fill = new THREE.DirectionalLight(0xbcd0ff, 0.35); fill.position.set(40, 50, -40); scene.add(fill)

// Pitch texture: mown stripes and lines.
function pitchTexture() {
  const c = document.createElement('canvas'), s = 20; c.width = 125 * s; c.height = 88 * s
  const g = c.getContext('2d'), ox = 10 * s, oy = 10 * s
  g.fillStyle = '#1C7A3A'; g.fillRect(0, 0, c.width, c.height)
  for (let i = 0; i < 14; i++) { g.fillStyle = i % 2 ? '#238C44' : '#2A9A4C'; g.fillRect(ox + i * 7.5 * s, oy, 7.5 * s, 68 * s) }
  for (let k = 0; k < 4000; k++) { g.fillStyle = `rgba(0,0,0,${Math.random() * 0.05})`; g.fillRect(Math.random() * c.width, Math.random() * c.height, 3, 3) }
  g.strokeStyle = 'rgba(255,255,255,0.92)'; g.lineWidth = 0.14 * s
  const R = (x, y, w, h) => g.strokeRect(ox + x * s, oy + y * s, w * s, h * s)
  R(0, 0, 105, 68); R(0, 13.84, 16.5, 40.32); R(88.5, 13.84, 16.5, 40.32); R(0, 24.84, 5.5, 18.32); R(99.5, 24.84, 5.5, 18.32)
  g.beginPath(); g.moveTo(ox + 52.5 * s, oy); g.lineTo(ox + 52.5 * s, oy + 68 * s); g.stroke()
  g.beginPath(); g.arc(ox + 52.5 * s, oy + 34 * s, 9.15 * s, 0, 7); g.stroke()
  g.beginPath(); g.arc(ox + 11 * s, oy + 34 * s, 9.15 * s, -0.93, 0.93); g.stroke()
  g.beginPath(); g.arc(ox + 94 * s, oy + 34 * s, 9.15 * s, Math.PI - 0.93, Math.PI + 0.93); g.stroke()
  g.fillStyle = '#fff'; for (const x of [11, 94, 52.5]) { g.beginPath(); g.arc(ox + x * s, oy + 34 * s, 0.25 * s, 0, 7); g.fill() }
  const t = new THREE.CanvasTexture(c); t.encoding = THREE.sRGBEncoding; t.anisotropy = 8; return t
}
const pitch = new THREE.Mesh(new THREE.PlaneGeometry(125, 88), new THREE.MeshStandardMaterial({ map: pitchTexture(), roughness: 0.95 }))
pitch.rotation.x = -Math.PI / 2; pitch.receiveShadow = true; scene.add(pitch)

// Goals with nets that ripple.
const nets = []
function goal(xSide) {
  const grp = new THREE.Group(), m = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.4 })
  const post = (x, y, z, h, rx) => { const p = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.06, h, 12), m); p.position.set(x, y, z); if (rx) p.rotation.x = Math.PI / 2; p.castShadow = true; grp.add(p) }
  post(0, 1.22, -3.66, 2.44); post(0, 1.22, 3.66, 2.44); post(0, 2.44, 0, 7.32, true)
  const geo = new THREE.PlaneGeometry(2, 7.32, 10, 30), net = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({ color: 0xffffff, wireframe: true, transparent: true, opacity: 0.55 }))
  net.position.set(xSide * 1, 1.22, 0); net.rotation.y = Math.PI / 2; net.rotation.z = 0
  const back = new THREE.Mesh(new THREE.PlaneGeometry(7.32, 2.44, 30, 10), net.material); back.position.set(xSide * 2, 1.22, 0); back.rotation.y = Math.PI / 2
  const roof = new THREE.Mesh(new THREE.PlaneGeometry(2, 7.32, 8, 30), net.material); roof.rotation.x = -Math.PI / 2; roof.rotation.z = Math.PI / 2; roof.position.set(xSide, 2.44, 0)
  grp.add(back, roof); grp.position.x = xSide > 0 ? 52.5 : -52.5
  back.userData.base = back.geometry.attributes.position.array.slice(); nets.push({ mesh: back, side: xSide })
  scene.add(grp)
}
goal(1); goal(-1)

// Stands with an instanced crowd in the home colours.
const crowd = { mesh: null, base: [], n: 0 }
function stands() {
  const mat = new THREE.MeshStandardMaterial({ color: '#16233F', roughness: 0.9 })
  const boards = new THREE.MeshStandardMaterial({ color: '#0E2A57', emissive: '#0E2A57', emissiveIntensity: 0.6 })
  const add = (w, d, x, z, ry) => { const s = new THREE.Mesh(new THREE.BoxGeometry(w, 1, d), mat); s.position.set(x, -0.4, z); s.rotation.y = ry; scene.add(s) }
  // Stepped tiers: far side, both ends, near side.
  const tiers = []
  for (let r = 0; r < 14; r++) {
    tiers.push([0, -(39 + r * 1.3), 1 + r * 0.95, 130, 0])
    tiers.push([0, 39 + r * 1.3, 1 + r * 0.95, 130, 0])
    tiers.push([-(60 + r * 1.3), 0, 1 + r * 0.95, 80, Math.PI / 2])
    tiers.push([60 + r * 1.3, 0, 1 + r * 0.95, 80, Math.PI / 2])
  }
  const geo = new THREE.CylinderGeometry(0.2, 0.17, 0.62, 8)
  const fanMat = new THREE.MeshStandardMaterial({ roughness: 0.8 })
  const pos = []
  for (const [x, z, y, len, ry] of tiers) {
    const step = new THREE.Mesh(new THREE.BoxGeometry(len, 0.95, 1.3), mat); step.position.set(x, y - 0.48, z); step.rotation.y = ry; scene.add(step)
    for (let i = -len / 2 + 0.4; i < len / 2; i += 0.55) if (Math.random() < 0.86) pos.push(ry ? [x, y + 0.31, z + i] : [x + i, y + 0.31, z])
  }
  crowd.n = pos.length
  crowd.mesh = new THREE.InstancedMesh(geo, fanMat, crowd.n)
  crowd.heads = new THREE.InstancedMesh(new THREE.SphereGeometry(0.13, 10, 8), new THREE.MeshStandardMaterial({ roughness: 0.7 }), crowd.n)
  const m = new THREE.Matrix4(), skin = ['#F1C9A5', '#E0AC82', '#C68B59', '#8D5524', '#6B3E1E'], c = new THREE.Color()
  pos.forEach((p, i) => { m.makeTranslation(p[0], p[1], p[2]); crowd.mesh.setMatrixAt(i, m); m.makeTranslation(p[0], p[1] + 0.44, p[2]); crowd.heads.setMatrixAt(i, m); crowd.heads.setColorAt(i, c.set(skin[i % 5])); crowd.base.push({ p, k: Math.random() }) })
  scene.add(crowd.mesh, crowd.heads)
  // Ad boards around the pitch.
  const cv = document.createElement('canvas'); cv.width = 1024; cv.height = 64; const g = cv.getContext('2d'); g.fillStyle = '#0E2A57'; g.fillRect(0, 0, 1024, 64); g.fillStyle = '#F5B82E'; g.font = '700 44px "Barlow Condensed", sans-serif'; for (let x = 20; x < 1024; x += 256) g.fillText('LEGENDS', x, 48)
  const tex = new THREE.CanvasTexture(cv); tex.wrapS = THREE.RepeatWrapping; tex.repeat.set(6, 1); tex.encoding = THREE.sRGBEncoding
  const bm = new THREE.MeshStandardMaterial({ map: tex, emissive: '#ffffff', emissiveMap: tex, emissiveIntensity: 0.5 })
  for (const [w, x, z, ry] of [[110, 0, -36.5, 0], [110, 0, 38.6, 0], [70, -56, 0, Math.PI / 2], [70, 56, 0, Math.PI / 2]]) { const b = new THREE.Mesh(new THREE.BoxGeometry(w, 0.9, 0.12), bm); b.position.set(x, 0.45, z); b.rotation.y = ry; scene.add(b) }
  // Floodlight towers.
  for (const [x, z] of [[-62, -44], [62, -44], [-62, 44], [62, 44]]) {
    const pole = new THREE.Mesh(new THREE.CylinderGeometry(0.5, 0.7, 34, 8), mat); pole.position.set(x, 17, z); scene.add(pole)
    const panel = new THREE.Mesh(new THREE.BoxGeometry(7, 4, 0.5), new THREE.MeshBasicMaterial({ color: '#FFF6D8' })); panel.position.set(x, 35, z); panel.lookAt(0, 0, 0); scene.add(panel)
  }
  // Benches on the near side.
  for (const x of [-8, 8]) { const b = new THREE.Mesh(new THREE.BoxGeometry(9, 2.2, 2), new THREE.MeshStandardMaterial({ color: '#0D1424', transparent: true, opacity: 0.85 })); b.position.set(x, 1.1, 39.5); scene.add(b) }
}

// Ball.
function ballTexture() {
  const c = document.createElement('canvas'); c.width = 256; c.height = 128; const g = c.getContext('2d')
  g.fillStyle = '#fff'; g.fillRect(0, 0, 256, 128); g.fillStyle = '#16233F'
  for (let i = 0; i < 12; i++) { const x = (i % 6) * 44 + (i > 5 ? 22 : 0), y = i > 5 ? 86 : 38; g.beginPath(); for (let k = 0; k < 5; k++) { const a = k / 5 * Math.PI * 2; g.lineTo(x + Math.cos(a) * 12, y + Math.sin(a) * 12) } g.fill() }
  const t = new THREE.CanvasTexture(c); t.encoding = THREE.sRGBEncoding; return t
}
const ball = new THREE.Mesh(new THREE.SphereGeometry(0.11, 24, 16), new THREE.MeshStandardMaterial({ map: ballTexture(), roughness: 0.45 }))
ball.castShadow = true; scene.add(ball)


// ------------------------------------------------------------------ 3D world helpers
const W3 = (x, y, h = 0) => new THREE.Vector3(x - 52.5, h, y - 34)
const AWAY_END = p => p[0] > 58

function colorCrowd() {
  const T = kits, c = new THREE.Color()
  crowd.base.forEach((f, i) => {
    const k = AWAY_END(f.p) ? T.away : T.home
    c.set(f.k < 0.5 ? k.shirt : f.k < 0.72 ? (k.stripe || k.trim) : f.k < 0.86 ? '#2A3A5E' : '#E9E3D2')
    crowd.mesh.setColorAt(i, c)
  })
  crowd.mesh.instanceColor.needsUpdate = true
}
function moveCrowd(t, mood, section) {
  if (!crowd.mesh) return
  const m = new THREE.Matrix4()
  crowd.base.forEach((f, i) => {
    const inSec = section === null ? false : (section === 'away') === AWAY_END(f.p)
    let j = Math.sin(t * 2 + f.k * 9) * 0.02
    if (inSec && mood === 'jump') j = Math.max(0, Math.sin(t * 9 + f.k * 30)) * 0.5
    else if (inSec && mood === 'groan') j = -0.18
    else if (inSec && mood === 'quiet') j = 0
    m.makeTranslation(f.p[0], f.p[1] + j, f.p[2]); crowd.mesh.setMatrixAt(i, m)
    m.makeTranslation(f.p[0], f.p[1] + j + 0.44, f.p[2]); crowd.heads.setMatrixAt(i, m)
  })
  crowd.mesh.instanceMatrix.needsUpdate = true; crowd.heads.instanceMatrix.needsUpdate = true
}

// Flares and flags for the crowd cutaways.
function glowTexture(inner, outer) {
  const c = document.createElement('canvas'); c.width = c.height = 128; const g = c.getContext('2d')
  const rg = g.createRadialGradient(64, 64, 0, 64, 64, 64); rg.addColorStop(0, inner); rg.addColorStop(1, outer); g.fillStyle = rg; g.fillRect(0, 0, 128, 128)
  return new THREE.CanvasTexture(c)
}
const flareTex = glowTexture('rgba(255,170,70,1)', 'rgba(255,80,20,0)')
const flares = []
for (let i = 0; i < 10; i++) {
  const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: flareTex, blending: THREE.AdditiveBlending, depthWrite: false, transparent: true }))
  s.scale.set(3, 3, 1); s.visible = false; scene.add(s); flares.push(s)
}
const flags = []
for (let i = 0; i < 4; i++) {
  const geo = new THREE.PlaneGeometry(3.2, 2, 16, 6)
  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({ side: THREE.DoubleSide, roughness: 0.8 }))
  mesh.userData.base = geo.attributes.position.array.slice(); mesh.visible = false; scene.add(mesh); flags.push(mesh)
}
function sectionFx(t, section, mood) {
  const T = kits, k = section === 'away' ? T.away : T.home
  flares.forEach((s, i) => {
    s.visible = mood === 'jump'
    if (!s.visible) return
    const p = section === 'away' ? new THREE.Vector3(64 + (i % 3) * 3, 4 + (i % 4) * 2.2, -20 + i * 4.4) : new THREE.Vector3(-22 + i * 4.6, 4 + (i % 4) * 2.2, -44 - (i % 3) * 3)
    s.position.copy(p); const fl = 2.4 + Math.sin(t * 30 + i * 7) * 0.5; s.scale.set(fl, fl, 1)
  })
  flags.forEach((f, i) => {
    f.visible = section !== null && mood !== 'quiet'
    if (!f.visible) return
    f.material.color.set(i % 2 ? k.shirt : (k.stripe || k.trim))
    if (section === 'away') { f.position.set(62.5 + i * 0.4, 9 + (i % 2) * 3, -12 + i * 8); f.rotation.y = -Math.PI / 2 }
    else { f.position.set(-16 + i * 9, 9 + (i % 2) * 3, -42.5); f.rotation.y = 0 }
    const arr = f.geometry.attributes.position.array, b = f.userData.base
    for (let j = 0; j < arr.length; j += 3) arr[j + 2] = b[j + 2] + Math.sin(t * 6 + b[j] * 2 + i) * 0.18 * (b[j] + 1.6)
    f.geometry.attributes.position.needsUpdate = true
  })
}

// Offside lines for the freeze and VAR shots.
const offLines = [0, 1].map(() => { const m = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.02, 70), new THREE.MeshBasicMaterial({ color: 0xffffff })); m.visible = false; scene.add(m); return m })


  stands()
  function setKits(k) { kits = k; colorCrowd() }
  function dispose() { ro.disconnect(); renderer.dispose(); renderer.domElement.remove() }
  return { THREE, renderer, scene, camera, ball, nets, crowd, W3, moveCrowd, sectionFx, offLines, setKits, dispose }
}
