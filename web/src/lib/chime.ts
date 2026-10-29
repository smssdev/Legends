// [Sprint 24 W3] A short rising chime for a slot opened at once (the owner's "sound and visual effect"), synthesized
// with Web Audio like the match's sound, so no file to license. Played right after the coach's tap; silent where the
// browser has no audio.
export function chime() {
  try {
    const ctx = new AudioContext()
    const master = ctx.createGain()
    master.gain.value = 0.25
    master.connect(ctx.destination)
    // C, E, G, C: four bell notes a little apart, each fading out.
    ;[523.25, 659.25, 783.99, 1046.5].forEach((freq, i) => {
      const at = ctx.currentTime + i * 0.09
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.type = 'triangle'
      osc.frequency.value = freq
      gain.gain.setValueAtTime(0.0001, at)
      gain.gain.exponentialRampToValueAtTime(1, at + 0.02)
      gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.6)
      osc.connect(gain).connect(master)
      osc.start(at)
      osc.stop(at + 0.65)
    })
    setTimeout(() => ctx.close(), 1200)
  } catch {
    // No audio here: the glow is enough.
  }
}
