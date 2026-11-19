import { describe, expect, it } from "vitest";
import type { Order } from "../api/schemas";
import { filterOrders, overview, readFilters } from "./orders";

const order = (id: number, status: Order["status"], customer: string, day: string, total = 1000): Order => ({
  id, status, customer, city: "Cairo", total, createdAt: `${day}T10:00:00.000Z`,
});
const orders = [
  order(1, "paid", "Sara Adel", "2026-03-10", 5000),
  order(2, "shipped", "Omar Farouk", "2026-03-09", 3000),
  order(3, "cancelled", "Sara Adel", "2026-03-09", 9000),
  order(4, "new", "Mona Samir", "2026-03-01", 2000),
];

describe("filterOrders", () => {
  it("يرشّح بالحالة وباسم العميل", () => {
    const f = readFilters(new URLSearchParams("status=paid&q=sara"));
    expect(filterOrders(orders, f).rows.map((o) => o.id)).toEqual([1]);
  });

  it("يقسم النتيجة إلى صفحات من ثمانية", () => {
    const many = Array.from({ length: 20 }, (_, i) => order(i, "new", "A", "2026-03-10"));
    const third = filterOrders(many, readFilters(new URLSearchParams("page=3")));
    expect(third).toMatchObject({ page: 3, pages: 3, count: 20 });
    expect(third.rows).toHaveLength(4);
  });
});

describe("overview", () => {
  const result = overview(orders, new Date("2026-03-10T12:00:00Z"));

  it("يحسب الإيرادات من الطلبات المدفوعة والمشحونة فقط", () => {
    expect(result).toMatchObject({ revenue: 8000, orders: 3, average: 4000, toShip: 1 });
  });

  it("يعطي عموداً لكل يوم من آخر سبعة أيام", () => {
    expect(result.days.map((d) => d.total)).toEqual([0, 0, 0, 0, 0, 3000, 5000]);
  });
});
