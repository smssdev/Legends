import { afterEach, describe, expect, it, vi } from 'vitest'
import { useWakeLock } from './useWakeLock'

describe('useWakeLock', () => {
  afterEach(() => { delete (navigator as any).wakeLock })

  it('asks once while allowed, and again after letting go', async () => {
    const release = vi.fn(() => Promise.resolve())
    const request = vi.fn(async () => ({ released: false, release }))
    ;(navigator as any).wakeLock = { request }
    let allowed = true
    const w = useWakeLock(() => allowed)
    await w.keep()
    await w.keep()
    expect(request).toHaveBeenCalledTimes(1)
    w.release()
    expect(release).toHaveBeenCalledTimes(1)
    allowed = false
    await w.keep()
    expect(request).toHaveBeenCalledTimes(1)
    allowed = true
    await w.keep()
    expect(request).toHaveBeenCalledTimes(2)
  })

  it('plays on when the phone refuses or has none', async () => {
    const w = useWakeLock(() => true)
    await expect(w.keep()).resolves.toBeUndefined()
    ;(navigator as any).wakeLock = { request: () => Promise.reject(new Error('battery saver')) }
    await expect(w.keep()).resolves.toBeUndefined()
  })
})
