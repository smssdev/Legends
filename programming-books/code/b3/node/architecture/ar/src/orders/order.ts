// المجال: قواعد المتجر، بـ TypeScript عادية؛ بلا قاعدة بيانات، ولا HTTP، ولا إطار
export type Line = { productId: number; quantity: number; price: number };
export type Order = {
  id: number;
  email: string;
  lines: Line[];
  total: number;
  placedAt: Date;
};

// أخطاء تتكلم لغة العمل؛ وكل محوّل يقرر ماذا تصير
export class OrderError extends Error {}
export class TooMany extends OrderError {}
export class OutOfStock extends OrderError {}
export class UnknownProduct extends OrderError {}

// قاعدة من قواعد العمل، لا من قواعد قاعدة البيانات ولا API
export const MAX_PER_PRODUCT = 10;

export function checkQuantities(items: { productId: number; quantity: number }[]) {
  for (const item of items) {
    if (item.quantity > MAX_PER_PRODUCT)
      throw new TooMany("10 على الأكثر من المنتج الواحد في الطلب");
  }
}

export const totalOf = (lines: Line[]) =>
  lines.reduce((sum, l) => sum + l.price * l.quantity, 0);
