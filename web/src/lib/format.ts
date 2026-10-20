// Numbers as the design shows them (docs/design/legends-ui: Main, MobileSquad): Latin digits in Barlow,
// club money short (1.45M, 980K), strength with one decimal from hundredths.
export function money(v: number): string {
  if (v >= 1_000_000) return `${trim(v / 1_000_000, v >= 10_000_000 ? 1 : 2)}M`
  if (v >= 1_000) return `${trim(v / 1_000, 0)}K`
  return String(v)
}
export const strength = (cp: number) => (cp / 100).toFixed(1)
export const count = (n: number) => n.toLocaleString('en-US')
function trim(n: number, digits: number) {
  return n.toFixed(digits).replace(/\.?0+$/, '')
}

/** Line letters and names (حارس، دفاع، وسط، هجوم). */
export const LINES = {
  gk: { letter: 'ح', name: 'حارس', plural: 'حراس' },
  def: { letter: 'د', name: 'دفاع', plural: 'دفاع' },
  mid: { letter: 'و', name: 'وسط', plural: 'وسط' },
  att: { letter: 'هـ', name: 'هجوم', plural: 'هجوم' },
} as const
export type Line = keyof typeof LINES
