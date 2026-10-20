// The photo scene engine (W15, MATCH_VIEW 4.7): a stadium photo for the camera angle, and on it the
// characters from the art atlases, each sized by where its feet touch the grass, lit like the plate,
// with two floodlight shadows and grass over the boots. Then the ball, the camera (pan, zoom, shake),
// cuts between angles, and a fine grain over everything so the cut-outs sit in the photo.
// render(t) draws the same picture for the same t: replays and two screens match.

import { drawFrame, plateUrl, type ArtFrame, type ArtManifest, type ArtPages, type ArtSize } from '../art'
import { PERSON, personHeight, plateCamera, type PlateCamera } from './plates'

export interface Actor {
  seq: string // a sequence in the manifest, e.g. 'striker/run-side'
  kit: string | null // the club colour for the white kit, null for its own colours
  x: number // feet, 0..1 across the plate
  y: number // feet, 0..1 down the plate (depth comes from this)
  flip?: boolean // face left instead of right
  t0?: number // when the sequence starts, seconds
  fps?: number // frames a second (the manifest's by default)
  loop?: boolean // loop, or hold the last frame
  lift?: number // off the grass, metres (a jump)
  alpha?: number
}

export interface BallState {
  x: number
  y: number // the ground point under the ball, 0..1
  h: number // height above the grass, metres
  spin: number // turns so far
  squash?: number // 0..1, the moment of the kick
}

export interface Wipe {
  at: number // when the wipe starts, seconds; the picture changes at its middle
  plate: string
  colour: string // the team's colour
}

const WIPE = 0.25 // seconds (MOMENTS 3)
const BALL = 0.22 // metres across
const LIGHT: Record<string, string> = { night: 'rgba(36,58,130,0.16)', day: 'rgba(255,236,200,0.08)', sunset: 'rgba(255,140,60,0.14)' }

