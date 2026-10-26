// The game's two languages [UP2]: Arabic (the source, written in the screens as it is) and English. A screen writes
// its Arabic and passes it through t() (or $t in a template): in English the dictionary (src/i18n/en.ts) gives the
// translation, and a sentence not yet there stays Arabic rather than break. {name} in a sentence takes vars.name.
// The choice is kept on this device and on the account (PATCH /auth/me), and every request carries it in
// Accept-Language, so the server's messages come in the same language.
import { ref } from 'vue'
import { EN } from '../i18n/en'

export type Locale = 'ar' | 'en'
const KEY = 'glm.locale'

function stored(): Locale | null {
  try {
    const v = localStorage.getItem(KEY)
    return v === 'ar' || v === 'en' ? v : null
  } catch {
    return null
  }
}
// Until the coach chooses: Arabic, the game's own language (many Arab phones run in English).
export const locale = ref<Locale>(stored() ?? 'ar')

function apply(l: Locale) {
  const html = document.documentElement
  html.lang = l
  html.dir = l === 'ar' ? 'rtl' : 'ltr'
}
apply(locale.value)

/** Sets the language on this device (and the page's direction). The account is saved by the caller. */
export function setLocale(l: Locale) {
  locale.value = l
  try {
    localStorage.setItem(KEY, l)
  } catch {
    // a private window: the choice lasts this visit
  }
  apply(l)
}

/** The account's language, once known: it wins over this device's, unless the device chose since. */
export function adoptLocale(l: string | null | undefined) {
  if ((l === 'ar' || l === 'en') && l !== locale.value) setLocale(l)
}

export function t(ar: string, vars?: Record<string, string | number>): string {
  let s = locale.value === 'en' ? (EN[ar] ?? ar) : ar
  if (vars) for (const [k, v] of Object.entries(vars)) s = s.split(`{${k}}`).join(String(v))
  return s
}

/** The locale for Intl: Arabic with Latin digits, as the game shows numbers. */
export const intlLocale = () => (locale.value === 'en' ? 'en-GB' : 'ar-EG-u-nu-latn')
