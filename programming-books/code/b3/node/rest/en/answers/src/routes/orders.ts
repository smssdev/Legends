import { createHash } from "node:crypto";
import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import { problems } from "../problem.ts";
import { egp, IdParams, OrderOut } from "../schemas.ts";
import type { Order, Store } from "../store.ts";

const NewOrder = z.strictObject({
  items: z
    .array(
      z.strictObject({
        product_id: z.number().int(),
        quantity: z.number().int().min(1).max(99),
      }),
    )
    .min(1)
    .max(20),
});

const show = (o: Order): z.infer<typeof OrderOut> => ({
  ...o,
  items: o.items.map((item) => ({ ...item, price: egp(item.price) })),
  total: egp(o.total),
});

type Saved = { fingerprint: string; order?: z.infer<typeof OrderOut> };

export const orderRoutes =
  (store: Store): FastifyPluginAsyncZod =>
  async (app) => {
    // remembered for 24 hours in a real system, in the database or Redis
    const keys = new Map<string, Saved>();

    app.post(
      "/orders",
      {
        schema: {
          headers: z.object({ "idempotency-key": z.string().min(8).max(100) }),
          body: NewOrder,
          response: { 201: OrderOut },
        },
      },
      async (request, reply) => {
        const key = request.headers["idempotency-key"];
        const body = JSON.stringify(request.body);
        const fingerprint = createHash("sha256").update(body).digest("hex");
        const saved = keys.get(key);
        if (saved) {
          if (saved.fingerprint !== fingerprint) throw problems.keyReused();
          if (!saved.order) throw problems.inProgress();
          reply.header("Idempotent-Replayed", "true");
          reply.header("Location", `/v1/orders/${saved.order.id}`);
          return reply.code(201).send(saved.order);
        }
        // mark the key as in progress before doing the work
        keys.set(key, { fingerprint });

        try {
          const items = request.body.items.map(({ product_id, quantity }) => {
            const product = store.products.find((p) => p.id === product_id);
            if (!product) throw problems.unknownProduct(product_id);
            if (product.stock < quantity) {
              throw problems.outOfStock(product.id, product.stock);
            }
            return { product, quantity };
          });
          for (const { product, quantity } of items) {
            product.stock -= quantity;
            product.version += 1;
          }
          const order: Order = {
            id: store.nextOrderId++,
            status: "pending",
            // the price comes from the server, never from the client
            items: items.map(({ product, quantity }) => ({
              product_id: product.id,
              quantity,
              price: product.price,
            })),
            total: items.reduce(
              (sum, { product, quantity }) => sum + product.price * quantity,
              0,
            ),
            created_at: new Date().toISOString(),
          };
          store.orders.push(order);
          keys.set(key, { fingerprint, order: show(order) });
          reply.header("Location", `/v1/orders/${order.id}`);
          return reply.code(201).send(show(order));
        } catch (error) {
          keys.delete(key); // a failed attempt may be tried again with the same key
          throw error;
        }
      },
    );

    const find = (id: number) => {
      const order = store.orders.find((o) => o.id === id);
      if (!order) throw problems.noOrder(id);
      return order;
    };

    app.get(
      "/orders/:id",
      { schema: { params: IdParams, response: { 200: OrderOut } } },
      async (request) => show(find(request.params.id)),
    );

    // An action, not create, read, update or delete: a sub-resource, with POST.
    app.post(
      "/orders/:id/cancel",
      { schema: { params: IdParams, response: { 200: OrderOut } } },
      async (request) => {
        const order = find(request.params.id);
        if (order.status !== "pending")
          throw problems.cannotCancel(order.id, order.status);
        order.status = "cancelled";
        for (const item of order.items) {
          const product = store.products.find((p) => p.id === item.product_id);
          if (product) product.stock += item.quantity;
        }
        return show(order);
      },
    );
  };
