import { afterEach, describe, expect, it, vi } from 'vitest'
import { nextTick } from 'vue'
import { midDevice, noteFrame, perfPref, setPerfPref, smooth, tier, weakDevice } from './perf'

const nav = (o: Record<string, unknown>) => {
  for (const [k, v] of Object.entries(o)) Object.defineProperty(navigator, k, { value: v, configurable: true })
}

describe('perf', () => {
  afterEach(() => {
    setPerfPref('auto')
    vi.unstubAllGlobals()
  })

  it('reads the device: little memory, few cores, data saving or less motion make it weak; a mid phone is mid', () => {
    vi.stubGlobal('matchMedia', (q: string) => ({ matches: q.includes('coarse') }))
    nav({ deviceMemory: 8, hardwareConcurrency: 8, connection: {} })
    expect(weakDevice()).toBe(false)
    expect(midDevice()).toBe(false)
    nav({ deviceMemory: 6 })
    expect(midDevice()).toBe(true)
    nav({ deviceMemory: 4 })
    expect(weakDevice()).toBe(true)
    expect(midDevice()).toBe(false)
    nav({ deviceMemory: 8, connection: { saveData: true } })
    expect(weakDevice()).toBe(true)
    nav({ connection: {} })
    vi.stubGlobal('matchMedia', (q: string) => ({ matches: q.includes('reduce') }))
    expect(weakDevice()).toBe(true)
  })

  it('takes the coach’s choice over the device, and keeps it', async () => {
    setPerfPref('smooth')
    await nextTick()
    await nextTick()
    expect([tier.value, smooth.value]).toEqual(['low', true])
    expect(document.documentElement.classList.contains('smooth')).toBe(true)
    setPerfPref('balanced')
    expect(tier.value).toBe('mid')
    setPerfPref('full')
    await nextTick()
    expect([tier.value, smooth.value]).toEqual(['high', false])
    expect(localStorage.getItem('glm.perf')).toBe('full')
  })

  it('lowers the automatic tier a step after two seconds of slow frames, never a chosen one', () => {
    setPerfPref('full')
    for (let i = 0; i < 100; i++) noteFrame(40)
    expect(tier.value).toBe('high')
    setPerfPref('auto')
    const before = tier.value
    for (let i = 0; i < 20; i++) noteFrame(16)
    expect(tier.value).toBe(before)
    for (let i = 0; i < 60; i++) noteFrame(40)
    expect(perfPref.value).toBe('auto')
    if (before !== 'low') expect(tier.value).not.toBe(before)
  })
})
