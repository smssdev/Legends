// Numbers as the design shows them (docs/design/legends-ui: Main, MobileSquad): Latin digits in Barlow,
// club money short (1.45M, 980K), strength with one decimal from hundredths.
export function money(v: number): string {
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
