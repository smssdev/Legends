import type { FastifyPluginAsync } from "fastify";
import { OrderError, OutOfStock, TooMany, UnknownProduct } from "./order.ts";

type PlaceOrder = (input: {
  email: string;
  items: { productId: number; quantity: number }[];
}) => Promise<{ id: number; total: number }>;

// the HTTP adapter: translate the request in, the result or the error out
export const orderRoutes =
  (placeOrder: PlaceOrder): FastifyPluginAsync =>
  async (app) => {
    app.post<{
      Body: { email: string; items: { productId: number; quantity: number }[] };
    }>("/orders", async (request, reply) => {
      try {
        const order = await placeOrder(request.body);
        return reply.code(201).send({ id: order.id, total: order.total });
      } catch (error) {
        if (!(error instanceof OrderError)) throw error;
        const status =
          error instanceof TooMany
            ? 422
            : error instanceof OutOfStock
              ? 409
              : error instanceof UnknownProduct
                ? 422
                : 400;
        return reply.code(status).send({ title: error.message, status });
      }
    });
  };
