import { describe, expect, it } from 'vitest'
import { clockAt } from './clock'

describe('clockAt', () => {
  it('a quiet minute runs its sixty seconds', () => {
    expect(clockAt([12, 0], 12, 0, null)).toEqual({ text: '11:00', frozen: false, half: 'first', progress: 0.12 })
    expect(clockAt([12, 0], 12, 0.5, null).text).toBe('11:30')
    expect(clockAt([47, 0], 47, 0.99, null)).toMatchObject({ text: '46:59', half: 'second' })
    expect(clockAt([45, 2], 47, 0, null).text).toBe('46:00')
  })

  it('a minute with a scene runs to the moment\'s second, stands still through it, then runs on', () => {
    const p = { total: 10, sceneT: 6, cutT: 2, scene: true } // held until 0.8 of the minute
    const at = 12 + ((30 * 37) % 40) // the moment's second, from the minute
    expect(clockAt([30, 0], 30, 0.02, p)).toMatchObject({ frozen: false })
    expect(clockAt([30, 0], 30, 0.5, p)).toMatchObject({ text: `29:${at}`, frozen: true })
    expect(clockAt([30, 0], 30, 0.9, p)).toMatchObject({ frozen: false })
    expect(Number(clockAt([30, 0], 30, 0.9, p).text.slice(3))).toBeGreaterThan(at)
  })

  it('names the half: extra time and the shootout', () => {
    expect(clockAt([100, 0], 100, 0, null).half).toBe('extra')
    expect(clockAt([121, 0], 121, 0, null).half).toBe('shootout')
  })
})
