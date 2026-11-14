// [Sprint 30 G2] A match's result as a picture to share (WhatsApp, Instagram…): drawn in the browser on a canvas (the
// browser shapes Arabic, a server's image library does not), in Legends' colours, with the score, the two clubs in
// their colours, the scorers and the brand. Shared with the phone's share sheet when it takes files, else downloaded.
import { locale, t } from './i18n'

export type ShareSide = { name: string; color: string; logo?: string | null }
export type ShareResult = {
  home: ShareSide
  away: ShareSide
  score: { home: number; away: number }
  caption?: string
  scorers?: { home: string[]; away: string[] }
}

const W = 1080
const H = 1080

function loadImage(src: string): Promise<HTMLImageElement | null> {
  return new Promise((resolve) => {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => resolve(img)
    img.onerror = () => resolve(null)
    img.src = src
  })
}

function fit(ctx: CanvasRenderingContext2D, text: string, max: number, size: number, weight = 800): void {
  let s = size
  do {
    ctx.font = `${weight} ${s}px Tajawal, sans-serif`
  } while (ctx.measureText(text).width > max && (s -= 2) > 18)
}

export async function drawResultCard(r: ShareResult): Promise<Blob> {
  await document.fonts?.ready
  const c = document.createElement('canvas')
  c.width = W
  c.height = H
  const ctx = c.getContext('2d')!
  // The night ink with an emerald glow, and each club's colour rising from its side.
  const bg = ctx.createLinearGradient(0, 0, 0, H)
  bg.addColorStop(0, '#0F2A3D')
  bg.addColorStop(1, '#071321')
  ctx.fillStyle = bg
  ctx.fillRect(0, 0, W, H)
  for (const [side, x] of [
    ['home', W * 0.78],
    ['away', W * 0.22],
  ] as const) {
    const g = ctx.createRadialGradient(x, 470, 20, x, 470, 380)
    g.addColorStop(0, r[side].color + 'AA')
    g.addColorStop(1, 'transparent')
    ctx.fillStyle = g
    ctx.fillRect(0, 0, W, H)
  }
  ctx.fillStyle = '#F5B82E'
  ctx.fillRect(0, 0, W, 10)
  ctx.direction = 'rtl'
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  // The caption (the competition, «نهاية المباراة»).
  ctx.fillStyle = '#CFE9DF'
  ctx.font = '700 40px Tajawal, sans-serif'
  ctx.fillText(r.caption ?? t('نهاية المباراة'), W / 2, 120)
  // The crests (or a disc in the club's colour), the names under them; home on the right in Arabic.
  const homeX = locale.value === 'ar' ? W * 0.78 : W * 0.22
  const awayX = W - homeX
  for (const [side, x] of [
    ['home', homeX],
    ['away', awayX],
  ] as const) {
    ctx.fillStyle = '#F4EFE4'
    ctx.beginPath()
    ctx.arc(x, 400, 120, 0, Math.PI * 2)
    ctx.fill()
    const img = r[side].logo ? await loadImage(r[side].logo!) : null
    if (img) {
      const k = Math.min(170 / img.width, 170 / img.height)
      ctx.drawImage(img, x - (img.width * k) / 2, 400 - (img.height * k) / 2, img.width * k, img.height * k)
    } else {
      ctx.fillStyle = r[side].color
      ctx.beginPath()
      ctx.arc(x, 400, 90, 0, Math.PI * 2)
      ctx.fill()
    }
    ctx.fillStyle = '#FFFFFF'
    fit(ctx, r[side].name, 380, 52)
    ctx.fillText(r[side].name, x, 590)
  }
  // The score, big, in the middle (left to right, the home side on the right in Arabic).
  ctx.direction = 'ltr'
  ctx.fillStyle = '#F5B82E'
  ctx.font = '800 170px "Barlow Condensed", Tajawal, sans-serif'
  const score = locale.value === 'ar' ? `${r.score.away} - ${r.score.home}` : `${r.score.home} - ${r.score.away}`
  ctx.fillText(score, W / 2, 410)
  // The scorers under each side: Latin names and minutes, drawn left to right (the minute's mark stays after it).
  ctx.direction = 'ltr'
  ctx.fillStyle = '#C9D2E1'
  for (const [side, x] of [
    ['home', homeX],
    ['away', awayX],
  ] as const) {
    ;(r.scorers?.[side] ?? []).slice(0, 4).forEach((n, i) => {
      fit(ctx, `⚽ ${n}`, 400, 34, 600)
      ctx.fillText(`⚽ ${n}`, x, 670 + i * 50)
    })
  }
  // The brand at the foot.
  ctx.direction = 'rtl'
  ctx.fillStyle = '#F5B82E'
  ctx.fillRect(0, H - 130, W, 2)
  ctx.font = '900 54px Tajawal, sans-serif'
  ctx.fillText(t('المدرب الأسطورة'), W / 2, H - 70)
  return new Promise((resolve) => c.toBlob((b) => resolve(b!), 'image/png'))
}

/** Shares the picture with the phone's share sheet when it takes files, else downloads it. */
export async function shareResult(r: ShareResult, fileName = 'legends-result.png'): Promise<'shared' | 'downloaded' | 'cancelled'> {
  const blob = await drawResultCard(r)
  const file = new File([blob], fileName, { type: 'image/png' })
  const title = `${r.home.name} ${r.score.home} - ${r.score.away} ${r.away.name}`
  if (navigator.canShare?.({ files: [file] })) {
    try {
      await navigator.share({ files: [file], title, text: title })
      return 'shared'
    } catch {
      return 'cancelled'
    }
  }
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = fileName
  a.click()
  setTimeout(() => URL.revokeObjectURL(a.href), 4000)
  return 'downloaded'
}
