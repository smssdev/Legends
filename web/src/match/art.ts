// The match art built by tools/art/build.py (W14): atlases, kit masks and the manifest.
// Draws any frame of any sequence in a club's colours. Used by the preview page (W14b) and later the scene engine (W15).

export type ArtSize = 'hd' | 'sd'

export interface ArtFrame { i: number; page: number; x: number; y: number; w: number; h: number; ax: number; ay: number }
export interface ArtSequence { total: number; missing: number[]; frames: Record<ArtSize, ArtFrame[]> }
export interface ArtManifest {
  fps: number
  sizes: Record<ArtSize, { player: number; pages: string[] }>
  sequences: Record<string, ArtSequence>
  plates: Record<string, Record<ArtSize, [number, number]>>
}

const BASE = '/match-art'

export async function loadManifest(): Promise<ArtManifest | null> {
  try {
    const res = await fetch(`${BASE}/manifest.json`, { cache: 'no-cache' })
    return res.ok ? await res.json() : null
  } catch {
    return null
  }
}

function image(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => resolve(img)
    img.onerror = () => reject(new Error(src))
    img.src = src
  })
}

/** The kit mask is greyscale; the browser needs it as alpha to cut with. */
function maskToAlpha(img: HTMLImageElement): HTMLCanvasElement {
  const c = document.createElement('canvas')
  c.width = img.width
  c.height = img.height
  const ctx = c.getContext('2d')!
  ctx.drawImage(img, 0, 0)
  const data = ctx.getImageData(0, 0, c.width, c.height)
  const px = data.data
  for (let i = 0; i < px.length; i += 4) {
    px[i + 3] = px[i]
    px[i] = px[i + 1] = px[i + 2] = 255
  }
  ctx.putImageData(data, 0, 0)
  return c
}

export interface ArtPages { colour: HTMLImageElement[]; kit: HTMLCanvasElement[] }

export async function loadPages(m: ArtManifest, size: ArtSize): Promise<ArtPages> {
  const names = m.sizes[size].pages
  const colour = await Promise.all(names.map((n) => image(`${BASE}/${size}/${n}.png`)))
  const kit = (await Promise.all(names.map((n) => image(`${BASE}/${size}/${n}-kit.png`)))).map(maskToAlpha)
  return { colour, kit }
}

export function plateUrl(name: string, size: ArtSize): string {
  return `${BASE}/${size}/plates/${name}.webp`
}

const scratch = document.createElement('canvas')

/**
 * Draws one frame with its anchor (middle of the shirt, ground line) at (x, y).
 * The white kit is multiplied by the club colour, so its folds and shadows stay.
 */
export function drawFrame(ctx: CanvasRenderingContext2D, pages: ArtPages, f: ArtFrame, x: number, y: number, kit: string | null, scale = 1) {
  const dx = x - f.ax * scale
  const dy = y - f.ay * scale
  const w = f.w * scale
  const h = f.h * scale
  ctx.drawImage(pages.colour[f.page], f.x, f.y, f.w, f.h, dx, dy, w, h)
  if (!kit) return
  scratch.width = f.w
  scratch.height = f.h
  const s = scratch.getContext('2d')!
  s.drawImage(pages.colour[f.page], f.x, f.y, f.w, f.h, 0, 0, f.w, f.h)
  s.globalCompositeOperation = 'multiply'
  s.fillStyle = kit
  s.fillRect(0, 0, f.w, f.h)
  s.globalCompositeOperation = 'destination-in'
  s.drawImage(pages.kit[f.page], f.x, f.y, f.w, f.h, 0, 0, f.w, f.h)
  s.globalCompositeOperation = 'source-over'
  ctx.drawImage(scratch, 0, 0, f.w, f.h, dx, dy, w, h)
}
