// The game's two languages [UP2]: Arabic (the source, written in the screens as it is) and English. A screen writes
// its Arabic and passes it through t() (or $t in a template): in English the dictionary (src/i18n/en.ts) gives the
// translation, and a sentence not yet there stays Arabic rather than break. {name} in a sentence takes vars.name.
// The choice is kept on this device and on the account (PATCH /auth/me), and every request carries it in
// Accept-Language, so the server's messages come in the same language.
// The English dictionary (100 KB) loads only for a coach who plays in English [E1.4]: the Arabic majority never
// downloads it, and the app mounts once it is here (i18nReady), so English never flashes Arabic.
import { storage } from './storage'
import { computed, ref, shallowRef } from 'vue'

export type Locale = 'ar' | 'en'
const KEY = 'locale'

function stored(): Locale | null {
  try {
    const v = storage.get(KEY)
    return v === 'ar' || v === 'en' ? v : null
  } catch {
    return null
  }
}
// [SEO] A link with ?lang=en (or ar), as Google's English pages are, opens in that language and keeps it.
function fromLink(): Locale | null {
  try {
    const v = new URLSearchParams(location.search).get('lang')
    if (v !== 'ar' && v !== 'en') return null
    storage.set(KEY, v)
    return v
  } catch {
    return null
  }
}
// Until the coach chooses: Arabic, the game's own language (many Arab phones run in English).
export const locale = ref<Locale>(fromLink() ?? stored() ?? 'ar')

function apply(l: Locale) {
  const html = document.documentElement
  html.lang = l
  html.dir = l === 'ar' ? 'rtl' : 'ltr'
}
apply(locale.value)

const EN = shallowRef<Record<string, string>>({})
let loading: Promise<void> | null = null
function loadEnglish(): Promise<void> {
  return (loading ??= import('../i18n/en').then((m) => { EN.value = m.EN }))
}
/** Resolves when the device's language can be shown: at once in Arabic, after the dictionary in English. */
export const i18nReady: Promise<void> = locale.value === 'en' ? loadEnglish().catch(() => {}) : Promise.resolve()

/** Sets the language on this device (and the page's direction). The account is saved by the caller. */
export function setLocale(l: Locale) {
  locale.value = l
  try {
    storage.set(KEY, l)
  } catch {
    // a private window: the choice lasts this visit
  }
  apply(l)
  if (l === 'en') void loadEnglish()
}

/** The account's language, once known: it wins over this device's, unless the device chose since. */
export function adoptLocale(l: string | null | undefined) {
  if ((l === 'ar' || l === 'en') && l !== locale.value) setLocale(l)
}

export function t(ar: string | null | undefined, vars?: Record<string, string | number | null | undefined>): string {
  if (ar == null) return ''
  let s = locale.value === 'en' ? (EN.value[ar] ?? ar) : ar
  if (vars) for (const [k, v] of Object.entries(vars)) s = s.split(`{${k}}`).join(String(v ?? ''))
  return s
}

/** The locale for Intl: Arabic with Latin digits, as the game shows numbers. */
export const intlLocale = () => (locale.value === 'en' ? 'en-GB' : 'ar-EG-u-nu-latn')

/** The crest in the page's language [SEO]: «المدرب الأسطورة» on it in Arabic, GLM in English (tools/brand/logo.py). */
export const emblemSrc = computed(() => (locale.value === 'ar' ? '/brand/emblem-ar.svg' : '/brand/emblem.svg'))
export const loaderSrc = computed(() => (locale.value === 'ar' ? '/brand/emblem-loader-ar.svg' : '/brand/emblem-loader.svg'))
