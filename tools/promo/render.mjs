// The promo video [2026-11-15]: stage.html taken frame by frame (30 a second) into ffmpeg, with music.py's sound.
//   python3 tools/promo/prepare.py && python3 tools/promo/music.py && node tools/promo/render.mjs [wide|tall|both]
//   PREVIEW="0,2,5.5" node tools/promo/render.mjs wide  → stills at those seconds, no video.
// Into tools/promo/out/: glm-promo-wide.mp4 (1920x1080) and glm-promo-tall.mp4 (1080x1920).
import { createRequire } from 'node:module'
import { spawn } from 'node:child_process'
import { existsSync } from 'node:fs'

const require = createRequire(new URL('../../web/package.json', import.meta.url))
const { chromium } = require('playwright')
const DIR = new URL('.', import.meta.url).pathname
const FPS = 30, SECONDS = 40
const which = process.argv[2] ?? 'both'
const formats = which === 'both' ? ['wide', 'tall'] : [which]
const browser = await chromium.launch(process.env.PW_CHROMIUM ? { executablePath: process.env.PW_CHROMIUM } : {})

for (const format of formats) {
  const [w, h] = format === 'tall' ? [1080, 1920] : [1920, 1080]
  const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 })
  await page.goto('file://' + DIR + 'stage.html?format=' + format)
  await page.evaluate(() => window.ready)
  if (process.env.PREVIEW) {
    for (const s of process.env.PREVIEW.split(',')) {
      await page.evaluate((t) => window.render(t), Number(s))
      await page.screenshot({ path: `${DIR}out/preview-${format}-${s}.jpg`, type: 'jpeg', quality: 85 })
    }
    console.log('previews', format)
    continue
  }
  const audio = DIR + 'out/music.wav'
  const outFile = `${DIR}out/glm-promo-${format}.mp4`
  const ff = spawn('ffmpeg', [
    '-y', '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'mjpeg', '-i', '-',
    ...(existsSync(audio) ? ['-i', audio, '-c:a', 'aac', '-b:a', '192k', '-shortest'] : []),
    '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', outFile,
  ], { stdio: ['pipe', 'ignore', 'inherit'] })
  for (let f = 0; f < FPS * SECONDS; f++) {
    await page.evaluate((t) => window.render(t), f / FPS)
    const buf = await page.screenshot({ type: 'jpeg', quality: 95 })
    if (!ff.stdin.write(buf)) await new Promise((r) => ff.stdin.once('drain', r))
    if (f % 150 === 0) console.log(format, f / FPS, 's')
  }
  ff.stdin.end()
  await new Promise((r) => ff.on('close', r))
  console.log('written', outFile)
  await page.close()
}
await browser.close()
