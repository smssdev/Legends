// [X61] One way to write when a message came, on every screen that lists them (the inbox, support, the
// announcements): «اليوم 14:05», «أمس 14:05», or «12 نوفمبر، 14:05» (and the year when it is not this one), in the
// device's time and the game's digits.
import { intlLocale, locale, t } from './i18n'

export function stamp(iso: string, now = new Date()): string {
  const d = new Date(iso)
  const time = new Intl.DateTimeFormat(intlLocale(), { hour: '2-digit', minute: '2-digit' }).format(d)
  const day = (x: Date) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime()
  const diff = Math.round((day(now) - day(d)) / 86400000)
  if (diff === 0) return t('اليوم {v0}', { v0: time })
  if (diff === 1) return t('أمس {v0}', { v0: time })
  const date = new Intl.DateTimeFormat(intlLocale(), { day: 'numeric', month: 'long', ...(d.getFullYear() !== now.getFullYear() ? { year: 'numeric' } : {}) }).format(d)
  return `${date}${locale.value === 'en' ? ',' : '،'} ${time}`
}
