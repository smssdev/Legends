// Match sound, synthesized with Web Audio (docs/MATCH_VIEW.md 5): a crowd bed
// that follows attack danger, reactions, whistles and ball strikes. No audio
// files, so nothing to license. Starts only after a user gesture.

export class MatchSound {
  private ctx: AudioContext | null = null
  private crowd: GainNode | null = null
  // The crowd goes down while the commentator talks, and back after [MATCH_VIEW 5, Sprint 35].
  private duckGain: GainNode | null = null
  private chanting = 0
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
    this.duckGain = ctx.createGain()
    src.connect(band).connect(this.crowd).connect(this.duckGain).connect(this.master)
    src.start()
    // [X41] The real crowd of a stadium (public/sfx/crowd-bed.mp3, the pauses of the commentator's recording, made
    // by tools/commentary/crowd_bed.py) takes the synthesized noise's place once it has loaded; same gains, so it
    // still rises with danger and steps back under the commentator.
    void fetch(import.meta.env.BASE_URL + 'sfx/crowd-bed.mp3')
      .then((r) => (r.ok ? r.arrayBuffer() : Promise.reject(r.status)))
      .then((b) => ctx.decodeAudioData(b))
      .then((buf) => {
        if (this.ctx !== ctx || !this.crowd) return
        const real = ctx.createBufferSource()
        real.buffer = buf
        real.loop = true
        const lift = ctx.createGain()
        lift.gain.value = 3.2
        real.connect(lift).connect(this.crowd)
        real.start(0, Math.random() * buf.duration)
        src.stop(ctx.currentTime + 0.4)
      })
      .catch(() => { /* no file: the synthesized crowd stays */ })
  }

  /** The commentator starts or stops talking: the crowd steps back under his voice. */
  duck(talking: boolean) {
    if (!this.duckGain || !this.ctx) return
    this.duckGain.gain.setTargetAtTime(talking ? 0.45 : 1, this.ctx.currentTime, talking ? 0.08 : 0.5)
  }

  /**
   * A chant from the stands: hands clapping a 3-and-2 rhythm, a few bars long. Made
   * here like the rest of the crowd, so there is nothing to license. Ducked with the crowd under the commentator.
   */
  chant(after = 0, bars = 3) {
    if (!this.ctx || !this.duckGain || this.chanting > this.ctx.currentTime + after) return
    const ctx = this.ctx
    const beat = 0.32
    const start = ctx.currentTime + 0.05 + after
    const length = bars * 8 * beat
    this.chanting = start + length
    // [UP18] No music in a match (the owner's spec, 12): the stands clap, nothing hums a tune under the game.
    // The hands: noise bursts on the 3-and-2 rhythm of every bar.
    const noise = ctx.createBuffer(1, ctx.sampleRate * 0.08, ctx.sampleRate)
    const d = noise.getChannelData(0)
    for (let i = 0; i < d.length; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / d.length)
    for (let b = 0; b < bars; b++) {
      for (const step of [0, 2, 4, 5, 6]) {
        const t = start + (b * 8 + step) * beat
        const src = ctx.createBufferSource()
        src.buffer = noise
        const band = ctx.createBiquadFilter()
        band.type = 'bandpass'
        band.frequency.value = 1600
        const g = ctx.createGain()
        g.gain.value = 0.35
        src.connect(band).connect(g).connect(this.duckGain)
        src.start(t)
      }
    }
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

  /** A heartbeat before a penalty: two low thumps. */
  heart() {
    if (!this.ctx || !this.master) return
    for (const [d, g] of [[0, 0.55], [0.18, 0.4]]) {
      const t = this.ctx.currentTime + d
      const osc = this.ctx.createOscillator()
      const gain = this.ctx.createGain()
      osc.frequency.setValueAtTime(70, t)
      osc.frequency.exponentialRampToValueAtTime(40, t + 0.16)
      gain.gain.setValueAtTime(g, t)
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.2)
      osc.connect(gain).connect(this.master)
      osc.start(t)
      osc.stop(t + 0.25)
    }
  }

  /** The ball hits the post: a short metallic ring. */
  post() {
    if (!this.ctx || !this.master) return
    const t = this.ctx.currentTime
    for (const f of [1180, 1730, 2650]) {
      const osc = this.ctx.createOscillator()
      const gain = this.ctx.createGain()
      osc.frequency.value = f
      gain.gain.setValueAtTime(0.08, t)
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.6)
      osc.connect(gain).connect(this.master)
      osc.start(t)
      osc.stop(t + 0.65)
    }
  }

  /** A friend's reaction arrives: a soft pop. */
  pop() {
    if (!this.ctx || !this.master) return
    const t = this.ctx.currentTime
    const osc = this.ctx.createOscillator()
    const gain = this.ctx.createGain()
    osc.frequency.setValueAtTime(520, t)
    osc.frequency.exponentialRampToValueAtTime(980, t + 0.08)
    gain.gain.setValueAtTime(0.12, t)
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.14)
    osc.connect(gain).connect(this.master)
    osc.start(t)
    osc.stop(t + 0.16)
  }

  stop() {
    this.ctx?.close()
    this.ctx = null
  }
}
