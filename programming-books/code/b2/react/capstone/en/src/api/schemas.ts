import * as z from "zod";

export const OrderStatus = z.enum(["new", "paid", "shipped", "cancelled"]);
export type OrderStatus = z.infer<typeof OrderStatus>;

export const Order = z.object({
  id: z.number().int(),
  customer: z.string(),
  city: z.string(),
  total: z.number().int().nonnegative(), // piastres
  status: OrderStatus,
  createdAt: z.iso.datetime(),
});
export type Order = z.infer<typeof Order>;

export const Product = z.object({
  id: z.number().int(),
  name: z.string(),
  price: z.number().int().positive(), // piastres
  stock: z.number().int().nonnegative(),
});
export type Product = z.infer<typeof Product>;
