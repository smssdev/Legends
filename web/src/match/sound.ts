// Match sound, synthesized with Web Audio (docs/MATCH_VIEW.md 5): a crowd bed
// that follows attack danger, reactions, whistles and ball strikes. No audio
// files, so nothing to license. Starts only after a user gesture.

export class MatchSound {
  private ctx: AudioContext | null = null
  private crowd: GainNode | null = null
  private master: GainNode | null = null
  muted = false

  start() {
    if (this.ctx) return
    const ctx = new AudioContext()
    this.ctx = ctx
    this.master = ctx.createGain()
    this.master.gain.value = 0.6
    this.master.connect(ctx.destination)

    // Crowd bed: brown noise through a band-pass filter.
    const buffer = ctx.createBuffer(1, ctx.sampleRate * 4, ctx.sampleRate)
    const data = buffer.getChannelData(0)
    let last = 0
    for (let i = 0; i < data.length; i++) {
      last = (last + 0.02 * (Math.random() * 2 - 1)) / 1.02
      data[i] = last * 3.5
    }
    const src = ctx.createBufferSource()
    src.buffer = buffer
    src.loop = true
    const band = ctx.createBiquadFilter()
    band.type = 'bandpass'
    band.frequency.value = 700
    band.Q.value = 0.6
    this.crowd = ctx.createGain()
    this.crowd.gain.value = 0.25
    src.connect(band).connect(this.crowd).connect(this.master)
    src.start()
  }

  setMuted(muted: boolean) {
    this.muted = muted
    if (this.master && this.ctx) this.master.gain.setTargetAtTime(muted ? 0 : 0.6, this.ctx.currentTime, 0.1)
  }

  /** Crowd level follows how dangerous the moment is (0..5). */
  danger(level: number) {
    if (!this.crowd || !this.ctx) return
    this.crowd.gain.setTargetAtTime(0.18 + Math.min(5, Math.abs(level)) * 0.08, this.ctx.currentTime, 0.4)
  }

  roar(seconds = 2.5) {
    if (!this.crowd || !this.ctx) return
    const t = this.ctx.currentTime
    this.crowd.gain.cancelScheduledValues(t)
    this.crowd.gain.setTargetAtTime(1.1, t, 0.05)
    this.crowd.gain.setTargetAtTime(0.3, t + seconds, 0.8)
  }

  groan() {
    if (!this.crowd || !this.ctx) return
    const t = this.ctx.currentTime
    this.crowd.gain.setTargetAtTime(0.7, t, 0.05)
    this.crowd.gain.setTargetAtTime(0.25, t + 0.8, 0.5)
  }

  whistle(blasts = 1) {
    if (!this.ctx || !this.master) return
    for (let i = 0; i < blasts; i++) {
      const t = this.ctx.currentTime + i * 0.45
      const osc = this.ctx.createOscillator()
      const lfo = this.ctx.createOscillator()
      const lfoGain = this.ctx.createGain()
      const gain = this.ctx.createGain()
      osc.frequency.value = 2800
      lfo.frequency.value = 28
      lfoGain.gain.value = 120
      lfo.connect(lfoGain).connect(osc.frequency)
      gain.gain.setValueAtTime(0, t)
      gain.gain.linearRampToValueAtTime(0.12, t + 0.02)
      gain.gain.setValueAtTime(0.12, t + (blasts > 1 && i === blasts - 1 ? 0.7 : 0.3))
      gain.gain.linearRampToValueAtTime(0, t + (blasts > 1 && i === blasts - 1 ? 0.8 : 0.35))
      osc.connect(gain).connect(this.master)
      osc.start(t)
      lfo.start(t)
      osc.stop(t + 0.9)
      lfo.stop(t + 0.9)
    }
  }

  kick(strong = false) {
    if (!this.ctx || !this.master) return
    const t = this.ctx.currentTime
    const osc = this.ctx.createOscillator()
    const gain = this.ctx.createGain()
    osc.frequency.setValueAtTime(strong ? 160 : 220, t)
    osc.frequency.exponentialRampToValueAtTime(50, t + 0.12)
    gain.gain.setValueAtTime(strong ? 0.5 : 0.25, t)
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.15)
    osc.connect(gain).connect(this.master)
    osc.start(t)
    osc.stop(t + 0.2)
  }

  stop() {
    this.ctx?.close()
    this.ctx = null
  }
}
