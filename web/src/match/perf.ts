// The match screen's QualityTier (README 7.7) [X30, three tiers since Sprint 33 Q1]: how much the cartoon simulator
// draws. 'low' (smooth) is for weak phones: no glass, glow, beams, trails, nets or captions, a third of the crowd, the
// pitch and scenes at 30 frames a second and at the screen's plain density, and no slow-motion replay. 'mid'
// (balanced) is for mid-range phones: everything but the costliest (the ball's trail, the second floodlight shadow,
// the replay's confetti), at most 1.5 pixels a point and half the crowd. 'high' (full) is for strong phones and
// laptops: all of it. Auto picks from what the device says of itself, then steps down one tier at a time when the
// frames fall behind during a match. The coach can force any of the three. It changes the drawing, never the timing.
import { storage } from '../lib/storage'
import { computed, ref, watch } from 'vue'

export type PerfPref = 'auto' | 'smooth' | 'balanced' | 'full'
export type Tier = 'low' | 'mid' | 'high'
const KEY = 'perf'

function readPref(): PerfPref {
  try {
    const v = storage.get(KEY)
    return v === 'smooth' || v === 'balanced' || v === 'full' ? v : 'auto'
  } catch {
    return 'auto'
  }
}

type Nav = Navigator & { deviceMemory?: number; connection?: { saveData?: boolean } }

/** What the device says of itself: little memory, few cores, data saving, or less motion asked for. */
export function weakDevice(): boolean {
  if (typeof navigator === 'undefined') return false
  const nav = navigator as Nav
  const reduced = typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches
  return (nav.deviceMemory !== undefined && nav.deviceMemory <= 4)
    || (nav.hardwareConcurrency !== undefined && nav.hardwareConcurrency <= 4)
    || !!nav.connection?.saveData
    || reduced
}

/** [Sprint 33 Q1] A mid-range device: not weak, but a phone with up to 6 GB or 6 cores. */
export function midDevice(): boolean {
  if (typeof navigator === 'undefined' || weakDevice()) return false
  const nav = navigator as Nav
  const phone = typeof matchMedia === 'function' && matchMedia('(pointer: coarse)').matches
  return phone && ((nav.deviceMemory !== undefined && nav.deviceMemory <= 6) || (nav.hardwareConcurrency !== undefined && nav.hardwareConcurrency <= 6))
}

const deviceTier = (): Tier => (weakDevice() ? 'low' : midDevice() ? 'mid' : 'high')
const PREF_TIER: Record<Exclude<PerfPref, 'auto'>, Tier> = { smooth: 'low', balanced: 'mid', full: 'high' }

export const perfPref = ref<PerfPref>(readPref())
// In auto: the device's tier, lowered by the frames that fell behind during this visit.
const autoTier = ref<Tier>(deviceTier())
/** The tier the match draws at now. */
export const tier = computed<Tier>(() => (perfPref.value === 'auto' ? autoTier.value : PREF_TIER[perfPref.value]))
/** The lowest tier (the smooth mode of X30), on or off: what most of the page asks. */
export const smooth = ref(tier.value === 'low')
watch(tier, (t) => { smooth.value = t === 'low' })

// The whole app follows it (the cards' blurred glass, style.css): a class on the page's root.
watch(smooth, (v) => { if (typeof document !== 'undefined') document.documentElement.classList.toggle('smooth', v) }, { immediate: true })

export function setPerfPref(p: PerfPref) {
  perfPref.value = p
  try { storage.set(KEY, p) } catch { /* private mode: for this visit only */ }
}

// Watching the frames while the match plays: two seconds of frames averaging over 28 ms (under 36 a second) lower
// the auto tier by one, for the rest of the visit; it waits two more seconds before it may lower it again.
let sum = 0
let count = 0
export function noteFrame(ms: number) {
  if (perfPref.value !== 'auto' || autoTier.value === 'low') return
  sum += Math.min(ms, 200)
  count++
  if (sum >= 2000) {
    if (sum / count > 28) autoTier.value = autoTier.value === 'high' ? 'mid' : 'low'
    sum = 0
    count = 0
  }
}
