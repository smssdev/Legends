// [X61] One way to write when a message came, on every screen that lists them (the inbox, support, the
// announcements): «اليوم 14:05», «أمس 14:05», or «12 نوفمبر، 14:05» (and the year when it is not this one), in the
// device's time; [X62] in Arabic with the Arabic-Indic digits (ar-EG), as the owner asked, in English the Western ones.
import { locale, t } from './i18n'

const dateLocale = () => (locale.value === 'en' ? 'en-GB' : 'ar-EG')

export function stamp(iso: string, now = new Date()): string {
  const d = new Date(iso)
  const time = new Intl.DateTimeFormat(dateLocale(), { hour: '2-digit', minute: '2-digit' }).format(d)
  const day = (x: Date) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime()
  const diff = Math.round((day(now) - day(d)) / 86400000)
  if (diff === 0) return t('اليوم {v0}', { v0: time })
  if (diff === 1) return t('أمس {v0}', { v0: time })
  const date = new Intl.DateTimeFormat(dateLocale(), {
    day: 'numeric',
    month: 'long',
    ...(d.getFullYear() !== now.getFullYear() ? { year: 'numeric' } : {}),
  }).format(d)
  return `${date}${locale.value === 'en' ? ',' : '،'} ${time}`
}
