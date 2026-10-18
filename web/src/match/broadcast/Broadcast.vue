<template>
  <div ref="host" class="absolute inset-0 overflow-hidden bg-bg-deep" style="container-type: inline-size">
    <div class="hud" dir="rtl">
      <canvas ref="mini" class="mini" :class="{ on: hud.mini }" />
      <div v-if="hud.mini" class="mm">
        <span class="mm-min font-numbers">{{ hud.miniMinute }}</span>
        <span v-if="hud.miniLabel" class="mm-label" :style="{ background: hud.miniLabel.color, color: hud.miniLabel.text }">{{ hud.miniLabel.t }}</span>
      </div>
      <div class="scan" :class="{ on: hud.frozen }" />
      <div class="tag" :class="{ on: hud.tag }" :style="hud.tag ? { background: hud.tag.bg, color: hud.tag.fg } : {}">{{ hud.tag?.text }}</div>
      <div class="big" :class="{ on: hud.big, small: hud.big?.small }" :style="{ '--glow': hud.big?.glow }">{{ hud.big?.text }}</div>
      <div class="lower" :class="{ on: hud.banner }" :style="{ '--kit': hud.banner?.accent }">
        <small v-if="hud.banner?.top">{{ hud.banner.top }}</small><b>{{ hud.banner?.title }}</b><span>{{ hud.banner?.sub }}</span>
      </div>
      <div class="lower" :class="{ on: hud.label }" :style="{ '--kit': hud.label?.accent }"><b>{{ hud.label?.title }}</b><span>{{ hud.label?.sub }}</span></div>
      <div class="badge slow" :class="{ on: hud.slow }">حركة بطيئة</div>
      <div class="badge replay" :class="{ on: hud.replay }">إعادة</div>
      <div class="badge freeze" :class="{ on: hud.freeze }">{{ hud.freeze }}</div>
      <div v-for="(l, i) in hud.lines" :key="i" class="ol" :style="{ left: l.x + '%', top: l.y + '%', background: l.color }">{{ l.text }}</div>
      <svg class="whistle" :class="{ on: hud.whistle }" :style="hud.whistle ? { left: hud.whistle.x + '%', top: hud.whistle.y + '%' } : {}" viewBox="0 0 64 44" aria-hidden="true"><rect x="6" y="18" width="30" height="18" rx="9" fill="#F5B82E" /><rect x="30" y="21" width="16" height="8" fill="#F5B82E" /><path d="M14 12a16 16 0 0 1 20 0M9 6a24 24 0 0 1 30 0" stroke="#F5B82E" stroke-width="3" fill="none" stroke-linecap="round" /></svg>
      <div class="wipe" :class="{ on: hud.wipe }" :style="hud.wipe ? { transform: `translateX(${hud.wipe.x}%) skewX(-18deg)`, background: hud.wipe.color } : {}" />
    </div>
  </div>
</template>

