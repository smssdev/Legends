import { checkQuantities } from "./order.ts";
import type { Clock, Mailer, OrderStore } from "./ports.ts";

type Deps = { store: OrderStore; mailer: Mailer; clock: Clock };
type Input = { email: string; items: { productId: number; quantity: number }[] };

// the use case: one thing the shop does, start to finish, through its ports
export function makePlaceOrder({ store, mailer, clock }: Deps) {
  return async function placeOrder({ email, items }: Input) {
    checkQuantities(items);
    const order = await store.place(email, items, clock.now());
    // the email after the order is saved, never inside its transaction
    await mailer.send(email, `Order ${order.id}: ${order.total / 100} EGP`);
    return order;
  };
}
