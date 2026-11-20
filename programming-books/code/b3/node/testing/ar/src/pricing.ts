// نقية: المدخل نفسه يعطي المخرج نفسه دائماً، ولا يحدث شيء آخر
export type Line = { price: number; quantity: number };

const CODES: Record<string, { percent?: number; amount?: number }> = {
  SAVE10: { percent: 10 },
  FIXED50: { amount: 5000 },
};

export function total(lines: Line[], code?: string) {
  const subtotal = lines.reduce((sum, l) => sum + l.price * l.quantity, 0);
  let discount = 0;
  if (code) {
    // أكواد الخصم: نسبة مئوية، أو مبلغ ثابت (لا ينزل تحت الصفر أبداً)
    const rule = CODES[code];
    if (!rule) throw new Error(`كود خصم مجهول: ${code}`);
    discount = rule.percent
      ? Math.round((subtotal * rule.percent) / 100)
      : rule.amount!;
    discount = Math.min(discount, subtotal);
  }
  // ضريبة 14% على المجموع بعد الخصم، مقرَّبة إلى أقرب قرش
  // التمرين 1: خطأ يُبحث عنه، يُشغَّل بـ BUG=1
  const rate = process.env.BUG ? 0.15 : 0.14;
  const vat = Math.round((subtotal - discount) * rate);
  return { subtotal, discount, vat, total: subtotal - discount + vat };
}
