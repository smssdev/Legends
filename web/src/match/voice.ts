// The English commentator (docs/PLAN.md 2.21). Lines are joined at play time from
// clips recorded with a free neural voice (tools/commentary/generate.py): every
// phrase calm and excited, and per club its name and its players' surnames.
// A club without clips falls back to the browser's own voice for that line.
// A line is never cut mid-sentence: lines queue, and a big moment only clears
// the lines still waiting.

export type Part = { key: string; club?: string }
export type Line = { text: string; parts: Part[]; excited: boolean }
type Pack = { buf: AudioBuffer; map: Record<string, [number, number]> }

// Keep these three in step with tools/commentary/generate.py.
export function slug(name: string) {
  return name.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '')
}
export function phraseKey(text: string) {
  return text.replace(/^[\s!.,?…]+/, '').replace(/\s+/g, ' ').trim()
}
const PARTICLES = new Set(['de', 'da', 'di', 'do', 'dos', 'van', 'von', 'der', 'den', 'ten', 'le', 'la', 'el', 'al', 'ben', 'mac', 'bin'])
export function surname(full: string) {
  const w = String(full).trim().split(/\s+/)
  if (w.length < 2 || /^(j(ú|u)nior|jr\.?)$/i.test(w[w.length - 1])) return w.join(' ')
  let i = w.length - 1
  while (i > 0 && PARTICLES.has(w[i - 1].toLowerCase())) i--
  return w.slice(i).join(' ')
}

const BASE = import.meta.env.BASE_URL + 'commentary/'
const GAP = 0.07

export class Commentator {
  on = false
  private ctx: AudioContext | null = null
  private out: GainNode | null = null
  private phrases: Promise<Pack | null> | null = null
  private wanted: string[] = []
  private packs = new Map<string, Promise<Pack | null>>()
  private ready = new Map<string, Pack | null>()
  private queue: Line[] = []
  private busy = false
  private sources: AudioBufferSourceNode[] = []
  private timer = 0
  private utter: SpeechSynthesisUtterance | null = null
  private synthVoice: SpeechSynthesisVoice | null = null
  private readonly synth = typeof window !== 'undefined' ? window.speechSynthesis : undefined

  constructor() {
    if (!this.synth) return
    const pick = () => {
      const vs = this.synth!.getVoices()
      this.synthVoice = vs.find((v) => /en-GB/i.test(v.lang) && /male|daniel|george|arthur|ryan/i.test(v.name)) ?? vs.find((v) => /en-GB/i.test(v.lang)) ?? vs.find((v) => /^en/i.test(v.lang)) ?? null
    }
    pick()
    this.synth.addEventListener?.('voiceschanged', pick)
  }

  /** Call from a tap: browsers only start audio after one. */
  setOn(on: boolean): void {
    this.on = on
    if (!on) return this.stop()
    if (!this.ctx) {
      this.ctx = new AudioContext()
      this.out = this.ctx.createGain()
      this.out.gain.value = 1.1
      this.out.connect(this.ctx.destination)
    }
    void this.ctx.resume()
    this.phrases ??= this.load('phrases')
    for (const c of this.wanted) this.pack(c)
  }

  /** Fetch the two clubs' names early, before their first line. */
  prepare(clubs: string[]) {
    this.wanted = clubs.map(slug)
    if (this.ctx) for (const c of this.wanted) this.pack(c)
  }

  say(line: Line) {
    if (!this.on || !line.text) return
    if (line.excited) this.queue = []
    else if (this.queue.length) this.queue.shift()
    this.queue.push(line)
    if (!this.busy) this.next()
  }

  stop() {
    this.queue = []
    this.busy = false
    clearTimeout(this.timer)
    for (const s of this.sources) try { s.stop() } catch {}
    this.sources = []
    this.utter = null
    this.synth?.cancel()
  }

  private next(): void {
    const line = this.queue.shift()
    if (!line || !this.on) { this.busy = false; return }
    this.busy = true
    const clips = this.resolve(line)
    if (clips === 'wait') return this.next()
    if (clips) this.play(clips)
    else this.speak(line)
  }

  // The clips for a line, null when one is missing for good (use the browser voice),
  // or 'wait' while a pack is still loading (the line is dropped; it would come late anyway).
  private resolve(line: Line): { pack: Pack; at: [number, number]; rate: number }[] | null | 'wait' {
    const phrases = this.ready.get('phrases')
    if (phrases === undefined) return 'wait'
    const out = []
    for (const p of line.parts) {
      const pack = p.club ? this.ready.get(p.club) : phrases
      if (pack === undefined) { if (p.club) this.pack(p.club); return 'wait' }
      const at = pack?.map[p.club ? p.key : (line.excited ? '!' : '') + p.key]
      if (!pack || !at) return null
      out.push({ pack, at, rate: p.club && line.excited ? 1.07 : 1 })
    }
    return out.length ? out : null
  }

  private play(clips: { pack: Pack; at: [number, number]; rate: number }[]) {
    const ctx = this.ctx!
    let t = ctx.currentTime + 0.03
    this.sources = clips.map(({ pack, at, rate }) => {
      const s = ctx.createBufferSource()
      s.buffer = pack.buf
      s.playbackRate.value = rate
      s.connect(this.out!)
      s.start(t, at[0], at[1])
      t += at[1] / rate + GAP
      return s
    })
    this.timer = window.setTimeout(() => this.next(), (t - ctx.currentTime) * 1000 + 150)
  }

  private speak(line: Line): void {
    if (!this.synth) return this.next()
    // Kept referenced: Chrome stops speech whose utterance gets garbage collected.
    const u = new SpeechSynthesisUtterance(line.text)
    if (this.synthVoice) u.voice = this.synthVoice
    u.lang = this.synthVoice?.lang ?? 'en-GB'
    u.rate = line.excited ? 1.12 : 1
    u.pitch = line.excited ? 1.2 : 1
    u.onend = u.onerror = () => { if (this.utter === u) { this.utter = null; this.next() } }
    this.utter = u
    this.synth.speak(u)
  }

  private pack(name: string) {
    if (!this.packs.has(name)) this.packs.set(name, this.load('clubs/' + name, name))
    return this.packs.get(name)!
  }

  private load(path: string, key = path): Promise<Pack | null> {
    const p = (async () => {
      try {
        const [map, bytes] = await Promise.all([
          fetch(BASE + path + '.json').then((r) => (r.ok ? r.json() : Promise.reject(r.status))),
          fetch(BASE + path + '.mp3').then((r) => (r.ok ? r.arrayBuffer() : Promise.reject(r.status))),
        ])
        return { map, buf: await this.ctx!.decodeAudioData(bytes) }
      } catch {
        return null
      }
    })()
    void p.then((v) => this.ready.set(key, v))
    return p
  }
}
