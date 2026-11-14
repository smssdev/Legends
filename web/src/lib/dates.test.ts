import { afterEach, describe, expect, it } from 'vitest'
import { stamp } from './dates'
import { locale } from './i18n'

describe('stamp', () => {
  afterEach(() => {
    locale.value = 'ar'
  })
  const now = new Date(2026, 10, 15, 18, 30)

  it('says today and yesterday with the time', () => {
    expect(stamp(new Date(2026, 10, 15, 14, 5).toISOString(), now)).toMatch(/^اليوم /)
    expect(stamp(new Date(2026, 10, 14, 23, 59).toISOString(), now)).toMatch(/^أمس /)
  })

  it('gives the date, and the year only when it is not this one', () => {
    locale.value = 'en'
    expect(stamp(new Date(2026, 10, 12, 14, 5).toISOString(), now)).toMatch(/^12 November, /)
    expect(stamp(new Date(2025, 10, 12, 14, 5).toISOString(), now)).toMatch(/^12 November 2025, /)
  })
})
