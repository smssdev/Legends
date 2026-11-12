import { describe, expect, it, vi } from 'vitest'
import { ref } from 'vue'

vi.mock('../api/sim', () => ({ sim: { ticks: async () => ({ ticks: [] }) }, leagueMatch: {} }))
vi.mock('./commentary', () => ({ line: () => '' }))

import { useMatchPlayer } from './useMatchPlayer'
import { useReplay } from './useReplay'

function make() {
  const play = vi.fn()
  const settle = vi.fn()
  const sound = { danger() {}, chant() {}, whistle: vi.fn() }
  const audio = { sound, voice: { remainingMs: () => 0, stop() {} }, soundOn: ref(true), toggleSound() {} } as any
  const P = useMatchPlayer({ id: '1', league: false, pitch: ref({ play, skip() {}, prepare() {}, react() {} }), audio, replay: useReplay(), orders: () => ({ settle }) as any, speed: 1 })
  P.view.value = { mode: 'solo', timing: { tick_ms: 3000, halftime_seconds: 30 }, clubs: { home: { name: 'A' }, away: { name: 'B' } } } as any
  return { P, play, settle, sound }
}
const goal = { tick: 20, minute: [20, 0], score: { home: 1, away: 0 }, danger: 3, events: [{ type: 'goal', team: 'home', text: 'GOAL' }], moment: { kind: 'goal', ms: 9000 } } as any

describe('useMatchPlayer', () => {
  it('the score changes when the ball crosses the line, and the feed waits for the scene', () => {
    const { P, play, settle } = make()
    P.show(goal)
    expect(play).toHaveBeenCalledWith(goal, undefined)
    expect(P.score.value).toEqual({ home: 0, away: 0 })
    expect(P.feed.value).toHaveLength(0)
    P.onCue('goal')
    expect(P.score.value).toEqual({ home: 1, away: 0 })
    P.onCue('reveal')
    expect(P.feed.value).toEqual([{ minute: "20'", text: 'GOAL', important: true }])
    expect(settle).toHaveBeenCalledWith(goal, "20'")
  })

  it('a minute told at once (no scene) gives its result straight away', () => {
    const { P, play } = make()
    P.show({ ...goal, finished: true }, false)
    expect(play).not.toHaveBeenCalled()
    expect([P.score.value, P.feed.value.length, P.finished.value]).toEqual([{ home: 1, away: 0 }, 1, true])
  })
})
