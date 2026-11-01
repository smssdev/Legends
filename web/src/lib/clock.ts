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
  if (!d) return hms
  // [Sprint 30 Q10] A day or more away: in words, «3 أيام و12 ساعة» («3 days 12 h»), not «3ي 12:00:00». Isolated right to
  // left (U+2067..U+2069) so it reads well inside the left-to-right clocks it sits in.
  const h = Math.floor(s / 3600)
  if (locale.value === 'en') return `${d} ${d === 1 ? 'day' : 'days'}${h ? ` ${h} h` : ''}`
  return `\u2067${arabicCount(d, 'يوم', 'يومان', 'أيام', 'يوماً')}${h ? ` و${arabicCount(h, 'ساعة', 'ساعتان', 'ساعات', 'ساعة')}` : ''}\u2069`
}

/** [Sprint 30 Q10] An Arabic count with its noun: 1 يوم، يومان، 3 أيام، 11 يوماً (the singular, dual, 3 to 10, and from 11). */
export function arabicCount(n: number, one: string, two: string, few: string, many: string): string {
  if (n === 1) return one
  if (n === 2) return two
  return `${n} ${n % 100 >= 3 && n % 100 <= 10 ? few : many}`
}
