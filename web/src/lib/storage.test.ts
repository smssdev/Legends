import { beforeEach, describe, expect, it } from 'vitest'
import { migrateStorage, storage } from './storage'

describe('storage', () => {
  beforeEach(() => localStorage.clear())

  it('moves the keys of before under glm., once, a key already there winning', () => {
    localStorage.setItem('legends.theme', 'light')
    localStorage.setItem('legends.league', '7')
    localStorage.setItem('glm.league', '9')
    localStorage.setItem('other', 'x')
    migrateStorage()
    expect([
      localStorage.getItem('glm.theme'),
      localStorage.getItem('glm.league'),
      localStorage.getItem('legends.theme'),
      localStorage.getItem('other'),
    ]).toEqual(['light', '9', null, 'x'])
    localStorage.setItem('legends.late', '1')
    migrateStorage()
    expect(localStorage.getItem('legends.late')).toBe('1') // once only
  })

  it('reads and writes under the prefix, and JSON safely', () => {
    storage.set('perf', 'smooth')
    expect([localStorage.getItem('glm.perf'), storage.get('perf'), storage.get('none')]).toEqual(['smooth', 'smooth', null])
    storage.setJson('bot.saved', { a: 1 })
    expect(storage.json('bot.saved', null)).toEqual({ a: 1 })
    localStorage.setItem('glm.broken', '{nope')
    expect(storage.json('broken', 'fallback')).toBe('fallback')
    storage.remove('perf')
    expect(storage.get('perf')).toBeNull()
  })
})
