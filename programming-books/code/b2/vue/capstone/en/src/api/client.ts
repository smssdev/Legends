import * as z from "zod";
import { Order, Product, type OrderStatus } from "./schemas";

// The only place that calls fetch: every answer is checked against its schema
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly errors: Record<string, string> = {},
  ) {
    super(`HTTP ${status}`);
  }
}

async function request<T>(path: string, schema: z.ZodType<T>, init?: RequestInit): Promise<T> {
  const response = await fetch(path, { ...init, headers: { "Content-Type": "application/json" } });
  const body: unknown = await response.json().catch(() => ({}));
  if (!response.ok) {
    const errors = (body as { errors?: Record<string, string> }).errors;
    throw new ApiError(response.status, errors);
  }
  return schema.parse(body);
}

const send = (method: string, data: unknown): RequestInit => ({ method, body: JSON.stringify(data) });

export const api = {
  orders: () => request("/api/orders", z.array(Order)),
  order: (id: number) => request(`/api/orders/${id}`, Order),
  setStatus: (id: number, status: OrderStatus) => request(`/api/orders/${id}`, Order, send("PATCH", { status })),
  products: () => request("/api/products", z.array(Product)),
  product: (id: number) => request(`/api/products/${id}`, Product),
  saveProduct: (product: Product) => request(`/api/products/${product.id}`, Product, send("PUT", product)),
};
