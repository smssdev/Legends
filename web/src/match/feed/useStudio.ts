// [Sprint 42 H1, Sprint 57 W3] The TV studio between the clips: two commentators at their desk and the clock on the LED
// wall. They take turns (each line said makes the next one talk for a while), a goal puts them on their feet, and back
// from a clip they react to it [Sprint 42 J2]. Drawn at 30 frames a second (20 on a weak phone), not behind a clip.
import type { Ref } from 'vue'
import { theme } from '../../lib/theme'
import { smooth } from '../perf'
import { studio } from './art'
import { reactionKey } from './cues'
import type { Kit, Side } from './kit'
import type { Story } from './told'

/** What the studio shows now: the clock, the score (away - home), and whether a clip covers it or the mic is on. */
export type StudioNow = { clock: string; score: string; frozen: boolean; covered: boolean; talking: boolean }

export function useStudio(host: Ref<HTMLElement | undefined>, kits: () => Record<Side, Kit>, seed: () => number, now: () => StudioNow) {
  let view: ReturnType<typeof studio> | null = null
  let talkTill = 0,
    talker = 1,
    hypeTill = 0,
    drawn = 0
  let reaction: { key: string; seed: number; t0: number } | null = null

  function draw(at: number, force = false) {
    const n = now()
    if (!view || (n.covered && !force) || (!force && at - drawn < (smooth.value ? 48 : 32))) return
    drawn = at
    const hype = Math.max(0, Math.min(1, (hypeTill - at) / 1000))
    try {
      view.update(at / 1000, {
        clock: n.clock,
        score: n.score,
        frozen: n.frozen,
        talk: at < talkTill || n.talking ? talker : 0,
        hype,
        react: reaction,
      })
    } catch (e) {
      console.error(e)
      view = null
    }
  }

  function build() {
    if (!host.value) return
    try {
      view = studio(kits(), seed(), theme.value === 'light')
      host.value.replaceChildren(view.svg)
      draw(performance.now(), true)
    } catch (e) {
      console.error(e)
      view = null
    }
  }

  /** A line said: the other commentator talks next, for a while. */
  function talk() {
    talker = talker === 1 ? 2 : 1
    talkTill = performance.now() + 2600
  }
  /** A goal: on their feet for six seconds. */
  function hype() {
    hypeTill = performance.now() + 6000
  }
  /** Back from a clip: what they react to. */
  function reactTo(s: Story | undefined, tick: number) {
    const key = s ? reactionKey(s) : null
    if (key) reaction = { key, seed: (Number(seed()) || 1) * 31 + tick, t0: performance.now() / 1000 }
  }

  return { build, draw, talk, hype, reactTo }
}
