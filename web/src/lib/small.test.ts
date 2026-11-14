import { describe, expect, it, vi } from 'vitest'
import { divisionName, signed, tierName } from './rating'
import { statusLabel } from './statuses'
import { uuid } from './uuid'

describe('small helpers', () => {
  it('names the server’s states, and keeps an unknown one', () => {
    expect(statusLabel('running')).toBe('جارٍ')
    expect(statusLabel('odd')).toBe('odd')
    expect(statusLabel(null)).toBe('')
  })

  it('names the coach’s tiers and divisions', () => {
    expect(tierName('legend')).toBe('الأسطورة')
    expect([divisionName(1), divisionName(3), divisionName(null)]).toEqual(['I', 'III', ''])
    expect([signed(5), signed(0), signed(-3)]).toEqual(['+5', '0', '-3'])
  })

  it('makes a v4 uuid, also where randomUUID is missing (plain HTTP)', () => {
    const v4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/
    expect(uuid()).toMatch(v4)
    const spy = vi.spyOn(globalThis.crypto, 'randomUUID').mockImplementation(() => {
      throw new Error('insecure')
    })
    expect(uuid()).toMatch(v4)
    spy.mockRestore()
  })
})
