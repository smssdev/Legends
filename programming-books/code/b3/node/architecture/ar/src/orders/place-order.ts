import { checkQuantities } from "./order.ts";
import type { Clock, Mailer, OrderStore } from "./ports.ts";

type Deps = { store: OrderStore; mailer: Mailer; clock: Clock };
type Input = { email: string; items: { productId: number; quantity: number }[] };

// حالة الاستخدام: شيء واحد يفعله المتجر، من البداية إلى النهاية، عبر منافذها
export function makePlaceOrder({ store, mailer, clock }: Deps) {
  return async function placeOrder({ email, items }: Input) {
    checkQuantities(items);
    const order = await store.place(email, items, clock.now());
    // البريد بعد حفظ الطلب، لا داخل معاملته أبداً
    await mailer.send(email, `Order ${order.id}: ${order.total / 100} EGP`);
    return order;
  };
}