<script setup lang="ts">
// @ts-nocheck
// The match broadcast (docs/MOMENTS.md): a 3D stadium where every minute plays
// the shot the director picked for it. The parent calls play(tick) per minute.
import { onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { createWorld } from './world'
import { animate, makePerson, setNear } from './people'
import { direct, lerpKeys } from './director'

const props = defineProps<{ kits: any; teams: any; seed: number; speed: number; minute: string }>()
const emit = defineEmits<{ cue: [name: string]; sound: [name: string] }>()
const host = ref<HTMLDivElement>()
const mini = ref<HTMLCanvasElement>()
const hud = reactive<any>({})

let W = null, raf = 0, last = 0, t = 0, script = null, fired = new Set(), dirHome = 1, tickMinute = ''
const people = new Map()
const extras = {}
const SKIN = ['#F1C9A5', '#E0AC82', '#C68B59', '#8D5524', '#6B3E1E', '#D9A066']
const HAIR = ['#1B1B1B', '#3B2A1A', '#6B4423', '#C9A35C', '#111111', '#2A1C12']
const REF = { shirt: '#14171F', shorts: '#14171F', socks: '#14171F', text: '#F5B82E', trim: '#F5B82E' }
const hash = (s) => { let h = 7; for (const c of String(s)) h = (h * 31 + c.charCodeAt(0)) >>> 0; return h }

// ---------------------------------------------------------------- cast
function kitOf(side, gk) {
  const k = props.kits[side]
  return gk ? { shirt: k.gk, shorts: '#1B2233', socks: k.gk, text: '#F7F4EA', trim: '#F7F4EA' } : k
}
function person(id, side, info) {
  let p = people.get(id)
  if (p) return p
  const look = side === 'ref' || side === 'lin' ? { skin: SKIN[1], hair: HAIR[0] } : { skin: SKIN[hash(id) % 6], hair: HAIR[(hash(id) >> 3) % 6] }
  const gk = info?.slot_line === 'gk'
  p = makePerson(side === 'ref' || side === 'lin' ? REF : kitOf(side, gk), { no: info?.no, ...look, longSleeve: gk, gloves: gk ? '#F2F2F2' : null })
  W.scene.add(p.root); people.set(id, p)
  return p
}
let boardTex = null, boardCtx = null
function buildExtras() {
  const suit = (k) => ({ shirt: '#1C2333', shorts: '#1C2333', socks: '#111', text: '#1C2333', trim: k.shirt })
  for (const side of ['home', 'away']) {
    const k = props.kits[side], x = side === 'home' ? 46 : 59
    extras['coach-' + side] = { pos: [x, 70.0], p: makePerson(suit(k), { skin: SKIN[side === 'home' ? 1 : 3], hair: HAIR[side === 'home' ? 4 : 2], scarf: k.shirt, scarf2: k.stripe || k.trim, longSleeve: true }) }
    for (let i = 0; i < 3; i++) extras['bench-' + side + i] = { pos: [x - 1.6 + i * 1.6, 71.4], p: makePerson(k, { no: 12 + i * 3, skin: SKIN[(i * 2 + (side === 'home' ? 1 : 2)) % 6], hair: HAIR[(i + 2) % 6] }) }
  }
  extras.fourth = { pos: [52.5, 69.5], p: makePerson(REF, { skin: SKIN[2], hair: HAIR[1] }) }
  for (const e of Object.values(extras)) { e.p.root.position.copy(W.W3(e.pos[0], e.pos[1])); e.p.root.rotation.y = Math.PI; W.scene.add(e.p.root) }
  const c = document.createElement('canvas'); c.width = 256; c.height = 320; boardCtx = c.getContext('2d')
  boardTex = new W.THREE.CanvasTexture(c); boardTex.encoding = W.THREE.sRGBEncoding
  const mat = new W.THREE.MeshStandardMaterial({ color: '#ffffff', map: boardTex, emissive: '#ffffff', emissiveMap: boardTex, emissiveIntensity: 0.8 }), dark = new W.THREE.MeshStandardMaterial({ color: '#05070C' })
  const board = new W.THREE.Mesh(new W.THREE.BoxGeometry(0.5, 0.62, 0.05), [dark, dark, dark, dark, mat, dark])
  board.position.set(0, 2.25, 0.12); extras.fourth.p.root.add(board)
}
function drawBoard(cut) {
  const g = boardCtx, side = script.sideOf(cut.team)
  g.fillStyle = '#05070C'; g.fillRect(0, 0, 256, 320); g.strokeStyle = props.kits[side].shirt; g.lineWidth = 14; g.strokeRect(7, 7, 242, 306)
  g.textAlign = 'center'; g.textBaseline = 'middle'
  if (cut.plus) { g.font = '700 150px "Barlow Condensed", sans-serif'; g.fillStyle = '#33E07A'; g.fillText('+' + cut.plus, 128, 165) }
  else { g.font = '700 130px "Barlow Condensed", sans-serif'; g.fillStyle = '#FF3B3B'; g.fillText(String(cut.out ?? ''), 128, 90); g.fillStyle = '#33E07A'; g.fillText(String(cut.in ?? ''), 128, 230) }
  boardTex.needsUpdate = true
}

// ---------------------------------------------------------------- play a minute
let debugLock = false, debugPaused = false
function play(tick, opts, fromHook = false) {
  if (debugLock && !fromHook) return
  dirHome = opts.dirHome
  tickMinute = tick.minute[1] ? `${tick.minute[0]}+${tick.minute[1]}'` : `${tick.minute[0]}'`
  script = direct(tick, { teams: props.teams, seed: props.seed, dirHome })
  script.frames = tick.frames
  t = 0; fired = new Set()
  // Players no longer on the pitch leave the scene.
  const ids = new Set(script.actors.map((a) => a.id))
  for (const [id, p] of people) p.root.visible = ids.has(id)
  for (const a of script.actors) { const p = person(a.id, a.side, script.players[a.id]); p.root.visible = true; p.face = undefined }
  for (const c of script.cuts) if (c.type === 'board') drawBoard(c)
}
function skip() { if (script) t = script.dur }
defineExpose({ play, skip })
// Test hook (only with ?debug in the URL): play a given minute and jump to a time in it.
if (location.search.includes('debug')) (window as any).__broadcast = { play: (tk, o) => { debugLock = true; play(tk, o ?? { dirHome: 1 }, true) }, seek: (x) => { debugPaused = true; t = x; if (script) draw(t, 0.05) }, state: () => ({ t, dur: script?.dur, kind: script?.kind, A: script?.A, cuts: script?.cuts.map((c) => [c.type, +c.t0.toFixed(2), +c.t1.toFixed(2)]), banner: hud.banner?.title, label: hud.label?.title, cam: W?.camera.position.toArray().map((v) => +v.toFixed(1)), fx: script?.fx.map((f) => [f.type, +f.t0.toFixed(2)]) }) }

// ---------------------------------------------------------------- per frame
const rate = (tt) => { for (const [a, b, r] of script.slow) if (tt >= a && tt <= b) return r; return 1 }
const name = (x) => (script.players[x] ? script.players[x].name : String(x))
const camTmp = { v: null }
function project(v) { const p = v.clone().project(W.camera); return { x: ((p.x + 1) / 2) * 100, y: ((1 - p.y) / 2) * 100 } }
function camKey(x, y, zoom) {
  const target = W.W3(x, y, 0.9), d = 540 / zoom, h = d * 0.42
  W.camera.position.set(target.x, h, target.z + d); W.camera.lookAt(target)
}
function lookAt(px, py, pz, tx, ty, tz) { W.camera.position.set(px, py, pz); W.camera.lookAt(tx, ty, tz) }

function placeCast(wt, dt, override) {
  const [bx, by] = lerpKeys(script.ball, wt) ?? [52.5, 34]
  const cam = W.camera.position
  for (const a of script.actors) {
    const p = people.get(a.id)
    const [x, y] = lerpKeys(a.keys, wt), [x2, y2] = lerpKeys(a.keys, wt + 0.12)
    const speed = Math.hypot(x2 - x, y2 - y) / 0.12
    p.root.position.copy(W.W3(x, y))
    if (speed > 0.3) p.face = Math.atan2(x2 - x, y2 - y)
    else if (p.face === undefined || a.side === 'ref' || a.side === 'lin' || script.players[a.id]?.slot_line === 'gk') p.face = Math.atan2(bx - x, by - y)
    let pose = null, pt = 0
    for (const [t0, t1, ps] of a.poses) if (wt >= t0 && wt <= t1) { pose = ps; pt = wt - t0; break }
    const o = override?.[a.id]
    if (o) { pose = o.pose; pt = o.pt; p.face = o.face; if (o.at) p.root.position.copy(W.W3(o.at[0], o.at[1])) }
    p.root.rotation.y = p.face
    const fx = Math.sin(p.face), fy = Math.cos(p.face), side = Math.sign(fx * (by - y) - fy * (bx - x)) || 1
    const i = Math.min(a.dist.length - 1, Math.max(0, Math.round(wt / 0.05)))
    animate(p, speed, (a.dist[i] || 0) * 2.85, pose, pt, side, o?.card)
    setNear(p, cam.distanceTo(p.root.position) < 14)
  }
}

function frame(now) {
  const real = Math.min(0.05, (now - last) / 1000); last = now
  if (script && W) {
    const r = rate(t) * (props.speed || 1)
    if (t < script.dur && !debugPaused) {
      t = Math.min(script.dur, t + real * r)
      for (const [ts, n] of script.snd) { const k = 's' + ts + n; if (t >= ts && !fired.has(k)) { fired.add(k); emit('sound', n) } }
      for (const [ts, n] of script.cues) { const k = 'c' + ts + n; if (t >= ts && !fired.has(k)) { fired.add(k); emit('cue', n) } }
    }
    draw(t, real * r)
  }
  raf = requestAnimationFrame(frame)
}

function draw(tt, dt) {
  const s = script, cut = s.cuts.find((c) => tt >= c.t0 && tt < c.t1)
  let wt = tt, override = null
  if (cut?.type === 'replay') wt = cut.from + (cut.to - cut.from) * ((tt - cut.t0) / (cut.t1 - cut.t0))
  if (cut?.type === 'freeze') wt = cut.at
  if (cut?.type === 'refcard') {
    wt = cut.t0
    const ref = s.actors.find((a) => a.id === 'ref'), off = s.actors.find((a) => a.id === String(cut.who))
    if (ref && off) {
      const [rx, ry] = lerpKeys(ref.keys, wt), fy = Math.min(ry, 60)
      override = { ref: { pose: 'card', pt: tt - cut.t0, card: cut.color === 'red' ? '#E5262B' : '#FFD400', face: -Math.PI / 2, at: [rx + 0.8, fy] }, [off.id]: { pose: cut.color === 'red' ? 'head' : 'argue', pt: tt - cut.t0, face: Math.PI / 2, at: [rx - 0.8, fy] } }
    }
  }
  placeCast(wt, dt, override)
  // Coaches, benches and the fourth official only appear in their own shots.
  const coachMood = {}
  for (const c of s.cuts) if (c.type === 'coach' && tt >= c.t0) coachMood[s.sideOf(c.team)] = c.mood
  const showExtras = cut && (cut.type === 'coach' || cut.type === 'board')
  for (const [id, e] of Object.entries(extras)) {
    e.p.root.visible = !!showExtras
    if (!showExtras) continue
    const side = id.includes('home') ? 'home' : 'away'
    const pose = id === 'fourth' ? 'run-arms' : id.startsWith('coach') ? coachMood[side] ?? null : coachMood[side] === 'celebrate' ? 'celebrate' : null
    animate(e.p, 0, 0, pose, tt, 1)
  }
  const [bx, by, bz] = lerpKeys(s.ball, wt) ?? [52.5, 34, 0]
  W.ball.position.copy(W.W3(bx, by, 0.11 + (bz || 0))); W.ball.rotation.x += dt * 9; W.ball.rotation.z += dt * 6
  const rip = s.fx.find((f) => f.type === 'ripple' && wt >= f.t0 && wt <= f.t1)
  for (const n of W.nets) {
    const arr = n.mesh.geometry.attributes.position.array, b = n.mesh.userData.base
    const hit = rip && Math.sign(rip.x - 52.5) === n.side, d = hit ? wt - rip.t0 : 9, amp = d < 1.4 ? Math.sin(d * 18) * (1.4 - d) * 0.35 : 0
    for (let i = 0; i < arr.length; i += 3) arr[i + 2] = b[i + 2] + amp * Math.exp(-(b[i] * b[i] + b[i + 1] * b[i + 1]) / 3) * n.side
    n.mesh.geometry.attributes.position.needsUpdate = true
  }
  const crowdCut = cut?.type === 'crowd' ? cut : null
  const cheering = s.fx.some((f) => f.type === 'center' && f.text.startsWith('هدف') && tt >= f.t0 && tt <= f.t1 + 2.5)
  W.moveCrowd(tt, crowdCut ? crowdCut.mood : cheering ? 'jump' : null, crowdCut ? s.sideOf(crowdCut.team) : cheering ? s.A : null)
  W.sectionFx(tt, crowdCut ? s.sideOf(crowdCut.team) : null, crowdCut ? crowdCut.mood : null)
  W.offLines.forEach((m, i) => { const ln = cut?.type === 'freeze' && cut.lines[i]; m.visible = !!ln; if (ln) { m.position.copy(W.W3(ln[0], 34, 0.03)); m.material.color.set(ln[1]) } })

  // Camera per shot.
  if (!cut || cut.type === 'minimap') { const [x, y, z] = lerpKeys(s.cam, tt) ?? [52.5, 34, 11]; camKey(x, y, z) }
  else if (cut.type === 'replay') { const gx = s.D > 0 ? 113 : -8, [rbx, rby] = lerpKeys(s.ball, wt), k = (tt - cut.t0) / (cut.t1 - cut.t0), p = W.W3(gx, 34 + (rby - 34) * 0.4 + (k - 0.5) * 6, 2.3), q = W.W3(rbx, rby, 0.8); lookAt(p.x, p.y, p.z, q.x, q.y, q.z) }
  else if (cut.type === 'freeze') camKey(cut.cam[0], cut.cam[1], cut.cam[2])
  else if (cut.type === 'crowd') {
    const k = (tt - cut.t0) / (cut.t1 - cut.t0)
    if (s.sideOf(cut.team) === 'away') lookAt(51, 4.5, -10 + k * 8, 66, 7.5, -8 + k * 8)
    else lookAt(-10 + k * 8, 4.5, -31, -6 + k * 8, 7.5, -46)
  } else if (cut.type === 'coach') { const p = extras['coach-' + s.sideOf(cut.team)].p.root.position; lookAt(p.x + 1.2, 1.55, p.z - 3.4, p.x, 1.3, p.z) }
  else if (cut.type === 'refcard') { const ref = people.get('ref').root.position, k = (tt - cut.t0) / (cut.t1 - cut.t0); lookAt(ref.x + 1.6 - k * 0.6, 1.55, ref.z + 3.6 - k * 0.5, ref.x - 0.5, 1.45, ref.z) }
  else if (cut.type === 'board') { const p = extras.fourth.p.root.position; lookAt(p.x + 1.2, 1.7, p.z - 3.6, p.x, 1.75, p.z) }
  if (cut?.type === 'minimap') drawMini(cut, tt)
  updateHud(tt, cut)
  W.renderer.render(W.scene, W.camera)
}

// ---------------------------------------------------------------- HUD
function kitInfo(team) { const side = script.sideOf(team); return { side, k: props.kits[side] } }
function updateHud(tt, cut) {
  const s = script, inCut = cut && cut.type !== 'replay'
  let tag = null, ban = null, cen = null, wh = null
  for (const f of s.fx) if (tt >= f.t0 && tt <= f.t1) { if (f.type === 'tag') tag = f; else if (f.type === 'banner') ban = f; else if (f.type === 'center') cen = f; else if (f.type === 'whistle') wh = f }
  hud.tag = tag && !inCut ? { text: tag.text, bg: kitInfo(tag.team).k.shirt, fg: kitInfo(tag.team).k.text } : null
  if (ban && !inCut) {
    const { k } = kitInfo(ban.team)
    hud.banner = { accent: ban.card === 'red' ? '#E5262B' : ban.card === 'yellow' ? '#FFD400' : k.shirt, top: ban.goal ? 'هدف · ' + k.name : '', title: name(ban.title), sub: (ban.sub ?? []).map(name).join(' ') }
  } else hud.banner = null
  hud.big = cen && !inCut ? { text: cen.text, glow: kitInfo(cen.team).k.shirt, small: cen.small } : null
  hud.slow = !inCut && (cut?.type === 'replay' || rate(tt) < 1)
  hud.replay = cut?.type === 'replay'
  hud.whistle = wh && !inCut && people.get('ref') ? project(people.get('ref').root.position.clone().setY(2.4)) : null
  hud.frozen = cut?.type === 'freeze'
  hud.freeze = cut?.type === 'freeze' ? 'لحظة التمرير · ' + cut.label : ''
  hud.lines = cut?.type === 'freeze' ? cut.lines.map(([x, color, text]) => ({ ...project(W.W3(x, 67.5, 0)), color, text })) : []
  let lab = null
  if (cut && cut.type !== 'minimap') {
    const { k } = cut.team ? kitInfo(cut.team) : { k: null }
    if (cut.type === 'coach') lab = { title: k.coach, sub: { celebrate: 'يحتفل مع الجهاز الفني', head: 'لا يصدق ما حدث', argue: 'يعترض على الحكم', shout: 'يصرخ بالتعليمات' }[cut.mood], accent: k.shirt }
    if (cut.type === 'crowd') lab = { title: 'جمهور ' + k.name, sub: { jump: 'المدرجات تشتعل', quiet: 'صمت وترقب', groan: 'حسرة في المدرجات' }[cut.mood], accent: k.shirt }
    if (cut.type === 'refcard') lab = { title: name(cut.who), sub: cut.color === 'red' ? 'بطاقة حمراء · طرد' : 'بطاقة صفراء · إنذار', accent: cut.color === 'red' ? '#E5262B' : '#FFD400' }
    if (cut.type === 'board') lab = { title: cut.plus ? 'الوقت بدل الضائع' : 'تبديل · ' + k.name, sub: cut.plus ? `${cut.plus} دقائق` : '', accent: cut.plus ? '#F5B82E' : k.shirt }
  }
  hud.label = lab
  hud.mini = cut?.type === 'minimap'
  let wipe = null
  for (const c of s.cuts) for (const e of [c.t0, c.t1]) if (c.type !== 'minimap' && e > 0 && e < s.dur && Math.abs(tt - e) < 0.13) wipe = { x: -140 + ((tt - e + 0.13) / 0.26) * 280, color: props.kits[s.sideOf(c.team || 'A')].shirt }
  hud.wipe = wipe
}

// Quiet minutes: the server's own frames on a mini-map.
function drawMini(cut, tt) {
  const cv = mini.value, g = cv.getContext('2d'), w = (cv.width = cv.clientWidth * 2), h = (cv.height = cv.clientHeight * 2)
  g.fillStyle = 'rgba(7,23,51,0.9)'; g.fillRect(0, 0, w, h)
  const pw = Math.min(w * 0.82, (h * 0.8 * 105) / 68), ph = (pw * 68) / 105, px = (w - pw) / 2, py = (h - ph) / 2
  g.fillStyle = '#1A8A42'; g.fillRect(px - 8, py - 8, pw + 16, ph + 16)
  for (let i = 0; i < 10; i++) { g.fillStyle = i % 2 ? '#1E9A4B' : '#22A653'; g.fillRect(px + (i * pw) / 10, py, pw / 10, ph) }
  g.strokeStyle = 'rgba(255,255,255,0.8)'; g.lineWidth = 3; g.strokeRect(px, py, pw, ph)
  g.beginPath(); g.moveTo(px + pw / 2, py); g.lineTo(px + pw / 2, py + ph); g.stroke(); g.beginPath(); g.arc(px + pw / 2, py + ph / 2, ph * 0.13, 0, 7); g.stroke()
  g.strokeRect(px, py + ph * 0.2, pw * 0.157, ph * 0.6); g.strokeRect(px + pw * 0.843, py + ph * 0.2, pw * 0.157, ph * 0.6)
  const fr = script.frames ?? [], n = fr.length
  if (n) {
    const pos = Math.min(n - 1, (tt / Math.max(0.1, script.dur)) * (n - 1)), i = Math.floor(pos), f = pos - i, a = fr[i], b = fr[Math.min(n - 1, i + 1)]
    const toS = (x, y) => (dirHome > 0 ? [px + (x / 1050) * pw, py + (y / 680) * ph] : [px + (1 - x / 1050) * pw, py + (1 - y / 680) * ph])
    for (const id of Object.keys(b.p)) {
      const p0 = a.p[id] ?? b.p[id], p1 = b.p[id], info = script.players[id]
      if (!info) continue
      const k = props.kits[info.side], [sx, sy] = toS(p0[0] + (p1[0] - p0[0]) * f, p0[1] + (p1[1] - p0[1]) * f)
      g.fillStyle = info.slot_line === 'gk' ? k.gk : k.shirt; g.beginPath(); g.arc(sx, sy, w * 0.009, 0, 7); g.fill(); g.strokeStyle = k.stripe || k.trim; g.lineWidth = 3; g.stroke()
    }
    const [sbx, sby] = toS(a.b[0] + (b.b[0] - a.b[0]) * f, a.b[1] + (b.b[1] - a.b[1]) * f)
    g.fillStyle = '#fff'; g.beginPath(); g.arc(sbx, sby, w * 0.006, 0, 7); g.fill()
  }
  hud.miniMinute = tickMinute
  const L = cut.label
  hud.miniLabel = L ? (() => { const k = props.kits[script.sideOf(L.team)]; return { t: L.text + (L.text.endsWith(' ') ? k.name : '') + (L.end ? ' · ' + L.end : ''), color: k.shirt, text: k.text } })() : null
}

onMounted(() => {
  W = createWorld(host.value)
  W.setKits(props.kits)
  buildExtras()
  last = performance.now(); raf = requestAnimationFrame(frame)
})
watch(() => props.kits, (k) => W?.setKits(k))
onBeforeUnmount(() => { cancelAnimationFrame(raf); W?.dispose() })
</script>

<style scoped>
.hud { position: absolute; inset: 0; pointer-events: none; font-size: clamp(8px, 1.45cqw, 17px); z-index: 1 }
.hud > * { opacity: 0; transition: opacity 0.18s }
.hud > .on, .hud .mm, .hud .ol { opacity: 1 }
.mini { position: absolute; inset: 0; width: 100%; height: 100% }
.mm { position: absolute; inset: 0 }
.mm-min { position: absolute; top: 4%; left: 3%; font-weight: 700; font-size: 3.6em; color: #F5B82E; line-height: 1 }
.mm-label { position: absolute; bottom: 5%; left: 50%; transform: translateX(-50%); padding: 0.35em 1em; border-radius: 99px; font-family: 'Alexandria', 'IBM Plex Sans Arabic', sans-serif; font-weight: 800; font-size: 1.2em; white-space: nowrap }
.scan { position: absolute; inset: 0; background: repeating-linear-gradient(0deg, rgba(0, 0, 0, 0.08) 0 1px, transparent 1px 4px), rgba(20, 60, 140, 0.2) }
.tag { position: absolute; top: 4%; left: 2%; padding: 0.35em 1em; border-radius: 99px; font-family: 'Alexandria', 'IBM Plex Sans Arabic', sans-serif; font-weight: 800; font-size: 1.2em }
.big { position: absolute; inset: 0; display: grid; place-items: center; font-family: 'Alexandria', 'IBM Plex Sans Arabic', sans-serif; font-weight: 800; font-size: 8em; color: #F7F4EA; text-shadow: 0 0 0.35em var(--glow, #F5B82E), 0 0.04em 0 #071733; transform: scale(0.7); transition: opacity 0.18s, transform 0.25s }
.big.on { transform: scale(1) }
.big.small { font-size: 5em }
.lower { position: absolute; right: 2%; bottom: 6%; min-width: 44%; max-width: 70%; background: rgba(7, 23, 51, 0.92); border-right: 0.6em solid var(--kit, #F5B82E); border-radius: 0.6em; padding: 0.5em 1em; transform: translateX(-1.5em); transition: opacity 0.22s, transform 0.22s; color: #F7F4EA }
.lower.on { transform: none }
.lower small { display: block; color: #F5B82E; font-weight: 600 }
.lower b { display: block; font-family: 'Alexandria', 'IBM Plex Sans Arabic', sans-serif; font-size: 1.8em; line-height: 1.25 }
.lower span { color: #C9D2E1 }
.badge { position: absolute; left: 2%; padding: 0.3em 0.95em; border-radius: 99px; font-weight: 700 }
.slow { bottom: 6%; background: rgba(7, 23, 51, 0.85); color: #F5B82E }
.replay { top: 4%; background: #F5B82E; color: #0A1F42; font-family: 'Alexandria', 'IBM Plex Sans Arabic', sans-serif; font-size: 1.25em }
.freeze { top: 4%; background: #EF4444; color: #fff; font-family: 'Alexandria', 'IBM Plex Sans Arabic', sans-serif }
.ol { position: absolute; transform: translate(-50%, 10%); color: #fff; font-weight: 700; padding: 0.15em 0.7em; border-radius: 0.35em; white-space: nowrap }
.whistle { position: absolute; width: 3.2em; height: 2.2em; transform: translate(-50%, -100%) }
.wipe { position: absolute; top: -10%; bottom: -10%; left: 0; width: 60%; border-left: 1.2em solid #F5B82E }
</style>
