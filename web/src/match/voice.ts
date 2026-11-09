// The commentator, in English only (the owner's decision, 2026-10-27: the Arabic commentary is deleted). Lines are
// joined at play time from recorded clips (tools/commentary/generate.py): every phrase in the voice it is said in
// (calm, or excited for the big moments), each club's name and its players' surnames.
// A club without clips falls back to the browser's own voice for that line.
// Calm lines queue and are never cut; a big moment's line (excited) is said at
// once, cutting the line before it short, so the voice stays with the scene.

export type Lang = 'en'
export type Part = { key: string; club?: string }
export type Line = { text: string; parts: Part[]; excited: boolean; lang: Lang }
type Pack = { buf: AudioBuffer; map: Record<string, [number, number]> }
type Clip = { pack: Pack; at: [number, number]; rate: number }

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

/**
 * A commentary line from story.ts as the commentator says it: names become clips of the player's (or club's) pack.
 * vars: {p, q} player ids, A the side the moment belongs to, n a number.
 */
// [Sprint 27 S1] The English commentator never says a word in another script: a name written in Arabic (a club the
// coach named, a player without a Latin name) is left out of what is said, and the line goes on without it.
const LATIN = /^[\p{Script=Latin}\p{M}\p{N}\p{P}\p{S}\s]+$/u
export const sayable = (name: string | undefined | null) => !!name && LATIN.test(name.trim())

export function voiceLine(lang: Lang, l: { en: string | null; x: boolean; vars: any; m?: string; s?: string }, players: Record<string, { name: string; side: string }>, clubs: Record<string, string>): Line | null {
  if (!l.en) return null
  const v = l.vars, other = v.A === 'home' ? 'away' : 'home'
  const parts: Part[] = []
  let text = ''
  for (const piece of l.en.replace(/\{n\}/g, v.n ?? '').split(/(\{[pqAB]\})/)) {
    const m = piece.match(/^\{([pqAB])\}$/)
    if (m && (m[1] === 'A' || m[1] === 'B')) {
      const club = clubs[m[1] === 'A' ? v.A : other]
      if (!sayable(club)) continue
      parts.push({ club: slug(club), key: '@club' })
      text += club
    } else if (m) {
      const p = players[v[m[1]]]
      if (!p || !sayable(p.name)) continue
      parts.push({ club: slug(clubs[p.side]), key: surname(p.name) })
      text += surname(p.name)
    } else {
      text += piece
      if (/[A-Za-z]/.test(phraseKey(piece))) parts.push({ key: phraseKey(piece) })
    }
  }
  return { lang, text, parts, excited: l.x }
}

const BASE = import.meta.env.BASE_URL + 'commentary/'

const GAP = 0.07

