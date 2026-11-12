// [Sprint 57 W1] The match again: its key moments (the goals and the big ones) after the final whistle, scene by scene,
// and live, the goal again in a small frame while play goes on; back after a gap, the goals missed one after another
// in that frame [X94].
import { ref, shallowRef } from 'vue'
import type { MatchEvent, Side, Tick } from '../api/sim'

const KEY_KINDS = ['goal', 'penalty', 'free_kick', 'red', 'save']

/** A minute worth seeing again: a goal, a penalty, a free kick, a red card, or a save from a big chance. */
export const isKey = (t: Tick) => !!t.moment && KEY_KINDS.includes(t.moment.kind) && (t.moment.kind !== 'save' || t.events.some((e) => e.type === 'attack' && e.quality === 'big'))

export function useReplay() {
  const keyTicks: Tick[] = []
  const replayTick = shallowRef<Tick | null>(null)
  const replayMissed = ref(false)
  const reel: Tick[] = []

  function nextReplay() {
    const t = reel.shift() ?? null
    replayMissed.value = !!t
    replayTick.value = t
  }

  /** A minute with a goal that was over before this screen saw it: into the reel, in order, once. */
  function missedGoal(t: { tick: number; minute: number | [number, number]; events: MatchEvent[] }, score: Record<Side, number>) {
    const goal = t.events.find((e) => e.type === 'goal')
    if (!goal || reel.some((x) => x.tick === t.tick)) return
    const kind = ({ penalty: 'penalty', free_kick: 'free_kick' } as Record<string, string>)[(goal as { kind?: string }).kind ?? 'open'] ?? 'goal'
    reel.push({ ...(t as unknown as Tick), minute: Array.isArray(t.minute) ? t.minute : [t.minute, 0], score, moment: { kind, ms: 0 } } as Tick)
    reel.sort((a, b) => a.tick - b.tick)
    if (!replayTick.value) nextReplay()
  }

  return { keyTicks, replayTick, replayMissed, nextReplay, missedGoal }
}
