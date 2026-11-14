import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useMatchClock } from './useMatchClock'

describe('useMatchClock', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    vi.setSystemTime(1_000_000)
  })
  afterEach(() => vi.useRealTimers())

  it('takes the server time from the fastest reply', () => {
    const c = useMatchClock()
    // Sent at 1_000_000, back now (rtt 0): the server said 1_005_000, so it is 5 s ahead.
    c.sample(1_000_000, 1_005_000)
    expect(c.serverNow()).toBe(1_005_000)
    // A slower reply (rtt 400 ms) saying otherwise does not move it.
    vi.setSystemTime(1_000_400)
    c.sample(1_000_000, 1_090_000)
    expect(c.serverNow()).toBe(1_005_400)
  })

  it('ticks at once, then on every turn of the server second', () => {
    const c = useMatchClock()
    c.sample(1_000_000, 1_000_300) // the server is 300 ms ahead: its second turns in 700 ms
    const tick = vi.fn()
    c.start(tick)
    expect(tick).toHaveBeenCalledTimes(1)
    vi.advanceTimersByTime(699)
    expect(tick).toHaveBeenCalledTimes(1)
    vi.advanceTimersByTime(1)
    expect(tick).toHaveBeenCalledTimes(2)
    vi.advanceTimersByTime(3000)
    expect(tick).toHaveBeenCalledTimes(5)
    c.stop()
    vi.advanceTimersByTime(5000)
    expect(tick).toHaveBeenCalledTimes(5)
  })
})
