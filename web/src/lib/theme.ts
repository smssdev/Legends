// [X56] The game's two looks: the night and the day, or the device's own choice (the default for who has not
// chosen, Sprint 43 A1). On this
// device only, like the names' language. A class on the page's root (html.light) swaps the colours of
// docs/design/tokens.json (colorLight); index.html puts it there before the first paint, so the page never flashes.
import { storage } from './storage'
import { computed, ref, watch } from 'vue'

export type ThemePref = 'dark' | 'light' | 'auto'
const KEY = 'theme'
/** The bar's colour on the phone, as the page's ground in each look (tokens.json bg). */
const BAR = { dark: '#0B1A2C', light: '#EFEADF' } as const

function readPref(): ThemePref {
  try {
    const v = storage.get(KEY)
    return v === 'light' || v === 'dark' ? v : 'auto'
  } catch {
    return 'auto'
  }
}

const media = typeof matchMedia === 'function' ? matchMedia('(prefers-color-scheme: light)') : null
const deviceLight = ref(media?.matches ?? false)
media?.addEventListener?.('change', (e) => (deviceLight.value = e.matches))

export const themePref = ref<ThemePref>(readPref())
/** The look on the screen now. */
export const theme = computed<'dark' | 'light'>(() =>
  themePref.value === 'auto' ? (deviceLight.value ? 'light' : 'dark') : themePref.value,
)

watch(
  theme,
  (v) => {
    if (typeof document === 'undefined') return
    document.documentElement.classList.toggle('light', v === 'light')
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', BAR[v])
  },
  { immediate: true },
)

export function setThemePref(p: ThemePref) {
  themePref.value = p
  try {
    storage.set(KEY, p)
  } catch {
    /* private mode: for this visit only */
  }
}
