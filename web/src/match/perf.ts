// The match screen's smooth mode [X30]: on a weak phone the cartoon simulator drops what costs the most for the
// least (blurred glass, SVG glow filters, the crowd's hundreds of dots, the light beams) and draws its scenes at
// 30 frames a second instead of 60, so the moments play without stutter. It turns on by itself from what the
// device says of itself, or when the frames start to fall behind during a match; the coach can force it either way.
import { ref, watch } from 'vue'

export type PerfPref = 'auto' | 'smooth' | 'full'
const KEY = 'legends.perf'

function readPref(): PerfPref {
  try {
    const v = localStorage.getItem(KEY)
    return v === 'smooth' || v === 'full' ? v : 'auto'
  } catch {
    return 'auto'
  }
}

/** What the device says of itself: little memory, few cores, data saving, or less motion asked for. */
export function weakDevice(): boolean {
  if (typeof navigator === 'undefined') return false
  const nav = navigator as Navigator & { deviceMemory?: number; connection?: { saveData?: boolean } }
  const reduced = typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches
  return (nav.deviceMemory !== undefined && nav.deviceMemory <= 4)
    || (nav.hardwareConcurrency !== undefined && nav.hardwareConcurrency <= 4)
    || !!nav.connection?.saveData
    || reduced
}

export const perfPref = ref<PerfPref>(readPref())
/** On when the coach chose it, or (auto) on a weak device or after the frames fell behind. */
export const smooth = ref(perfPref.value === 'smooth' || (perfPref.value === 'auto' && weakDevice()))

// The whole app follows it (the cards' blurred glass, style.css): a class on the page's root.
watch(smooth, (v) => { if (typeof document !== 'undefined') document.documentElement.classList.toggle('smooth', v) }, { immediate: true })

export function setPerfPref(p: PerfPref) {
  perfPref.value = p
  try { localStorage.setItem(KEY, p) } catch { /* private mode: for this visit only */ }
  smooth.value = p === 'smooth' || (p === 'auto' && (weakDevice() || fellBehind))
}

// Watching the frames while a scene plays: two seconds of frames averaging over 28 ms (under 36 a second)
// turn the smooth mode on for the rest of the visit, in auto only.
let fellBehind = false
let sum = 0
let count = 0
export function noteFrame(ms: number) {
  if (perfPref.value !== 'auto' || smooth.value) return
  sum += Math.min(ms, 200)
  count++
  if (sum >= 2000) {
    if (sum / count > 28) {
      fellBehind = true
      smooth.value = true
    }
    sum = 0
    count = 0
  }
}
