import { locale } from './i18n'
// Numbers as the design shows them (docs/design/legends-ui: Main, MobileSquad): Latin digits in Barlow,
// club money short (1.45M, 980K), strength with one decimal from hundredths.
export function money(v: number): string {
  // [Sprint 30 Q10] In the Arabic game the amount in words: «3 ملايين»، «3.5 مليون»، «750 ألف» (isolated right to left,
  // U+2067..U+2069, so it reads well inside the left-to-right number spans it sits in). In English 3M and 750K.
  if (locale.value !== 'en' && v >= 1_000) {
    const [n, one, few] = v >= 1_000_000 ? [trim(v / 1_000_000, v >= 10_000_000 ? 1 : 2), 'مليون', 'ملايين'] : [trim(v / 1_000, 0), 'ألف', 'آلاف']
    const whole = Number(n)
    return `\u2067${n} ${Number.isInteger(whole) && whole >= 3 && whole <= 10 ? few : one}\u2069`
  }
  if (v >= 1_000_000) return `${trim(v / 1_000_000, v >= 10_000_000 ? 1 : 2)}M`
  if (v >= 1_000) return `${trim(v / 1_000, 0)}K`
  return String(v)
}
export const strength = (cp: number) => (cp / 100).toFixed(1)
export const count = (n: number) => n.toLocaleString('en-US')
// Drops the decimals' trailing zeros only (1.50 → 1.5, 2.00 → 2), never a whole number's (620 stays 620).
function trim(n: number, digits: number) {
  const s = n.toFixed(digits)
  return s.includes('.') ? s.replace(/0+$/, '').replace(/\.$/, '') : s
}

/** Line letters and names (حارس، دفاع، وسط، هجوم). */
export const LINES = {
  gk: { letter: 'ح', name: 'حارس', plural: 'حراس' },
  def: { letter: 'د', name: 'دفاع', plural: 'دفاع' },
  mid: { letter: 'و', name: 'وسط', plural: 'وسط' },
  att: { letter: 'هـ', name: 'هجوم', plural: 'هجوم' },
} as const
export type Line = keyof typeof LINES

/**
 * [X73] A score for a left-to-right number box: the first side's goals on the first side's edge. In Arabic the first
 * (home, or mine) team sits on the right, so its number is written last to land on the right; in English first.
 * «سيراميكا 1 - 3 الزمالك» showed the 1 beside Zamalek, as if Zamalek had lost.
 */
export function scoreText(first: number | string | null | undefined, second: number | string | null | undefined): string {
  const [a, b] = [first ?? '-', second ?? '-']
  return locale.value === 'en' ? `${a} - ${b}` : `${b} - ${a}`
}
