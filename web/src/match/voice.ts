// The English commentator's voice (docs/PLAN.md 2.21): the browser's own speech,
// free and offline, with a British voice when the device has one.
// A line is never cut mid-sentence: lines queue, and a big moment only clears
// the lines still waiting. The playing utterance is kept referenced, because
// Chrome stops speech whose utterance object gets garbage collected.
export class Commentator {
  on = false
  private voice: SpeechSynthesisVoice | null = null
  private readonly synth = typeof window !== 'undefined' ? window.speechSynthesis : undefined
  private queue: { text: string; excited: boolean }[] = []
  private current: SpeechSynthesisUtterance | null = null

  constructor() {
    if (!this.synth) return
    const pick = () => {
      const vs = this.synth!.getVoices()
      this.voice = vs.find((v) => /en-GB/i.test(v.lang) && /male|daniel|george|arthur|ryan/i.test(v.name)) ?? vs.find((v) => /en-GB/i.test(v.lang)) ?? vs.find((v) => /^en/i.test(v.lang)) ?? null
    }
    pick()
    this.synth.addEventListener?.('voiceschanged', pick)
  }

  setOn(on: boolean) {
    this.on = on
    if (!on) this.stop()
  }

  say(text: string, excited = false) {
    if (!this.on || !this.synth || !text) return
    if (excited) this.queue = []
    else if (this.queue.length) this.queue.shift()
    this.queue.push({ text, excited })
    if (!this.current) this.next()
  }

  stop() {
    this.queue = []
    this.current = null
    this.synth?.cancel()
  }

  private next() {
    const line = this.queue.shift()
    if (!line || !this.synth) { this.current = null; return }
    const u = new SpeechSynthesisUtterance(line.text)
    if (this.voice) u.voice = this.voice
    u.lang = this.voice?.lang ?? 'en-GB'
    u.rate = line.excited ? 1.12 : 1
    u.pitch = line.excited ? 1.2 : 1
    u.onend = u.onerror = () => { if (this.current === u) this.next() }
    this.current = u
    this.synth.speak(u)
  }
}
