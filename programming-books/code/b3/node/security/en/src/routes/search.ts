import type { FastifyPluginAsyncZod } from "fastify-type-provider-zod";
import { z } from "zod";
import { db } from "../db.ts";

const Query = z.object({ q: z.string().max(100) });

export const searchRoutes: FastifyPluginAsyncZod = async (app) => {
  app.get(
    "/unsafe/products",
    { schema: { querystring: Query } },
    async (request) => {
      // DANGER: the input becomes part of the SQL text
      const sql = `SELECT name, price FROM products WHERE name = '${request.query.q}'`;
      return (await db.query(sql)).rows;
    },
  );

  app.get("/products", { schema: { querystring: Query } }, async (request) => {
    // the input travels separately, as $1: it is only ever a value
    const sql = "SELECT name, price FROM products WHERE name = $1";
    return (await db.query(sql, [request.query.q])).rows;
  });
};
