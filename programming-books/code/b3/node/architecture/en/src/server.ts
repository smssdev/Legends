import Fastify from "fastify";
import { connect } from "./db.ts";
import { kyselyOrderStore } from "./orders/kysely-store.ts";
import { makePlaceOrder } from "./orders/place-order.ts";
import { orderRoutes } from "./orders/routes.ts";

// the composition root: the only place that knows every concrete piece
const db = connect();
const placeOrder = makePlaceOrder({
  store: kyselyOrderStore(db),
  mailer: { send: async (to, subject) => console.log(`mail to ${to}: ${subject}`) },
  clock: { now: () => new Date() },
});

const app = Fastify();
await app.register(orderRoutes(placeOrder));
app.get("/ready", async () => ({ ready: true }));
await app.listen({ port: 3000 });
