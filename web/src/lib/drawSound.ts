// [Sprint 29] The draw's sound, all made here with Web Audio (no files, nothing paid): a drum roll that quickens while
// the ball is held, a cymbal and a brass chord when it opens, and the team's name in the screen's language from the
// browser's own voice (speechSynthesis). Silent until the viewer turns it on (browsers allow sound only after a tap).
import { locale } from './i18n'

let ctx: AudioContext | null = null
let noise: AudioBuffer | null = null

export function soundOn(): boolean {
  try {
    ctx ??= new AudioContext()
    void ctx.resume()
    if (!noise) {
      noise = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate)
      const d = noise.getChannelData(0)
      for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1
    }
    return true
  } catch {
    return false
  }
}

export function soundOff(): void {
  try { speechSynthesis.cancel() } catch { /* no voice */ }
  void ctx?.suspend()
}

function hit(at: number, gain: number, freq: number, length = 0.12) {
  if (!ctx || !noise) return
  const src = ctx.createBufferSource()
  src.buffer = noise
  const f = ctx.createBiquadFilter()
  f.type = 'bandpass'
  f.frequency.value = freq
  const g = ctx.createGain()
  g.gain.setValueAtTime(gain, at)
  g.gain.exponentialRampToValueAtTime(0.001, at + length)
  src.connect(f).connect(g).connect(ctx.destination)
  src.start(at, Math.random() * 0.5, length + 0.05)
  // The drum's body under the snare.
  const o = ctx.createOscillator()
  const og = ctx.createGain()
  o.frequency.setValueAtTime(110, at)
  o.frequency.exponentialRampToValueAtTime(55, at + length)
  og.gain.setValueAtTime(gain * 0.6, at)
  og.gain.exponentialRampToValueAtTime(0.001, at + length)
  o.connect(og).connect(ctx.destination)
  o.start(at)
  o.stop(at + length + 0.02)
}

/** The roll while the ball is held: from 6 to 22 hits a second over `seconds`, louder as it goes. */
export function drumRoll(seconds: number): void {
  if (!ctx || ctx.state !== 'running') return
  const start = ctx.currentTime
  let t = start
  while (t < start + seconds) {
    const p = (t - start) / seconds
    hit(t, 0.12 + 0.25 * p, 900 + 600 * p, 0.08)
    t += 1 / (6 + 16 * p)
  }
}

/** The opening: a cymbal crash and a short rising brass chord. */
export function reveal(): void {
  if (!ctx || !noise || ctx.state !== 'running') return
  const at = ctx.currentTime
  const src = ctx.createBufferSource()
  src.buffer = noise
  const hp = ctx.createBiquadFilter()
  hp.type = 'highpass'
  hp.frequency.value = 5000
  const g = ctx.createGain()
  g.gain.setValueAtTime(0.35, at)
  g.gain.exponentialRampToValueAtTime(0.001, at + 1.6)
  src.connect(hp).connect(g).connect(ctx.destination)
  src.start(at, 0, 1.7)
  hit(at, 0.5, 200, 0.25)
  for (const [i, f] of [261.6, 329.6, 392, 523.3].entries()) {
    const o = ctx.createOscillator()
    o.type = 'sawtooth'
    const lp = ctx.createBiquadFilter()
    lp.type = 'lowpass'
    lp.frequency.setValueAtTime(800, at)
    lp.frequency.linearRampToValueAtTime(2400, at + 0.3)
    const og = ctx.createGain()
    const s = at + i * 0.06
    og.gain.setValueAtTime(0, s)
    og.gain.linearRampToValueAtTime(0.07, s + 0.05)
    og.gain.exponentialRampToValueAtTime(0.001, s + 1.1)
    o.frequency.value = f
    o.connect(lp).connect(og).connect(ctx.destination)
    o.start(s)
    o.stop(s + 1.2)
  }
}

/** Say a line in the screen's language with the browser's voice; a missing voice says nothing. */
export function announce(text: string): void {
  if (!ctx || ctx.state !== 'running') return
  try {
    speechSynthesis.cancel()
    const u = new SpeechSynthesisUtterance(text)
    const lang = locale.value === 'en' ? 'en' : 'ar'
    u.lang = lang === 'en' ? 'en-GB' : 'ar-SA'
    const voice = speechSynthesis.getVoices().find((v) => v.lang.toLowerCase().startsWith(lang))
    if (voice) u.voice = voice
    u.rate = 0.95
    u.pitch = 1.05
    u.volume = 1
    speechSynthesis.speak(u)
  } catch { /* no voice on this browser */ }
}
