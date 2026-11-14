// [Sprint 37 R2, Sprint 66 T4] The director's cutaways (director.ts) by tier and by the time left; these checks were
// scripts/feed.mjs, and a change in the director is pinned here.
import { describe, expect, it } from 'vitest'
import { director, type StoryView } from './director'

const tick = { tick: 12, moods: { home: 'joy', away: 'sad' } }
const goal: StoryView = { scene: 'goal', goal: true, side: 'home', data: {} }
const names = (cuts: { name: string }[]) => cuts.map((c) => c.name).join(',')
const story = (scene: string, side: 'home' | 'away', data: Record<string, unknown>): StoryView => ({ scene, side, goal: false, data })

describe('director', () => {
  it('cuts away by the device’s tier: none, the crowd, then both coaches', () => {
    expect(director(goal, tick, 30, 6, { tier: 'low' })).toHaveLength(0)
    expect(names(director(goal, tick, 30, 6, { tier: 'mid' }))).toBe('crowd')
    expect(names(director(goal, tick, 30, 6, { tier: 'high' }))).toBe('crowd,coachReact,coachReact')
  })

  it('shows the coaches in their looks and the server’s moods', () => {
    const [, mine, theirs] = director(goal, tick, 30, 6, { tier: 'high', looks: { home: 'C3' } })
    expect(mine!.data).toMatchObject({ side: 'home', look: 'C3', mood: 'joy' })
    expect(theirs!.data).toMatchObject({ side: 'away', look: 'C2', mood: 'sad' })
    const calm = director(goal, { tick: 12, moods: { home: 'idle' } }, 30, 6, { tier: 'high' })
    expect([calm[1]!.data.mood, calm[2]!.data.mood]).toEqual(['joy', 'angry'])
  })

  it('keeps only what fits, with 4.5 s for a goal’s replay', () => {
    expect(director(goal, tick, 6 + 2.6 + 4.5, 6, { tier: 'high' })).toHaveLength(1)
    expect(director(goal, tick, 6 + 2.3 + 4.5, 6, { tier: 'high' })).toHaveLength(0)
  })

  it('tells cards: the brawl then the coach for a red, nothing for a yellow on mid', () => {
    expect(names(director(story('card', 'away', { type: 'red' }), tick, 30, 4.4, { tier: 'high' }))).toBe('brawl,coachReact')
    expect(director(story('card', 'away', { type: 'yellow' }), tick, 30, 4.4, { tier: 'mid' })).toHaveLength(0)
    for (const drama of ['brawl', 'spit'])
      expect(names(director(story('card', 'away', { type: 'red', drama }), tick, 30, 6.6, { tier: 'high' })), drama).toBe('coachReact')
    expect(names(director(story('card', 'away', { type: 'red', drama: 'tackle' }), tick, 30, 6.6, { tier: 'high' }))).toBe(
      'brawl,coachReact',
    )
  })

  it('tells misses, whistles and VAR', () => {
    expect(names(director(story('miss', 'home', { how: 'over' }), tick, 30, 5, { tier: 'mid' }))).toBe('meltdown')
    expect(names(director(story('miss', 'home', { how: 'wide' }), tick, 30, 5, { tier: 'mid' }))).toBe('coachReact')
    expect(names(director(story('whistle', 'home', { name: 'halftime' }), tick, 30, 3.6, { tier: 'high' }))).toBe('tunnel')
    expect(names(director(story('whistle', 'home', { name: 'fulltime' }), tick, 30, 3.6, { tier: 'high' }))).toBe(
      'handshake,coachReact,coachReact',
    )
    expect(names(director(story('var', 'home', {}), tick, 30, 8.2, { tier: 'high' }))).toBe('coachReact,coachReact')
    expect(director({ scene: null, side: 'home', goal: false, data: {} }, tick, 30, 0, { tier: 'high' })).toHaveLength(0)
  })

  it('gives every screen the same cutaways for the same seed', () => {
    expect(director(goal, tick, 30, 6, { tier: 'high', seed: 9 })).toEqual(director(goal, tick, 30, 6, { tier: 'high', seed: 9 }))
  })
})
