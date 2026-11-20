import type { Order, OrderStatus, Product } from "./schemas";

// A pretend server for the screenshots and the end-to-end tests: same addresses and answers as the real one
const day = 24 * 60 * 60 * 1000;
const today = Math.floor(Date.now() / day) * day;

let seed = 7;
const random = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
const pick = <T,>(list: readonly T[]): T => list[Math.floor(random() * list.length)]!;

const names = "Sara Adel|Omar Farouk|Mona Samir|Youssef Hany|Laila Nabil|Karim Fathy|Nour Hassan|Ali Mostafa|Hana Wael".split("|");
const cities = "Cairo|Giza|Alexandria|Mansoura|Aswan".split("|");
const statuses: OrderStatus[] = ["new", "paid", "paid", "shipped", "shipped", "shipped", "cancelled"];

// Orders from the last eight days, counted back from today
const orders: Order[] = Array.from({ length: 36 }, (_, i) => ({
  id: 1036 - i,
  customer: names[i % names.length]!,
  city: pick(cities),
  total: 2500 + Math.round(random() * 40) * 500,
  status: i < 3 ? "new" : pick(statuses),
  createdAt: new Date(today + 20 * 60 * 60 * 1000 - Math.floor(i / 4.5) * day - Math.floor(random() * 8) * 60 * 60 * 1000).toISOString(),
}));

const products: Product[] = [
  { id: 1, name: "Code from Zero", price: 25000, stock: 12 },
  { id: 2, name: "Bit mug", price: 8500, stock: 40 },
  { id: 3, name: "Bit cap", price: 12000, stock: 0 },
  { id: 4, name: "Bit sticker", price: 1500, stock: 300 },
];

export const server = { delay: 250, failNextChange: false };

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });

export async function fakeFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  await new Promise((resolve) => setTimeout(resolve, server.delay));
  const path = new URL(String(input), "http://shop").pathname;
  const method = init?.method ?? "GET";
  const body = init?.body ? (JSON.parse(String(init.body)) as Record<string, unknown>) : {};
  if (method !== "GET" && server.failNextChange) {
    server.failNextChange = false;
    return json({ message: "busy" }, 503);
  }

  if (path === "/api/orders") return json(orders);
  if (path === "/api/products") return json(products);

  const order = /^\/api\/orders\/(\d+)$/.exec(path);
  if (order) {
    const found = orders.find((o) => o.id === Number(order[1]));
    if (!found) return json({}, 404);
    if (method === "PATCH") found.status = body.status as OrderStatus;
    return json(found);
  }

  const product = /^\/api\/products\/(\d+)$/.exec(path);
  if (product) {
    const found = products.find((p) => p.id === Number(product[1]));
    if (!found) return json({}, 404);
    if (method === "PUT") {
      const name = String(body.name).trim();
      if (products.some((p) => p.id !== found.id && p.name.toLowerCase() === name.toLowerCase())) {
        return json({ errors: { name: "Another product already has this name." } }, 422);
      }
      Object.assign(found, { name, price: body.price, stock: body.stock });
    }
    return json(found);
  }
  return json({}, 404);
}
