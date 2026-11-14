import { afterEach, describe, expect, it } from 'vitest'
import { adoptLocale, intlLocale, locale, setLocale, t } from './i18n'

describe('i18n', () => {
  afterEach(() => setLocale('ar'))

  it('writes Arabic as it is, with its values in place', () => {
    expect(t('مرحباً {name}، لديك {n} رسائل', { name: 'سارة', n: 3 })).toBe('مرحباً سارة، لديك 3 رسائل')
    expect(t(null)).toBe('')
    expect(t('{a}{a}', { a: 'x' })).toBe('xx')
  })

  it('turns to English once the dictionary is in, and keeps an unknown sentence', async () => {
    setLocale('en')
    expect(document.documentElement.dir).toBe('ltr')
    expect(document.documentElement.lang).toBe('en')
    await expect.poll(() => t('المكتب')).toBe('Office')
    expect(t('جملة ليست في القاموس')).toBe('جملة ليست في القاموس')
    expect(intlLocale()).toBe('en-GB')
  })

  it('takes the account’s language, and ignores what is not one', () => {
    adoptLocale('en')
    expect(locale.value).toBe('en')
    adoptLocale('fr')
    expect(locale.value).toBe('en')
    adoptLocale('ar')
    expect(document.documentElement.dir).toBe('rtl')
    expect(intlLocale()).toBe('ar-EG-u-nu-latn')
  })
})
