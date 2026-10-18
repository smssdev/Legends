<template>
  <div ref="host" class="absolute inset-0" />
</template>

<script setup lang="ts">
// The match pitch (docs/MATCH_VIEW.md 4), drawn with PixiJS from the
// server's keyframes. It only interpolates: no movement is computed here.
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { Application, Container, Graphics, Text } from 'pixi.js'
import type { Frame } from '../api/sim'
import { project, VIEW_H, VIEW_W } from './projection'

export interface PitchPlayer {
  no: number
  side: 'home' | 'away'
  gk: boolean
}

const props = defineProps<{
  players: Record<string, PitchPlayer>
  kits: { home: string; homeText: string; away: string; awayText: string }
}>()

const host = ref<HTMLDivElement>()
let app: Application | null = null
const stage = new Container()
const people = new Map<string, { root: Container; body: Graphics; ring: Graphics }>()
let ball: { root: Container; shadow: Graphics; dot: Graphics } | null = null

let from: Record<string, [number, number]> = {}
let fromBall: [number, number, number] = [525, 340, 0]
let frames: Frame[] = []
let start = 0
let duration = 1

function pts(list: [number, number][]) {
  return list.flatMap(([x, y]) => {
    const p = project(x, y)
    return [p.sx, p.sy]
  })
}

function drawPitch(g: Graphics) {
  g.rect(0, 0, VIEW_W, VIEW_H).fill(0x06122a)
  // Stands with a crowd texture.
  g.rect(-20, 0, VIEW_W + 40, 88).fill(0x14254a)
  for (let i = 0; i < 1400; i++) {
    const x = (i * 97) % (VIEW_W + 20)
    const y = 6 + ((i * 53) % 80)
    g.circle(x, y, 1.6).fill(i % 3 === 0 ? 0xc8102e : i % 3 === 1 ? 0xe9e3d2 : 0x7a0a1c)
  }
  g.rect(0, 0, VIEW_W, 14).fill(0x0a1a38)
  const apron = pts([[-90, -70], [1140, -70], [1140, 760], [-90, 760]])
  g.poly(apron).fill(0x177a3b)
  for (let i = 0; i < 14; i++) {
    const a = i * 75
    g.poly(pts([[a, 0], [a + 75, 0], [a + 75, 680], [a, 680]])).fill(i % 2 ? 0x1e9a4b : 0x22a653)
  }
  const line = { width: 1.6, color: 0xffffff, alpha: 0.82 }
  const rect = (x0: number, y0: number, x1: number, y1: number) => g.poly(pts([[x0, y0], [x1, y0], [x1, y1], [x0, y1]])).stroke(line)
  rect(0, 0, 1050, 680)
  rect(0, 138, 165, 542)
  rect(885, 138, 1050, 542)
  rect(0, 248, 55, 432)
  rect(995, 248, 1050, 432)
  g.poly(pts([[525, 0], [525, 680]]), false).stroke(line)
  const circle: [number, number][] = []
  for (let k = 0; k <= 48; k++) circle.push([525 + 91.5 * Math.cos((k / 48) * Math.PI * 2), 340 + 91.5 * Math.sin((k / 48) * Math.PI * 2)])
  g.poly(pts(circle)).stroke(line)
  for (const gx of [0, 1050]) {
    const a = project(gx, 303)
    const b = project(gx, 377)
    g.moveTo(a.sx, a.sy).lineTo(a.sx, a.sy - 22 * a.s).lineTo(b.sx, b.sy - 22 * b.s).lineTo(b.sx, b.sy).stroke({ width: 2.4, color: 0xffffff })
  }
}

function person(id: string) {
  let p = people.get(id)
  if (p) return p
  const info = props.players[id]
  const root = new Container()
  const shadow = new Graphics().ellipse(0, 0, 13, 4).fill({ color: 0x000000, alpha: 0.38 })
  const ring = new Graphics()
  const body = new Graphics()
  const home = info?.side === 'home'
  const color = info?.gk ? (home ? 0x1f6b45 : 0xe7c826) : parseInt((home ? props.kits.home : props.kits.away).slice(1), 16)
  const text = info?.gk ? (home ? 0xffffff : 0x2a2300) : parseInt((home ? props.kits.homeText : props.kits.awayText).slice(1), 16)
  body.roundRect(-12, -30, 24, 28, 7).fill(color).stroke({ width: 2, color: text, alpha: 0.9 })
  const label = new Text({ text: String(info?.no ?? ''), style: { fontFamily: 'Barlow Condensed, sans-serif', fontWeight: '700', fontSize: 15, fill: text } })
  label.anchor.set(0.5)
  label.position.set(0, -16)
  root.addChild(shadow, ring, body, label)
  stage.addChild(root)
  p = { root, body, ring }
  people.set(id, p)
  return p
}

