// [Sprint 63 G13] The three levels: each a gain from 0 to 1, and a sound at 0 is not played.
import { describe, expect, it, vi } from 'vitest'
import { gainOf, levels, uiSound } from './soundLevels'

describe('sound levels', () => {
  it('a level is a gain, and 0 plays nothing', () => {
    levels.ui = 40
    levels.voice = 0
    expect(gainOf('ui')).toBe(0.4)
    expect(gainOf('voice')).toBe(0)
    const made = vi.fn()
    vi.stubGlobal('Audio', class { volume = 1; currentTime = 0; constructor() { made() } canPlayType() { return 'probably' } play() { return Promise.resolve() } })
    uiSound('tap', 'voice')
    expect(made).not.toHaveBeenCalled()
    uiSound('tap', 'ui')
    expect(made).toHaveBeenCalled()
    vi.unstubAllGlobals()
  })
})