function rng(seed: number) {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

export class PhotoStage {
  readonly canvas = document.createElement('canvas')
  private ctx = this.canvas.getContext('2d')!
  private plates = new Map<string, HTMLImageElement>()
  private actorCanvas = document.createElement('canvas')
  private grainTile: HTMLCanvasElement
  plate = ''
  cam: PlateCamera = plateCamera('')
  actors: Actor[] = []
  ball: BallState | null = null
  view = { x: 0.5, y: 0.5, zoom: 1 }
  shake = 0 // 0..1
  wipes: Wipe[] = []
  options = { shadows: true, light: true, grain: true, blend: true, grass: true }
  aspect = 16 / 9

  private manifest: ArtManifest
  private pages: ArtPages
  private size: ArtSize

  constructor(manifest: ArtManifest, pages: ArtPages, size: ArtSize) {
    this.manifest = manifest
    this.pages = pages
    this.size = size
    this.grainTile = grain()
  }

  /** Loads every plate the scene will cut to, so no cut waits for a picture (MATCH_VIEW 4.7). */
  async load(names: string[]) {
    await Promise.all(
      names.filter((n) => !this.plates.has(n)).map(
        (n) =>
          new Promise<void>((resolve, reject) => {
            const img = new Image()
            img.onload = () => (this.plates.set(n, img), resolve())
            img.onerror = () => reject(new Error(n))
            img.src = plateUrl(n, this.size)
          }),
      ),
    )
    if (!this.plate && names[0]) this.setPlate(names[0])
  }

  has(seq: string) {
    const s = this.manifest.sequences[seq]
    return !!s && s.frames[this.size].length > 0
  }

  setPlate(name: string) {
    this.plate = name
    this.cam = plateCamera(name)
  }

  /** Sizes the canvas to its box at the device's pixel ratio. */
  fit(width: number) {
    const dpr = Math.min(window.devicePixelRatio || 1, 2)
    const h = Math.round(width / this.aspect)
    if (this.canvas.width !== Math.round(width * dpr)) {
      this.canvas.width = Math.round(width * dpr)
      this.canvas.height = Math.round(h * dpr)
      this.canvas.style.width = '100%'
      this.canvas.style.aspectRatio = String(this.aspect)
    }
  }

  // ------------------------------------------------------------------ geometry
  /** Plate pixels to screen pixels: the plate covers the canvas, then the camera zooms on view. */
  private frame() {
    const img = this.plates.get(this.plate)
    const W = this.canvas.width
    const H = this.canvas.height
    const pw = img?.width ?? 1376
    const ph = img?.height ?? 768
    const k = Math.max(W / pw, H / ph) * Math.max(1, this.view.zoom)
    const sw = pw * k
    const sh = ph * k
    // keep the plate covering the screen however the camera moves
    const cx = Math.min(1 - W / sw / 2, Math.max(W / sw / 2, this.view.x))
    const cy = Math.min(1 - H / sh / 2, Math.max(H / sh / 2, this.view.y))
    return { W, H, sw, sh, ox: W / 2 - cx * sw, oy: H / 2 - cy * sh }
  }

  /** Where a ground point (0..1 on the plate) is on screen, and how many screen pixels a metre is there. */
  project(x: number, y: number) {
    const f = this.frame()
    const tall = personHeight(this.cam, y) * f.sh
    return { sx: f.ox + x * f.sw, sy: f.oy + y * f.sh, perMetre: tall / PERSON }
  }

  // ------------------------------------------------------------------ drawing
  render(t: number) {
    const { ctx } = this
    const f = this.frame()
    const r = rng(Math.floor(t * 60) + 7)
    ctx.save()
    ctx.setTransform(1, 0, 0, 1, 0, 0)
    if (this.shake > 0) ctx.translate((r() - 0.5) * 14 * this.shake, (r() - 0.5) * 10 * this.shake)

    const wipe = this.wipes.find((w) => t >= w.at && t < w.at + WIPE)
    const passed = this.wipes.filter((w) => t >= w.at + WIPE / 2)
    if (passed.length) this.setPlate(passed[passed.length - 1].plate)

    const img = this.plates.get(this.plate)
    if (img) ctx.drawImage(img, f.ox, f.oy, f.sw, f.sh)
    else {
      ctx.fillStyle = '#0B1A33'
      ctx.fillRect(0, 0, f.W, f.H)
    }

    // far ones first, so nearer ones stand in front
    const order = [...this.actors].sort((a, b) => a.y - b.y)
    let ballDrawn = !this.ball
    for (const a of order) {
      if (!ballDrawn && this.ball!.y <= a.y) (this.drawBall(t), (ballDrawn = true))
      this.drawActor(a, t)
    }
    if (!ballDrawn) this.drawBall(t)

    if (this.options.grain) {
      ctx.globalAlpha = 0.07
      ctx.fillStyle = ctx.createPattern(this.grainTile, 'repeat')!
      ctx.translate(-r() * 128, -r() * 128)
      ctx.fillRect(0, 0, f.W + 256, f.H + 256)
      ctx.setTransform(1, 0, 0, 1, 0, 0)
      ctx.globalAlpha = 1
    }
    vignette(ctx, f.W, f.H)
    if (wipe) drawWipe(ctx, f.W, f.H, (t - wipe.at) / WIPE, wipe.colour)
    ctx.restore()
  }

  private frameAt(a: Actor, t: number): [ArtFrame, ArtFrame, number] | null {
    const list = this.manifest.sequences[a.seq]?.frames[this.size]
    if (!list?.length) return null
    const p = Math.max(0, (t - (a.t0 ?? 0)) * (a.fps ?? this.manifest.fps))
    const n = list.length
    const i = Math.floor(p)
    const loop = a.loop ?? true
    const k = loop ? i % n : Math.min(i, n - 1)
    const next = loop ? (k + 1) % n : Math.min(k + 1, n - 1)
    return [list[k], list[next], this.options.blend ? p - i : 0]
  }

  private drawActor(a: Actor, t: number) {
    const fr = this.frameAt(a, t)
    if (!fr) return
    const [A, B, mix] = fr
    const { sx, sy, perMetre } = this.project(a.x, a.y)
    if (perMetre <= 0) return
    const player = this.manifest.sizes[this.size].player
    const scale = (perMetre * PERSON) / player
    const lift = (a.lift ?? 0) * perMetre
    const { ctx } = this

    if (this.options.shadows) shadows(ctx, sx, sy, perMetre, a.lift ?? 0, (a.alpha ?? 1) * 0.55)

    // The figure goes on its own canvas first, so light and grass touch it and not the plate.
    // wide enough on both sides of the anchor (the torso), which is not always the frame's middle
    const w = Math.ceil(2 * Math.max(A.ax, A.w - A.ax, B.ax, B.w - B.ax) * scale) + 8
    const h = Math.ceil(Math.max(A.ay, B.ay) * scale) + 8
    const oc = this.actorCanvas
    if (oc.width < w || oc.height < h) {
      oc.width = Math.max(oc.width, w)
      oc.height = Math.max(oc.height, h)
    }
    const o = oc.getContext('2d')!
    o.clearRect(0, 0, oc.width, oc.height)
    const ax = w / 2
    const ay = h - 4
    drawFrame(o, this.pages, A, ax, ay, a.kit, scale)
    if (mix > 0.05) {
      o.globalAlpha = mix
      drawFrame(o, this.pages, B, ax, ay, a.kit, scale)
      o.globalAlpha = 1
    }
    o.globalCompositeOperation = 'source-atop'
    if (this.options.light) {
      o.fillStyle = LIGHT[this.plate.split('/')[1]] ?? LIGHT.night
      o.fillRect(0, 0, w, h)
      // the floodlights from behind: a cool rim on the top half
      const g = o.createLinearGradient(0, 0, 0, h)
      g.addColorStop(0, 'rgba(200,220,255,0.10)')
      g.addColorStop(0.5, 'rgba(200,220,255,0)')
      o.fillStyle = g
      o.fillRect(0, 0, w, h)
    }
    o.globalCompositeOperation = 'destination-out'
    if (this.options.grass && !a.lift) {
      // the grass hides the tips of the boots
      const blades = perMetre * 0.035
      const g = o.createLinearGradient(0, ay - blades, 0, ay)
      g.addColorStop(0, 'rgba(0,0,0,0)')
      g.addColorStop(1, 'rgba(0,0,0,0.85)')
      o.fillStyle = g
      o.fillRect(0, ay - blades, w, blades + 4)
    }
    o.globalCompositeOperation = 'source-over'

    ctx.save()
    ctx.globalAlpha = a.alpha ?? 1
    ctx.translate(sx, sy - lift)
    if (a.flip) ctx.scale(-1, 1)
    ctx.drawImage(oc, 0, 0, w, h, -ax, -ay, w, h)
    ctx.restore()
  }

  private drawBall(t: number) {
    const b = this.ball!
    const { sx, sy, perMetre } = this.project(b.x, b.y)
    if (perMetre <= 0) return
    const { ctx } = this
    const r = Math.max(1.5, (BALL / 2) * perMetre)
    if (this.options.shadows) {
      const fade = 1 / (1 + b.h * 0.6)
      ctx.save()
      ctx.globalAlpha = 0.5 * fade
      ctx.fillStyle = '#000'
      ctx.beginPath()
      ctx.ellipse(sx, sy, r * (1.1 + b.h * 0.15), r * 0.35, 0, 0, Math.PI * 2)
      ctx.fill()
      ctx.restore()
    }
    const by = sy - b.h * perMetre - r
    const spin = this.manifest.sequences['balls/classic/spin']?.frames[this.size]
    if (spin?.length) {
      const f = spin[Math.floor(b.spin * spin.length) % spin.length]
      const s = (2 * r) / Math.max(f.w, f.h)
      drawFrame(ctx, this.pages, f, sx, by + r, null, s)
      return
    }
    // until the ball's own frames arrive: a shaded ball with turning patches
    ctx.save()
    ctx.translate(sx, by)
    ctx.scale(1 + (b.squash ?? 0) * 0.25, 1 - (b.squash ?? 0) * 0.2)
    const g = ctx.createRadialGradient(-r * 0.35, -r * 0.4, r * 0.1, 0, 0, r)
    g.addColorStop(0, '#FFFFFF')
    g.addColorStop(0.7, '#D8DDE6')
    g.addColorStop(1, '#7D8698')
    ctx.fillStyle = g
    ctx.beginPath()
    ctx.arc(0, 0, r, 0, Math.PI * 2)
    ctx.fill()
    ctx.clip()
    ctx.fillStyle = 'rgba(20,24,34,0.75)'
    const a0 = b.spin * Math.PI * 2
    for (let i = 0; i < 5; i++) {
      const a = a0 + (i * Math.PI * 2) / 5
      const d = r * 0.62 * Math.cos(a)
      if (Math.sin(a) < -0.2) continue
      ctx.beginPath()
      ctx.arc(d, r * 0.15 * Math.sin(a * 2), r * 0.24 * Math.max(0.3, Math.sin(a)), 0, Math.PI * 2)
      ctx.fill()
    }
    ctx.restore()
    void t
  }
}

/** Two soft shadows on the grass from the floodlights on either side, shorter and fainter in the air. */
function shadows(ctx: CanvasRenderingContext2D, x: number, y: number, perMetre: number, lift: number, alpha: number) {
  const fade = 1 / (1 + lift * 1.5)
  ctx.save()
  for (const [dx, rot] of [[-0.35, -0.25], [0.35, 0.25]]) {
    ctx.save()
    ctx.translate(x + dx * perMetre * 0.4, y)
    ctx.rotate(rot)
    const len = perMetre * 0.9
    const g = ctx.createRadialGradient(0, 0, 0, 0, 0, len)
    g.addColorStop(0, `rgba(0,0,0,${alpha * fade})`)
    g.addColorStop(1, 'rgba(0,0,0,0)')
    ctx.scale(1, 0.16)
    ctx.fillStyle = g
    ctx.beginPath()
    ctx.arc(0, 0, len, 0, Math.PI * 2)
    ctx.fill()
    ctx.restore()
  }
  // contact shadow right under the feet
  ctx.globalAlpha = alpha * fade
  ctx.fillStyle = '#000'
  ctx.beginPath()
  ctx.ellipse(x, y, perMetre * 0.32, perMetre * 0.06, 0, 0, Math.PI * 2)
  ctx.fill()
  ctx.restore()
}

function grain(): HTMLCanvasElement {
  const c = document.createElement('canvas')
  c.width = c.height = 128
  const ctx = c.getContext('2d')!
  const d = ctx.createImageData(128, 128)
  const r = rng(99)
  for (let i = 0; i < d.data.length; i += 4) {
    const v = Math.floor(r() * 255)
    d.data[i] = d.data[i + 1] = d.data[i + 2] = v
    d.data[i + 3] = 255
  }
  ctx.putImageData(d, 0, 0)
  return c
}

function vignette(ctx: CanvasRenderingContext2D, W: number, H: number) {
  const g = ctx.createRadialGradient(W / 2, H / 2, Math.min(W, H) * 0.45, W / 2, H / 2, Math.max(W, H) * 0.75)
  g.addColorStop(0, 'rgba(0,0,0,0)')
  g.addColorStop(1, 'rgba(0,0,0,0.35)')
  ctx.fillStyle = g
  ctx.fillRect(0, 0, W, H)
}

/** The cut between angles: a slanted band in the team's colour with a gold edge (MOMENTS 3). */
function drawWipe(ctx: CanvasRenderingContext2D, W: number, H: number, p: number, colour: string) {
  const band = W * 0.5
  const x = -band - H * 0.4 + p * (W + band * 2 + H * 0.4)
  ctx.save()
  ctx.beginPath()
  ctx.moveTo(x, H)
  ctx.lineTo(x + H * 0.4, 0)
  ctx.lineTo(x + H * 0.4 + band, 0)
  ctx.lineTo(x + band, H)
  ctx.closePath()
  ctx.fillStyle = colour
  ctx.fill()
  ctx.strokeStyle = '#E8B84B'
  ctx.lineWidth = Math.max(3, W * 0.006)
  ctx.beginPath()
  ctx.moveTo(x + band, H)
  ctx.lineTo(x + H * 0.4 + band, 0)
  ctx.stroke()
  ctx.restore()
}