function makeBall() {
  const root = new Container()
  const shadow = new Graphics().ellipse(0, 0, 7, 2.6).fill({ color: 0x000000, alpha: 0.45 })
  const dot = new Graphics().circle(0, 0, 7).fill(0xffffff).stroke({ width: 1.5, color: 0x0a1f42 })
  root.addChild(shadow, dot)
  stage.addChild(root)
  return { root, shadow, dot }
}

/** Plays one minute: interpolates from where things are to the minute's 6 frames. */
function play(next: Frame[], ms: number) {
  if (!next.length) return
  // Start from the current on-screen positions so nothing jumps.
  const now = sample(performance.now())
  from = now.players
  fromBall = now.ball
  frames = next
  start = performance.now()
  duration = Math.max(200, ms)
}

function sample(time: number): { players: Record<string, [number, number]>; ball: [number, number, number]; holder: number | null } {
  if (!frames.length) return { players: from, ball: fromBall, holder: null }
  const t = Math.min(1, (time - start) / duration)
  const pos = t * frames.length
  const i = Math.min(frames.length - 1, Math.floor(pos))
  const f = pos - i
  const a = i === 0 ? { p: from, b: fromBall } : frames[i - 1]
  const b = frames[i]
  const players: Record<string, [number, number]> = {}
  for (const id of Object.keys(b.p)) {
    const p0 = (a.p as Record<string, [number, number]>)[id] ?? b.p[id]
    const p1 = b.p[id]
    players[id] = [p0[0] + (p1[0] - p0[0]) * f, p0[1] + (p1[1] - p0[1]) * f]
  }
  const b0 = a.b as [number, number, number]
  const arc = Math.sin(Math.PI * f) * Math.max(b0[2], b.b[2])
  return { players, ball: [b0[0] + (b.b[0] - b0[0]) * f, b0[1] + (b.b[1] - b0[1]) * f, arc], holder: f > 0.5 ? b.h : (a as Frame).h ?? b.h }
}

function render() {
  const now = sample(performance.now())
  const seen = new Set<string>()
  for (const [id, [x, y]] of Object.entries(now.players)) {
    seen.add(id)
    const p = person(id)
    const pr = project(x, y)
    p.root.visible = true
    p.root.position.set(pr.sx, pr.sy)
    p.root.scale.set(pr.s)
    p.root.zIndex = pr.sy
    const holding = now.holder !== null && String(now.holder) === id
    p.ring.clear()
    if (holding) p.ring.roundRect(-15, -33, 30, 34, 9).fill({ color: props.players[id]?.side === 'home' ? 0xf5b82e : 0xf7f4ea, alpha: 0.95 })
  }
  for (const [id, p] of people) if (!seen.has(id)) p.root.visible = false
  if (ball) {
    const [x, y, z] = now.ball
    const pr = project(x, y)
    ball.root.position.set(pr.sx, pr.sy)
    ball.root.zIndex = pr.sy + 1
    ball.root.scale.set(pr.s)
    ball.dot.position.set(0, -6 - z * 0.9)
  }
}

function fit() {
  if (!app || !host.value) return
  const w = host.value.clientWidth
  const h = host.value.clientHeight
  const scale = Math.min(w / VIEW_W, h / VIEW_H)
  stage.scale.set(scale)
  stage.position.set((w - VIEW_W * scale) / 2, (h - VIEW_H * scale) / 2)
}

let observer: ResizeObserver | null = null

onMounted(async () => {
  app = new Application()
  await app.init({ background: 0x06122a, antialias: true, resizeTo: host.value!, resolution: Math.min(2, window.devicePixelRatio || 1), autoDensity: true })
  host.value!.appendChild(app.canvas)
  stage.sortableChildren = true
  const pitch = new Graphics()
  drawPitch(pitch)
  pitch.zIndex = -1000
  stage.addChild(pitch)
  ball = makeBall()
  app.stage.addChild(stage)
  fit()
  observer = new ResizeObserver(fit)
  observer.observe(host.value!)
  app.ticker.add(render)
})

onBeforeUnmount(() => {
  observer?.disconnect()
  app?.destroy(true, { children: true })
  app = null
})

defineExpose({ play })
</script>
