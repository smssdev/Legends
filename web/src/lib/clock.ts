// [Sprint 20 W3, W5] One second's tick for every countdown on the screen, and how a time left is written.
import { onBeforeUnmount, ref } from 'vue'
import { locale } from './i18n'

/** The time now, updated every second while the component lives. */
export function useNow() {
  const now = ref(Date.now())
  const id = setInterval(() => (now.value = Date.now()), 1000)
  onBeforeUnmount(() => clearInterval(id))
  return now
}

/** "02:14:36" (or "3ي 07:14:36" past a day, "3d …" in English) until iso; "" once it has come. */
export function countdown(iso: string | null | undefined, now: number): string {
  if (!iso) return ''
  let s = Math.max(0, Math.floor((new Date(iso).getTime() - now) / 1000))
  if (s === 0) return ''
  const d = Math.floor(s / 86400)
  s -= d * 86400
  const hms = [Math.floor(s / 3600), Math.floor((s % 3600) / 60), s % 60].map((n) => String(n).padStart(2, '0')).join(':')
  // The days isolated (U+2068..U+2069), so the Arabic letter keeps its number beside it inside a left-to-right clock.
  return d ? `\u2068${d}${locale.value === 'en' ? 'd' : 'ي'}\u2069 ${hms}` : hms
}
