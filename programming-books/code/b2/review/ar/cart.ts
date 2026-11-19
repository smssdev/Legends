export type Line = { name: string; price: number; qty: number };

export function subtotal(lines: readonly Line[]): number {
  return lines.reduce((sum, line) => sum + line.price * line.qty, 0);
}
