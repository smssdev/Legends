import { afterEach, describe, expect, it } from 'vitest'
import { count, fitnessTone, money, scoreText, strength } from './format'
import { locale } from './i18n'

describe('format', () => {
  afterEach(() => {
    locale.value = 'ar'
  })

  it('writes money in Arabic words, isolated right to left', () => {
    expect(money(3_000_000)).toBe('⁧3 ملايين⁩')
    expect(money(3_500_000)).toBe('⁧3.5 مليون⁩')
    expect(money(12_300_000)).toBe('⁧12.3 مليون⁩')
    expect(money(750_000)).toBe('⁧750 ألف⁩')
    expect(money(5_000)).toBe('⁧5 آلاف⁩')
    expect(money(620)).toBe('620')
  })

  it('writes money short in English, without trailing zeros', () => {
    locale.value = 'en'
    expect(money(1_450_000)).toBe('1.45M')
    expect(money(2_000_000)).toBe('2M')
    expect(money(980_000)).toBe('980K')
    expect(money(12_000_000)).toBe('12M')
    expect(money(999)).toBe('999')
  })

  it('writes strength, counts and fitness tones', () => {
    expect(strength(8452)).toBe('84.5')
    expect(count(1234567)).toBe('1,234,567')
    expect([fitnessTone(95), fitnessTone(80), fitnessTone(60)]).toEqual(['bg-success', 'bg-gold', 'bg-live'])
    expect([fitnessTone(90, 'text'), fitnessTone(75, 'text'), fitnessTone(74, 'text')]).toEqual([
      'text-success',
      'text-warning',
      'text-danger',
    ])
  })

  it('puts the first side’s goals on its own edge (X73)', () => {
    expect(scoreText(1, 3)).toBe('3 - 1')
    expect(scoreText(null, undefined)).toBe('- - -')
    locale.value = 'en'
    expect(scoreText(1, 3)).toBe('1 - 3')
  })
})
