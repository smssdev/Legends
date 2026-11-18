import { describe, expect, it, vi } from 'vitest'
import { canRunUnity, unityClock, unityFiles, unityMinute, unityQuality, unitySetup, withUnity } from './bridge'
import type { Tick } from '../../api/sim'

const view = {
  clubs: {
    home: { id: 1, name: 'Liverpool', code: 'LIV', primary: '#C8102E', secondary: '#FFFFFF', pattern: null },
    away: { id: 2, name: 'Arsenal', code: 'ARS', color_primary: '#EF0107', color_secondary: '#063672' },
  },
  kits: { home: { kit: 'x' }, away: { kit: 'y' } },
  timing: { tick_ms: 3300, extra_time_tick_ms: 3300, halftime_seconds: 30 },
  seed: 48213,
  coach_looks: { home: 'C2' as const },
} as never

const teams = {
  home: {
    players: [
      { id: 9, name: 'Salah', no: 11, pos: 'RW', line: 'FW', on: true },
      { id: 10, name: 'Sub', no: 20, pos: 'CM', line: 'MF', on: false },
    ],
  },
} as never

describe('the Unity bridge', () => {
  it('sends the setup in the shape of the scene route', () => {
    const s = unitySetup(view, teams)
    expect(s.clubs.home).toEqual({ id: 1, name: 'Liverpool', code: 'LIV', primary: '#C8102E', secondary: '#FFFFFF', pattern: null })
    expect(s.clubs.away.primary).toBe('#EF0107')
    expect(s.players.home).toEqual([
      { id: 9, name: 'Salah', no: 11, pos: 'RW', line: 'FW', starter: true },
      { id: 10, name: 'Sub', no: 20, pos: 'CM', line: 'MF', starter: false },
    ])
    expect(s.players.away).toEqual([])
    expect([s.tick_ms, s.seed, s.coach_looks, s.light]).toEqual([3300, 48213, { home: 'C2', away: null }, 'night'])
    expect(unitySetup(view, teams, 'day').light).toBe('day')
  })

  it('finds the build under /unity/<build>/Build', () => {
    const f = unityFiles('2026.11.18')
    expect(f.loaderUrl).toBe('/unity/2026.11.18/Build/WebGL.loader.js')
    expect(f.codeUrl).toBe('/unity/2026.11.18/Build/WebGL.wasm.unityweb')
    expect(unityFiles('a b').dataUrl).toBe('/unity/a%20b/Build/WebGL.data.unityweb')
  })

  it('leaves weak devices and data saving to the cartoon', () => {
    expect(canRunUnity({ deviceMemory: 8, hardwareConcurrency: 8 }, true)).toBe(true)
    expect(canRunUnity({}, true)).toBe(true)
    expect(canRunUnity({ deviceMemory: 8 }, false)).toBe(false)
    expect(canRunUnity({ deviceMemory: 2 }, true)).toBe(false)
    expect(canRunUnity({ hardwareConcurrency: 2 }, true)).toBe(false)
    expect(canRunUnity({ connection: { saveData: true } }, true)).toBe(false)
  })

  it('maps the tiers to the quality levels', () => {
    expect(['low', 'mid', 'high'].map((t) => unityQuality(t as never))).toEqual(['low', 'medium', 'high'])
  })

  it('tells the scene how far into the minute the page is', () => {
    const t = { tick: 7 } as unknown as Tick
    expect(JSON.parse(unityMinute(t, null, 5000))).toEqual({ tick: 7 })
    expect(JSON.parse(unityMinute(t, 1000, 3500))).toEqual({ tick: 7, into: 2.5 })
    expect(JSON.parse(unityMinute(t, 5000, 5010))).toEqual({ tick: 7 })
  })

  it('tells the scene the page clock: the minute, the second, the speed', () => {
    expect(unityClock(12, 3.14159, 2)).toBe('12,3.142,2')
    expect(unityClock(1, -1, 0)).toBe('1,0.000,0')
    expect(unityClock(1, 0, 20)).toBe('1,0.000,8')
    expect(unityClock(1, 0, Number.NaN)).toBe('1,0.000,1')
  })

  it('plays every minute on the cartoon, and on Unity when it is on', () => {
    const feed = { play: vi.fn(), skip: vi.fn(), prepare: vi.fn(), react: vi.fn() }
    const scene = { play: vi.fn(), skip: vi.fn() }
    let on: typeof scene | null = null
    const p = withUnity(feed, () => on)
    const t = { tick: 1 } as unknown as Tick
    p.play(t)
    expect(feed.play).toHaveBeenCalledWith(t, undefined)
    expect(scene.play).not.toHaveBeenCalled()
    on = scene
    p.play(t, 123)
    expect(scene.play).toHaveBeenCalledWith(t, 123)
    p.skip()
    expect([feed.skip.mock.calls.length, scene.skip.mock.calls.length]).toEqual([1, 1])
    p.prepare(t)
    p.react('home', 'x', 'y', 'z')
    expect([feed.prepare.mock.calls.length, feed.react.mock.calls.length]).toEqual([1, 1])
  })
})