export class Commentator {
  on = false
  /** Told when he starts and stops talking, so the crowd can step back [Sprint 35]. */
  onTalk: ((talking: boolean) => void) | null = null
  private ctx: AudioContext | null = null
  private out: GainNode | null = null
  private wanted: string[] = []
  private packs = new Map<string, Promise<Pack | null>>()
  private ready = new Map<string, Pack | null>()
  private queue: Line[] = []
  private busy = false
  private sources: AudioBufferSourceNode[] = []
  private timer = 0
  private endsAt = 0
  private lineGain: GainNode | null = null
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
    this.pack('phrases')
    for (const c of this.wanted) this.pack('clubs/' + c)
  }

  /** Fetch the two clubs' names early, before their first line. */
  prepare(clubs: string[]) {
    this.wanted = clubs.map(slug)
    // [2026-11-09] Only these two clubs' names stay in memory: another match's are let go.
    for (const name of [...this.packs.keys()]) {
      if (name.startsWith('clubs/') && !this.wanted.includes(name.slice(6))) {
        this.packs.delete(name)
        this.ready.delete(name)
      }
    }
    if (this.ctx) for (const c of this.wanted) this.pack('clubs/' + c)
  }

  say(line: Line | null) {
    if (!this.on || !line?.text) return
    // The big call (goal, save) comes the instant the ball gets there: it cuts the build-up short.
    if (line.excited) {
      this.queue = [line]
      if (this.busy) this.cut()
      return this.next()
    }
    if (this.queue.length) this.queue.shift()
    this.queue.push(line)
    if (!this.busy) this.next()
  }

  // A line cut short fades out in a breath instead of stopping mid-word, as a commentator lets a sentence go.
  private cut() {
    clearTimeout(this.timer)
    const now = this.ctx?.currentTime ?? 0
    this.lineGain?.gain.setTargetAtTime(0, now, 0.05)
    for (const s of this.sources) try { s.stop(now + 0.25) } catch {}
    this.sources = []
    this.lineGain = null
    if (this.utter) { this.utter = null; this.synth?.cancel() }
  }

  /** How long until the commentator has finished what he is saying (ms). */
  remainingMs(): number {
    if (!this.busy || !this.ctx) return 0
    const now = this.ctx.currentTime
    let ms = Math.max(0, (this.endsAt - now) * 1000)
    for (const l of this.queue) ms += l.text.length * 65
    return ms
  }

  stop() {
    this.queue = []
    if (this.busy) this.onTalk?.(false)
    this.busy = false
    clearTimeout(this.timer)
    for (const s of this.sources) try { s.stop() } catch {}
    this.sources = []
    this.utter = null
    this.synth?.cancel()
  }

  /**
   * [2026-11-09] The page is gone: silence, then the audio device and the decoded clips let go. Browsers allow only a
   * few AudioContexts at once, so each match page closes its own.
   */
  dispose() {
    this.on = false
    this.stop()
    this.onTalk = null
    this.packs.clear()
    this.ready.clear()
    const ctx = this.ctx
    this.ctx = null
    this.out = null
    this.lineGain = null
    if (ctx && ctx.state !== 'closed') void ctx.close().catch(() => {})
  }

  private next(): void {
    const line = this.queue.shift()
    if (!line || !this.on) {
      if (this.busy) this.onTalk?.(false)
      this.busy = false
      return
    }
    if (!this.busy) this.onTalk?.(true)
    this.busy = true
    const clips = this.resolve(line)
    if (clips === 'wait') return this.next()
    if (clips) this.play(clips)
    else this.speak(line)
  }

  // The clips for a line, null when one is missing for good (use the browser voice),
  // or 'wait' while a pack is still loading (the line is dropped; it would come late anyway).
  private resolve(line: Line): Clip[] | null | 'wait' {
    const out: Clip[] = []
    for (const p of line.parts) {
      const name = p.club ? 'clubs/' + p.club : 'phrases'
      const pack = this.ready.get(name)
      if (pack === undefined) { this.pack(name); return 'wait' }
      const at = pack?.map[p.club ? p.key : (line.excited ? '!' : '') + p.key] ?? pack?.map[p.key]
      if (!pack || !at) return null
      out.push({ pack, at, rate: p.club && line.excited ? 1.07 : 1 })
    }
    return out.length ? out : null
  }

  private play(clips: Clip[]) {
    const ctx = this.ctx!
    let t = ctx.currentTime + 0.03
    // Each line has its own gain, so cutting it fades only this line, never the next one.
    const g = ctx.createGain()
    g.connect(this.out!)
    this.lineGain = g
    this.sources = clips.map(({ pack, at, rate }) => {
      const s = ctx.createBufferSource()
      s.buffer = pack.buf
      s.playbackRate.value = rate
      s.connect(g)
      s.start(t, at[0], at[1])
      t += at[1] / rate + GAP
      return s
    })
    this.endsAt = t
    this.timer = window.setTimeout(() => this.next(), (t - ctx.currentTime) * 1000 + 150)
  }

  private speak(line: Line): void {
    const v = this.synthVoice
    // [Sprint 27 S1] Only an English voice says a line: a phone without one would read it in its own (Arabic) voice.
    if (!this.synth || !v || !sayable(line.text)) return this.next()
    // Kept referenced: Chrome stops speech whose utterance gets garbage collected.
    const u = new SpeechSynthesisUtterance(line.text)
    if (v) u.voice = v
    u.lang = v?.lang ?? 'en-GB'
    u.rate = line.excited ? 1.12 : 1
    u.pitch = line.excited ? 1.2 : 1
    u.onend = u.onerror = () => { if (this.utter === u) { this.utter = null; this.next() } }
    this.utter = u
    this.endsAt = (this.ctx?.currentTime ?? 0) + line.text.length * 0.065
    this.synth.speak(u)
  }

  private pack(name: string) {
    if (!this.packs.has(name) && this.ctx) {
      const p = (async () => {
        try {
          const [map, bytes] = await Promise.all([
            fetch(BASE + name + '.json').then((r) => (r.ok ? r.json() : Promise.reject(r.status))),
            fetch(BASE + name + '.mp3').then((r) => (r.ok ? r.arrayBuffer() : Promise.reject(r.status))),
          ])
          return { map, buf: await this.ctx!.decodeAudioData(bytes) }
        } catch {
          return null
        }
      })()
      this.packs.set(name, p)
      void p.then((v) => this.ready.set(name, v))
    }
    return this.packs.get(name)
  }
}
