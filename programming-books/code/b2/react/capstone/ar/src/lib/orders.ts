import type { Order, OrderStatus } from "../api/schemas";

// دوال نقية: لا React ولا fetch، فتُختبر في أجزاء من الثانية
export const PAGE_SIZE = 8;
export const STATUSES: OrderStatus[] = ["new", "paid", "shipped", "cancelled"];

export type Filters = { status: OrderStatus | "all"; q: string; page: number };

export function readFilters(params: URLSearchParams): Filters {
  const status = params.get("status");
  return {
    status: STATUSES.includes(status as OrderStatus) ? (status as OrderStatus) : "all",
    q: params.get("q") ?? "",
    page: Math.max(1, Number(params.get("page")) || 1),
  };
}

export function filterOrders(orders: readonly Order[], { status, q, page }: Filters) {
  const query = q.trim().toLocaleLowerCase();
  const matching = orders
    .filter((o) => status === "all" || o.status === status)
    .filter((o) => !query || o.customer.toLocaleLowerCase().includes(query))
    .toSorted((a, b) => b.createdAt.localeCompare(a.createdAt));
  const pages = Math.max(1, Math.ceil(matching.length / PAGE_SIZE));
  const current = Math.min(page, pages);
  return { rows: matching.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE), page: current, pages, count: matching.length };
}

export function overview(orders: readonly Order[], now: Date) {
  const earning = orders.filter((o) => o.status === "paid" || o.status === "shipped");
  const revenue = earning.reduce((sum, o) => sum + o.total, 0);
  const days = Array.from({ length: 7 }, (_, i) => {
    const date = new Date(now);
    date.setUTCDate(date.getUTCDate() - (6 - i));
    const key = date.toISOString().slice(0, 10);
    const total = earning.filter((o) => o.createdAt.startsWith(key)).reduce((sum, o) => sum + o.total, 0);
    return { day: key, total };
  });
  return {
    revenue,
    orders: orders.filter((o) => o.status !== "cancelled").length,
    average: earning.length ? Math.round(revenue / earning.length) : 0,
    toShip: orders.filter((o) => o.status === "paid").length,
    days,
  };
}
