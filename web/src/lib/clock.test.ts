import { afterEach, describe, expect, it } from 'vitest'
import { arabicCount, countdown } from './clock'
import { locale } from './i18n'

const at = (ms: number) => new Date(Date.UTC(2026, 10, 15, 12) + ms).toISOString()
const now = Date.UTC(2026, 10, 15, 12)

describe('countdown', () => {
  afterEach(() => {
    locale.value = 'ar'
  })

  it('is empty without a time or once it has come', () => {
    expect(countdown(null, now)).toBe('')
    expect(countdown(at(0), now)).toBe('')
    expect(countdown(at(-5000), now)).toBe('')
  })

  it('counts hours, minutes and seconds under a day', () => {
    expect(countdown(at((2 * 3600 + 14 * 60 + 36) * 1000), now)).toBe('02:14:36')
    expect(countdown(at(999), now)).toBe('')
    expect(countdown(at(1000), now)).toBe('00:00:01')
  })

  it('says days and hours in words past a day', () => {
    expect(countdown(at((3 * 86400 + 12 * 3600) * 1000), now)).toBe('⁧3 أيام و12 ساعة⁩')
    expect(countdown(at(86400 * 1000), now)).toBe('⁧يوم⁩')
    expect(countdown(at((2 * 86400 + 2 * 3600) * 1000), now)).toBe('⁧يومان وساعتان⁩')
    locale.value = 'en'
    expect(countdown(at((3 * 86400 + 12 * 3600) * 1000), now)).toBe('3 days 12 h')
    expect(countdown(at(86400 * 1000), now)).toBe('1 day')
  })

  it('counts in Arabic: one, two, a few, many', () => {
    const c = (n: number) => arabicCount(n, 'يوم', 'يومان', 'أيام', 'يوماً')
    expect([c(1), c(2), c(3), c(10), c(11), c(103), c(111)]).toEqual([
      'يوم',
      'يومان',
      '3 أيام',
      '10 أيام',
      '11 يوماً',
      '103 أيام',
      '111 يوماً',
    ])
  })
})
