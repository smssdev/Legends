import { z } from "zod";

export const Money = z.object({
  amount: z.number().int().describe("piastres"),
  currency: z.literal("EGP"),
});

export const ProductOut = z.object({
  id: z.number().int(),
  name: z.string(),
  price: Money,
  stock: z.number().int(),
  created_at: z.iso.datetime(),
});

export const OrderItemOut = z.object({
  product_id: z.number().int(),
  quantity: z.number().int(),
  price: Money,
});

export const OrderOut = z.object({
  id: z.number().int(),
  status: z.enum(["pending", "cancelled"]),
  items: z.array(OrderItemOut),
  total: Money,
  created_at: z.iso.datetime(),
});

export const IdParams = z.object({ id: z.coerce.number().int().positive() });

export const egp = (amount: number) => ({ amount, currency: "EGP" as const });
