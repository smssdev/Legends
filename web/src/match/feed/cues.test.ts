import { describe, expect, it } from 'vitest'
import { reactionKey, soundsOf } from './cues'
import type { Story } from './told'

const s = (scene: string | null, data: Record<string, unknown> = {}, goal = false) => ({ scene, data, goal }) as unknown as Story

describe('cues', () => {
  it('each scene its sounds, the dramas theirs', () => {
    expect(soundsOf(s('goal'))).toEqual([
      [0.3, 'kick'],
      ['key', 'kick'],
      ['key', 'roar'],
    ])
    expect(soundsOf(s('foul', { drama: 'dive' }))).toEqual([
      [0.25, 'groan'],
      [0.8, 'whistle'],
    ])
    expect(soundsOf(s('card', { drama: 'brawl', type: 'red' })).slice(-2)).toEqual([
      [0.42, 'whistle'],
      [0.78, 'kick'],
    ])
    expect(soundsOf(s(null))).toEqual([])
  })

  it('what the studio reacts to', () => {
    expect(reactionKey(s('goal', { drama: 'blackout' }, true))).toBe('blackout')
    expect(reactionKey(s('penalty', { scored: true }, true))).toBe('penalty_goal')
    expect(reactionKey(s('card', { drama: 'spit' }))).toBe('brawl')
    expect(reactionKey(s('trap'))).toBe('offside')
    expect(reactionKey(s(null))).toBeNull()
  })
})
