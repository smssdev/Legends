import { beforeEach, describe, expect, it, vi } from 'vitest'

const calls: string[] = []
vi.mock('./sound', () => ({
  MatchSound: class {
    start() {
      calls.push('start')
    }
    setMuted(m: boolean) {
      calls.push('muted:' + m)
    }
    whistle(n?: number) {
      calls.push('whistle' + (n ?? ''))
    }
    kick(c: boolean) {
      calls.push('kick:' + c)
    }
    duck() {}
    stop() {
      calls.push('stop')
    }
    roar() {}
    net() {}
    touch() {}
    groan() {}
    heart() {}
    post() {}
  },
}))
vi.mock('./voice', () => ({
  Commentator: class {
    onTalk: unknown = null
    setOn(on: boolean) {
      calls.push('voice:' + on)
    }
    dispose() {
      calls.push('dispose')
    }
  },
}))

import { useMatchAudio } from './useMatchAudio'

describe('useMatchAudio', () => {
  beforeEach(() => {
    calls.length = 0
    localStorage.clear()
  })

  it('the sound and the commentator turn on together, and the commentator can be left off', () => {
    const a = useMatchAudio()
    a.toggleSound()
    expect(calls).toEqual(['start', 'muted:false', 'voice:true', 'whistle'])
    a.toggleCommentary()
    expect([a.commentary.value, calls[calls.length - 1], localStorage.getItem('glm.commentary')]).toEqual(['off', 'voice:false', 'off'])
    expect(useMatchAudio().commentary.value).toBe('off')
  })

  it('plays what the scene asks for', () => {
    const a = useMatchAudio()
    a.onSound('kick')
    a.onSound('thud')
    a.onSound('whistle-long')
    expect(calls).toEqual(['kick:true', 'kick:false', 'whistle1'])
  })
})
