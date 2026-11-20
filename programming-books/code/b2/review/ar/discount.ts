import { subtotal, type Line } from "./cart";

// الأسعار بالقروش أعداداً صحيحة: لا أموال بأعداد عشرية
// الأكواد في جدول واحد، وإضافة كود لا تحتاج if جديدة
const codes: Record<string, { percent: number }> = {
  BIT10: { percent: 10 },
  HALF: { percent: 50 },
};

// الكود المجهول جواب، لا سعر كامل صامت
export type Priced =
  | { ok: true; subtotal: number; discount: number; total: number }
  | { ok: false; reason: "unknown-code" };

// السلة لا تتغير: الدالة تُرجع نتيجة جديدة
export function price(lines: readonly Line[], code?: string): Priced {
  const sum = subtotal(lines);
  const key = code?.trim().toUpperCase();
  if (!key) return { ok: true, subtotal: sum, discount: 0, total: sum };
  const found = codes[key];
  if (!found) return { ok: false, reason: "unknown-code" };
  const discount = Math.round((sum * found.percent) / 100);
  return { ok: true, subtotal: sum, discount, total: sum - discount };
}
