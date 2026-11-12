import { describe, expect, it } from 'vitest'
import { isKey, useReplay } from './useReplay'
import type { Tick } from '../api/sim'

const tick = (n: number, kind: string, events: any[] = []) => ({ tick: n, minute: [n, 0], score: { home: 0, away: 0 }, events, moment: { kind, ms: 3000 } }) as unknown as Tick

describe('useReplay', () => {
  it('keeps the goals and the big moments, and only the saves from big chances', () => {
    expect(isKey(tick(1, 'goal'))).toBe(true)
    expect(isKey(tick(2, 'red'))).toBe(true)
    expect(isKey(tick(3, 'quiet'))).toBe(false)
    expect(isKey(tick(4, 'save', [{ type: 'attack', quality: 'normal' }]))).toBe(false)
    expect(isKey(tick(5, 'save', [{ type: 'attack', quality: 'big' }]))).toBe(true)
  })

  it('shows the missed goals one after another, in order and once each while waiting', () => {
    const r = useReplay()
    const goal = (n: number, kind?: string) => ({ tick: n, minute: n, events: [{ type: 'goal', team: 'home', kind } as any] })
    r.missedGoal(goal(30), { home: 1, away: 0 })
    r.missedGoal(goal(12, 'penalty'), { home: 1, away: 0 })
    r.missedGoal(goal(12, 'penalty'), { home: 1, away: 0 })
    r.missedGoal({ tick: 40, minute: 40, events: [] }, { home: 1, away: 0 })
    expect([r.replayTick.value?.tick, r.replayMissed.value]).toEqual([30, true])
    r.nextReplay()
    expect([r.replayTick.value?.tick, r.replayTick.value?.moment?.kind, r.replayMissed.value]).toEqual([12, 'penalty', true])
    r.nextReplay()
    expect([r.replayTick.value, r.replayMissed.value]).toEqual([null, false])
  })
})
