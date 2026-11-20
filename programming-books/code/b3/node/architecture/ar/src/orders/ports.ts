import type { Line, Order } from "./order.ts";

// المنافذ: ما تحتاجه حالة الاستخدام من العالم الخارجي، كما تصفه هي
export type OrderStore = {
  /** Takes the stock and saves the order, all or nothing; prices come from the store. */
  place(
    email: string,
    items: Omit<Line, "price">[],
    placedAt: Date,
  ): Promise<Order>;
};
export type Mailer = { send(to: string, subject: string): Promise<void> };
export type Clock = { now(): Date };
