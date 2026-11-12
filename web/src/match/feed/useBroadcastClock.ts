// [X35, Sprint 42 G1, Sprint 57 W3] The broadcast clock on the feed: minutes and seconds running through each minute as
// on TV, frozen at the moment's second while the clip plays (clock.ts says when), the half, and how far the match has
// gone. [Sprint 42 I1] Written straight into its places (the scorebar, the strap, the bar), never through the template:
// it changes almost every frame while a quiet minute runs, and a render of the whole feed for it made it stutter.
// And how close the ball is to a goal, in tenths, for the crowd's sound [Sprint 31 D4] (the server's Keyframes).
import { onMounted, ref, watch, type Ref } from 'vue'
import { t as tr } from '../../lib/i18n'
import { sample } from '../frames'
import type { Tick } from '../../api/sim'
import { clockAt, type Timing } from './clock'

const HALVES = { first: 'الشوط الأول', second: 'الشوط الثاني', extra: 'الوقت الإضافي', shootout: 'ركلات الترجيح' }

export function useBroadcastClock(at: { a: Ref<HTMLElement | undefined>; b: Ref<HTMLElement | undefined>; bar: Ref<HTMLElement | undefined> }, minute: () => string, onNear: (closeness: number) => void) {
  const frozen = ref(false)
  const half = ref('')
  let clock = '', shown = '', shownAt = 0, progShown = -1, nearSent = -1, frozenWas = false

  function show(text: string, force = false) {
    const now = performance.now()
    // At most a dozen times a second: a quiet minute passes in one second, so its seconds are a blur anyway.
    if (text === shown || (!force && now - shownAt < 80)) return
    shown = text; shownAt = now
    for (const e of [at.a.value, at.b.value]) if (e) e.textContent = text
  }
  watch(minute, (m) => { if (!clock) show(m, true) })
  onMounted(() => show(clock || minute(), true))

  /** The minute at u (0..1 of it), with its scene's timing. */
  function tick(t: Tick, u: number, p: Timing) {
    const f = t?.frames
    const ball = f?.length ? sample(f, u)?.ball : null
    const near = ball ? Math.round(Math.max(0, Math.min(1, (Math.abs(ball[0] - 525) - 200) / 300)) * 10) / 10 : nearSent
    if (near !== nearSent) { nearSent = near; onNear(near) }
    const m = t?.minute
    if (!m || t.moment?.kind === 'shootout') { clock = ''; show(minute(), true); frozen.value = false; return }
    const c = clockAt(m, t.tick, u, p)
    if (frozen.value !== c.frozen) frozen.value = c.frozen
    half.value = tr(HALVES[c.half])
    // The bar by transform, not width: no layout for it.
    if (c.progress !== progShown && at.bar.value) { progShown = c.progress; at.bar.value.style.transform = `scaleX(${c.progress})` }
    clock = c.text
    show(c.text, c.frozen !== frozenWas)
    frozenWas = c.frozen
  }

  return { frozen, half, tick, shown: () => shown || minute() }
}
