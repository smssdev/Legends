"""Writes the capstone of Book 2 (React edition): an admin dashboard for Bit's shop, in English and Arabic.
Run: python3 make.py   Text placeholders are {w_…}.

The app is one real codebase, in src/, organised by the layers of the architecture chapter:
  src/api       the only code that talks to the server (zod schemas, a typed client, TanStack Query hooks)
  src/lib       pure logic, tested without React (filters, pages, the overview numbers)
  src/i18n      both languages, with Intl for money and dates; src/settings.ts keeps language and theme
  src/ui        small shared components
  src/features  the screens; src/app the routes and the layout
src/main.tsx starts it as a real site does. page.tsx is for the book's screenshots and end-to-end tests:
it installs a pretend server in place of fetch (as Mock Service Worker does in real projects), and uses
a memory router, because the screenshot tool opens a file rather than a site.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[1]))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Bit's shop admin", w_book="Code from Zero", w_mug="Bit mug", w_cap="Bit cap", w_sticker="Bit sticker",
        w_names="Sara Adel|Omar Farouk|Mona Samir|Youssef Hany|Laila Nabil|Karim Fathy|Nour Hassan|Ali Mostafa|Hana Wael",
        w_cities="Cairo|Giza|Alexandria|Mansoura|Aswan",
        w_taken="Another product already has this name.",
        w_c_server="A pretend server for the screenshots and the end-to-end tests: same addresses and answers as the real one",
        w_c_today="Orders from the last eight days, counted back from today",
        w_c_client="The only place that calls fetch: every answer is checked against its schema",
        w_c_keys="One place for query keys, so reading and invalidating always use the same names",
        w_c_opt="Show the new status at once; put the old one back if the server refuses",
        w_c_pure="Pure functions: no React, no fetch, so they are tested in milliseconds",
        w_c_url="The filters live in the address, so a filtered list can be bookmarked and shared",
        w_c_msgs="Every text of the app, in both languages; TypeScript checks that Arabic has every English key",
        w_c_size="Bundles the app as production would, and checks it against the budget",
        w_c_page="For the screenshots and end-to-end tests only",
        w_c_lazy="Loaded only when opened: the form library is not part of the first download",
        w_c_first="The first load: the entry file and every file it imports directly",
        w_s_ours="our code", w_s_later="loaded later", w_s_first="first load", w_s_under="under the budget of", w_s_over="over the budget of",
        w_t_filter="filters by status and by customer name",
        w_t_pages="splits the result into pages of eight",
        w_t_kpis="counts revenue only from paid and shipped orders",
        w_t_days="gives one bar for each of the last seven days",
        w_t_form="shows an error under each wrong field, and does not save",
        w_t_save="saves whole numbers, not the text typed",
        w_t_server="shows the server's errors under the right field",
        w_t_ship="an order can be marked as shipped",
        w_t_axe="the overview and the orders have no accessibility violations",
        w_t_ar="the whole app switches to Arabic, right to left",
        w_e_orders="Orders", w_e_paid="Paid", w_e_shipped="Shipped", w_e_overview="Overview",
        w_e_switch="العربية", w_e_dir="rtl", w_e_heading="نظرة عامة",
    ),
    "ar": dict(
        w_title="إدارة متجر بِت", w_book="البرمجة من الصفر", w_mug="كوب بِت", w_cap="قبعة بِت", w_sticker="ملصق بِت",
        w_names="سارة عادل|عمر فاروق|منى سمير|يوسف هاني|ليلى نبيل|كريم فتحي|نور حسن|علي مصطفى|هنا وائل",
        w_cities="القاهرة|الجيزة|الإسكندرية|المنصورة|أسوان",
        w_taken="منتج آخر يحمل هذا الاسم.",
        w_c_server="خادم وهمي للصور ولاختبارات الطرف إلى الطرف: العناوين والردود نفسها التي للخادم الحقيقي",
        w_c_today="طلبات آخر ثمانية أيام، عدّاً من اليوم إلى الوراء",
        w_c_client="المكان الوحيد الذي يستدعي fetch، وكل رد يُفحص بمخططه",
        w_c_keys="مكان واحد لمفاتيح الاستعلامات، فالقراءة والإبطال يستخدمان الأسماء نفسها دائماً",
        w_c_opt="اعرض الحالة الجديدة فوراً، وأعد القديمة إن رفض الخادم",
        w_c_pure="دوال نقية: لا React ولا fetch، فتُختبر في أجزاء من الثانية",
        w_c_url="المرشحات تعيش في العنوان، فتُحفظ القائمة المرشحة وتُشارك",
        w_c_msgs="كل نصوص التطبيق باللغتين، ويتأكد TypeScript أن للعربية كل مفتاح في الإنجليزية",
        w_c_size="يحزم التطبيق كما في الإنتاج، ويقارنه بالميزانية",
        w_c_page="للصور واختبارات الطرف إلى الطرف فقط",
        w_c_lazy="يُحمَّل حين يُفتح فقط: مكتبة النماذج ليست في التنزيل الأول",
        w_c_first="التحميل الأول: ملف البداية وكل ملف يستورده مباشرة",
        w_s_ours="كودنا", w_s_later="يُحمَّل لاحقاً", w_s_first="التحميل الأول", w_s_under="ضمن ميزانية", w_s_over="فوق ميزانية",
        w_t_filter="يرشّح بالحالة وباسم العميل",
        w_t_pages="يقسم النتيجة إلى صفحات من ثمانية",
        w_t_kpis="يحسب الإيرادات من الطلبات المدفوعة والمشحونة فقط",
        w_t_days="يعطي عموداً لكل يوم من آخر سبعة أيام",
        w_t_form="يعرض خطأ تحت كل حقل خاطئ، ولا يحفظ",
        w_t_save="يحفظ أعداداً صحيحة، لا النص المكتوب",
        w_t_server="يعرض أخطاء الخادم تحت الحقل الصحيح",
        w_t_ship="يمكن تحويل طلب إلى مشحون",
        w_t_axe="النظرة العامة والطلبات بلا مخالفات إتاحة",
        w_t_ar="يتحول التطبيق كله إلى الإنجليزية، من اليسار إلى اليمين",
        w_e_orders="الطلبات", w_e_paid="مدفوع", w_e_shipped="مشحون", w_e_overview="نظرة عامة",
        w_e_switch="English", w_e_dir="ltr", w_e_heading="Overview",
    ),
}

CSS = r""":root { --bg: #f5f5fb; --panel: #ffffff; --text: #1e1b2e; --muted: #57546e; --brand: #4338ca; --brand-soft: #e0e7ff; --line: #e5e7f5; --danger: #b91c1c; --ok: #047857; }
html.dark { --bg: #14121f; --panel: #1f1c30; --text: #ecebf5; --muted: #b4b1c9; --brand: #a5b4fc; --brand-soft: #312e81; --line: #34304d; --danger: #fca5a5; --ok: #6ee7b7; }
body { padding: 0; background: var(--bg); color: var(--text); }
h1, h2 { color: var(--brand); }
.app { display: grid; grid-template-columns: 150px 1fr; min-height: 100vh; }
.side { background: var(--panel); padding: 14px 10px; border-inline-end: 1px solid var(--line); }
.side .brand { font-weight: 800; color: var(--brand); margin: 0 6px 14px; display: block; }
.side a { display: block; padding: 6px 10px; border-radius: 10px; color: var(--text); text-decoration: none; }
.side a.active { background: var(--brand); color: var(--panel); }
.top { display: flex; gap: 8px; justify-content: flex-end; padding: 10px 16px; }
main { padding: 0 16px 20px; }
button { background: var(--brand); color: var(--panel); }
button.secondary { background: var(--brand-soft); color: var(--text); }
button[aria-pressed="true"] { outline: 2px solid var(--brand); outline-offset: 2px; }
.card { background: var(--panel); border-radius: 14px; padding: 12px 14px; box-shadow: 0 2px 10px rgb(0 0 0 / 0.06); margin-bottom: 12px; }
.kpis { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; margin-bottom: 12px; }
.kpi { margin: 0; } .kpi p { margin: 0; color: var(--muted); font-size: 0.85rem; } .kpi strong { font-size: 1.3rem; }
ol.bars { display: flex; gap: 8px; align-items: flex-end; height: 120px; list-style: none; margin: 0; padding: 0; }
ol.bars li { flex: 1; display: flex; flex-direction: column; justify-content: flex-end; align-items: center; height: 100%; font-size: 0.75rem; color: var(--muted); }
ol.bars .bar { width: 100%; background: var(--brand); border-radius: 6px 6px 0 0; min-height: 2px; }
.filters { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 8px; }
.filters a { padding: 3px 12px; border-radius: 999px; background: var(--brand-soft); color: var(--text); text-decoration: none; font-size: 0.9rem; }
.filters a[aria-current="page"] { background: var(--brand); color: var(--panel); }
input { font: inherit; width: 100%; padding: 6px 10px; border: 2px solid var(--line); border-radius: 10px; background: var(--panel); color: var(--text); }
label { display: block; font-weight: 600; margin-top: 8px; }
table { width: 100%; border-collapse: collapse; font-size: 0.9rem; }
th, td { text-align: start; padding: 6px 4px; border-bottom: 1px solid var(--line); }
td a { color: var(--brand); font-weight: 600; }
.badge { padding: 1px 9px; border-radius: 999px; font-size: 0.8rem; background: var(--brand-soft); color: var(--text); white-space: nowrap; }
.badge.paid { background: #fef3c7; color: #78350f; } .badge.shipped { background: #d1fae5; color: #064e3b; } .badge.cancelled { background: #fee2e2; color: #7f1d1d; }
.pager { display: flex; gap: 8px; align-items: center; justify-content: space-between; margin-top: 8px; }
dl { display: grid; grid-template-columns: auto 1fr; gap: 4px 14px; margin: 0 0 10px; } dt { color: var(--muted); } dd { margin: 0; }
.actions { display: flex; gap: 6px; flex-wrap: wrap; }
.error { color: var(--danger); margin: 2px 0 0; } .done { color: var(--ok); font-weight: 700; }
.skeleton { height: 16px; border-radius: 6px; background: var(--brand-soft); margin: 10px 0; }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
.skip { position: absolute; inset-inline-start: 8px; top: -40px; } .skip:focus { top: 8px; }
"""

PLAIN = {}
NODE = {}
BROWSER = {}

# ================================================================== src/api
PLAIN["src/api/schemas.ts"] = r'''import * as z from "zod";

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
'''

PLAIN["src/api/client.ts"] = r'''import * as z from "zod";
import { Order, Product, type OrderStatus } from "./schemas";

// {w_c_client}
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
'''

PLAIN["src/api/queries.ts"] = r'''import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "./client";
import type { Order, OrderStatus, Product } from "./schemas";

// {w_c_keys}
export const keys = {
  orders: ["orders"] as const,
  order: (id: number) => ["orders", id] as const,
  products: ["products"] as const,
  product: (id: number) => ["products", id] as const,
};

export const useOrders = () => useQuery({ queryKey: keys.orders, queryFn: api.orders });
export const useOrder = (id: number) => useQuery({ queryKey: keys.order(id), queryFn: () => api.order(id) });
export const useProducts = () => useQuery({ queryKey: keys.products, queryFn: api.products });
export const useProduct = (id: number) => useQuery({ queryKey: keys.product(id), queryFn: () => api.product(id) });

export function useSetStatus(id: number) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (status: OrderStatus) => api.setStatus(id, status),
    // {w_c_opt}
    onMutate: async (status) => {
      await client.cancelQueries({ queryKey: keys.order(id) });
      const before = client.getQueryData<Order>(keys.order(id));
      if (before) client.setQueryData<Order>(keys.order(id), { ...before, status });
      return { before };
    },
    onError: (_error, _status, context) => {
      if (context?.before) client.setQueryData(keys.order(id), context.before);
    },
    onSettled: () => client.invalidateQueries({ queryKey: keys.orders }),
  });
}

export function useSaveProduct() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (product: Product) => api.saveProduct(product),
    onSuccess: (saved) => {
      client.setQueryData(keys.product(saved.id), saved);
      void client.invalidateQueries({ queryKey: keys.products, exact: true });
    },
  });
}
'''

PLAIN["src/api/fake-server.ts"] = r'''import type { Order, OrderStatus, Product } from "./schemas";

// {w_c_server}
const day = 24 * 60 * 60 * 1000;
const today = Math.floor(Date.now() / day) * day;

let seed = 7;
const random = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
const pick = <T,>(list: readonly T[]): T => list[Math.floor(random() * list.length)]!;

const names = "{w_names}".split("|");
const cities = "{w_cities}".split("|");
const statuses: OrderStatus[] = ["new", "paid", "paid", "shipped", "shipped", "shipped", "cancelled"];

// {w_c_today}
const orders: Order[] = Array.from({ length: 36 }, (_, i) => ({
  id: 1036 - i,
  customer: names[i % names.length]!,
  city: pick(cities),
  total: 2500 + Math.round(random() * 40) * 500,
  status: i < 3 ? "new" : pick(statuses),
  createdAt: new Date(today + 20 * 60 * 60 * 1000 - Math.floor(i / 4.5) * day - Math.floor(random() * 8) * 60 * 60 * 1000).toISOString(),
}));

const products: Product[] = [
  { id: 1, name: "{w_book}", price: 25000, stock: 12 },
  { id: 2, name: "{w_mug}", price: 8500, stock: 40 },
  { id: 3, name: "{w_cap}", price: 12000, stock: 0 },
  { id: 4, name: "{w_sticker}", price: 1500, stock: 300 },
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
        return json({ errors: { name: "{w_taken}" } }, 422);
      }
      Object.assign(found, { name, price: body.price, stock: body.stock });
    }
    return json(found);
  }
  return json({}, 404);
}
'''

# ================================================================== src/lib
PLAIN["src/lib/orders.ts"] = r'''import type { Order, OrderStatus } from "../api/schemas";

// {w_c_pure}
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
'''

PLAIN["src/lib/orders.test.ts"] = r'''import { describe, expect, it } from "vitest";
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
  it("{w_t_filter}", () => {
    const f = readFilters(new URLSearchParams("status=paid&q=sara"));
    expect(filterOrders(orders, f).rows.map((o) => o.id)).toEqual([1]);
  });

  it("{w_t_pages}", () => {
    const many = Array.from({ length: 20 }, (_, i) => order(i, "new", "A", "2026-03-10"));
    const third = filterOrders(many, readFilters(new URLSearchParams("page=3")));
    expect(third).toMatchObject({ page: 3, pages: 3, count: 20 });
    expect(third.rows).toHaveLength(4);
  });
});

describe("overview", () => {
  const result = overview(orders, new Date("2026-03-10T12:00:00Z"));

  it("{w_t_kpis}", () => {
    expect(result).toMatchObject({ revenue: 8000, orders: 3, average: 4000, toShip: 1 });
  });

  it("{w_t_days}", () => {
    expect(result.days.map((d) => d.total)).toEqual([0, 0, 0, 0, 0, 3000, 5000]);
  });
});
'''

# ================================================================== src/i18n and settings
PLAIN["src/i18n/messages.ts"] = r'''// {w_c_msgs}
const en = {
  brand: "Bit's shop admin",
  skip: "Skip to content",
  overview: "Overview",
  orders: "Orders",
  products: "Products",
  switchLanguage: "العربية",
  dark: "Dark theme",
  revenue: "Revenue",
  ordersCount: "Orders",
  average: "Average order",
  toShip: "Waiting to ship",
  lastWeek: "Revenue, last 7 days",
  all: "All",
  new: "New",
  paid: "Paid",
  shipped: "Shipped",
  cancelled: "Cancelled",
  search: "Search by customer",
  order: "Order",
  customer: "Customer",
  city: "City",
  total: "Total",
  date: "Date",
  status: "Status",
  found: "{count} orders",
  page: "Page {page} of {pages}",
  previous: "Previous",
  next: "Next",
  none: "No orders match these filters.",
  orderTitle: "Order #{id}",
  markAs: "Mark as",
  allOrders: "All orders",
  failed: "Could not save, so the change was undone. Please try again.",
  name: "Name",
  price: "Price in piastres",
  stock: "Stock",
  edit: "Edit",
  save: "Save",
  saving: "Saving…",
  saved: "Saved.",
  nameError: "Write a name of 2 to 40 characters.",
  priceError: "The price must be a whole number above zero.",
  stockError: "Stock must be a whole number, 0 or more.",
  loadError: "Could not load the data.",
  retry: "Try again",
  loading: "Loading…",
  notFound: "There is no page at this address.",
};

export type Key = keyof typeof en;

const ar: Record<Key, string> = {
  brand: "إدارة متجر بِت",
  skip: "تخطَّ إلى المحتوى",
  overview: "نظرة عامة",
  orders: "الطلبات",
  products: "المنتجات",
  switchLanguage: "English",
  dark: "المظهر الداكن",
  revenue: "الإيرادات",
  ordersCount: "الطلبات",
  average: "متوسط الطلب",
  toShip: "بانتظار الشحن",
  lastWeek: "الإيرادات في آخر 7 أيام",
  all: "الكل",
  new: "جديد",
  paid: "مدفوع",
  shipped: "مشحون",
  cancelled: "ملغى",
  search: "ابحث باسم العميل",
  order: "الطلب",
  customer: "العميل",
  city: "المدينة",
  total: "الإجمالي",
  date: "التاريخ",
  status: "الحالة",
  found: "{count} طلباً",
  page: "صفحة {page} من {pages}",
  previous: "السابق",
  next: "التالي",
  none: "لا طلبات تطابق هذه المرشحات.",
  orderTitle: "الطلب رقم {id}",
  markAs: "غيّر الحالة إلى",
  allOrders: "كل الطلبات",
  failed: "تعذّر الحفظ، فأُلغي التغيير. حاول مرة أخرى.",
  name: "الاسم",
  price: "السعر بالقروش",
  stock: "المخزون",
  edit: "تعديل",
  save: "احفظ",
  saving: "جارٍ الحفظ…",
  saved: "حُفظ.",
  nameError: "اكتب اسماً من 2 إلى 40 حرفاً.",
  priceError: "السعر عدد صحيح أكبر من صفر.",
  stockError: "المخزون عدد صحيح، صفر أو أكثر.",
  loadError: "تعذّر تحميل البيانات.",
  retry: "حاول مرة أخرى",
  loading: "جارٍ التحميل…",
  notFound: "لا صفحة على هذا العنوان.",
};

export const messages = { en, ar };
export type Lang = keyof typeof messages;
'''

PLAIN["src/i18n/format.ts"] = r'''import { messages, type Key, type Lang } from "./messages";

const locales: Record<Lang, string> = { en: "en-EG", ar: "ar-EG" };

export function makeT(lang: Lang) {
  const money = new Intl.NumberFormat(locales[lang], { style: "currency", currency: "EGP", maximumFractionDigits: 0 });
  const date = new Intl.DateTimeFormat(locales[lang], { day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });
  const weekday = new Intl.DateTimeFormat(locales[lang], { weekday: "short", timeZone: "UTC" });
  const number = new Intl.NumberFormat(locales[lang]);
  const t = (key: Key, values: Record<string, string | number> = {}) =>
    messages[lang][key].replace(/\{(\w+)\}/g, (_, name: string) => {
      const value = values[name];
      return typeof value === "number" ? number.format(value) : String(value);
    });
  return Object.assign(t, {
    lang,
    money: (piastres: number) => money.format(piastres / 100),
    date: (iso: string) => date.format(new Date(iso)),
    weekday: (day: string) => weekday.format(new Date(day)),
  });
}
export type T = ReturnType<typeof makeT>;
'''

PLAIN["src/settings.ts"] = r'''import { useMemo } from "react";
import { create } from "zustand";
import { persist } from "zustand/middleware";
import { makeT } from "./i18n/format";
import type { Lang } from "./i18n/messages";

type Settings = { lang: Lang; dark: boolean; toggleLanguage: () => void; toggleDark: () => void };

export const useSettings = create<Settings>()(
  persist(
    (set) => ({
      lang: globalThis.document?.documentElement.lang === "ar" ? "ar" : "en",
      dark: false,
      toggleLanguage: () => set((s) => ({ lang: s.lang === "en" ? "ar" : "en" })),
      toggleDark: () => set((s) => ({ dark: !s.dark })),
    }),
    { name: "admin-settings" },
  ),
);

export function useT() {
  const lang = useSettings((s) => s.lang);
  return useMemo(() => makeT(lang), [lang]);
}
'''

# ================================================================== src/ui
PLAIN["src/ui/ui.tsx"] = r'''import type { ReactNode } from "react";
import type { OrderStatus } from "../api/schemas";
import { useT } from "../settings";

export function Card({ title, children }: { title?: string; children: ReactNode }) {
  return (
    <section className="card">
      {title && <h2>{title}</h2>}
      {children}
    </section>
  );
}

export function StatusBadge({ status }: { status: OrderStatus }) {
  const t = useT();
  return <span className={`badge ${status}`}>{t(status)}</span>;
}

export function Loading() {
  const t = useT();
  return (
    <div aria-busy="true" aria-label={t("loading")}>
      <div className="skeleton" />
      <div className="skeleton" />
      <div className="skeleton" />
    </div>
  );
}

export function LoadError({ retry }: { retry: () => void }) {
  const t = useT();
  return (
    <div role="alert" className="card">
      <p>{t("loadError")}</p>
      <button type="button" onClick={retry}>
        {t("retry")}
      </button>
    </div>
  );
}
'''

# ================================================================== src/features
PLAIN["src/features/overview/OverviewPage.tsx"] = r'''import { useOrders } from "../../api/queries";
import { overview } from "../../lib/orders";
import { useT } from "../../settings";
import { Card, LoadError, Loading } from "../../ui/ui";

export function OverviewPage() {
  const t = useT();
  const orders = useOrders();
  if (orders.isPending) return <Loading />;
  if (orders.isError) return <LoadError retry={() => void orders.refetch()} />;

  const o = overview(orders.data, new Date());
  const highest = Math.max(1, ...o.days.map((d) => d.total));
  const kpis = [
    [t("revenue"), t.money(o.revenue)],
    [t("ordersCount"), String(o.orders)],
    [t("average"), t.money(o.average)],
    [t("toShip"), String(o.toShip)],
  ] as const;

  return (
    <>
      <h1>{t("overview")}</h1>
      <div className="kpis">
        {kpis.map(([label, value]) => (
          <figure key={label} className="card kpi">
            <p>{label}</p>
            <strong>{value}</strong>
          </figure>
        ))}
      </div>
      <Card title={t("lastWeek")}>
        <ol className="bars">
          {o.days.map((d) => (
            <li key={d.day}>
              <span className="bar" style={{ blockSize: `${(d.total / highest) * 100}%` }} />
              <span aria-hidden="true">{t.weekday(d.day)}</span>
              <span className="sr-only">{`${t.weekday(d.day)}: ${t.money(d.total)}`}</span>
            </li>
          ))}
        </ol>
      </Card>
    </>
  );
}
'''

PLAIN["src/features/orders/OrdersPage.tsx"] = r'''import { Link, useSearchParams } from "react-router";
import { useOrders } from "../../api/queries";
import { filterOrders, readFilters, STATUSES } from "../../lib/orders";
import { useT } from "../../settings";
import { LoadError, Loading, StatusBadge } from "../../ui/ui";

export function OrdersPage() {
  const t = useT();
  const orders = useOrders();
  // {w_c_url}
  const [params, setParams] = useSearchParams();
  const filters = readFilters(params);

  const link = (changes: Record<string, string | null>) => {
    const next = new URLSearchParams(params);
    for (const [key, value] of Object.entries(changes)) {
      if (value === null) next.delete(key);
      else next.set(key, value);
    }
    return `?${next}`;
  };

  return (
    <>
      <h1>{t("orders")}</h1>
      <nav className="filters" aria-label={t("status")}>
        {(["all", ...STATUSES] as const).map((s) => (
          <Link key={s} to={link({ status: s === "all" ? null : s, page: null })} aria-current={filters.status === s ? "page" : undefined}>
            {t(s)}
          </Link>
        ))}
      </nav>
      <label htmlFor="q" className="sr-only">
        {t("search")}
      </label>
      <input
        id="q"
        type="search"
        placeholder={t("search")}
        value={filters.q}
        onChange={(e) => setParams(link({ q: e.target.value || null, page: null }).slice(1), { replace: true })}
      />
      {orders.isPending && <Loading />}
      {orders.isError && <LoadError retry={() => void orders.refetch()} />}
      {orders.isSuccess && <OrdersTable result={filterOrders(orders.data, filters)} link={link} />}
    </>
  );
}

type Result = ReturnType<typeof filterOrders>;

function OrdersTable({ result, link }: { result: Result; link: (changes: Record<string, string>) => string }) {
  const t = useT();
  if (result.count === 0) return <p role="status">{t("none")}</p>;
  return (
    <section className="card">
      <table>
        <caption className="sr-only">{t("found", { count: result.count })}</caption>
        <thead>
          <tr>
            <th scope="col">{t("order")}</th>
            <th scope="col">{t("customer")}</th>
            <th scope="col">{t("total")}</th>
            <th scope="col">{t("status")}</th>
          </tr>
        </thead>
        <tbody>
          {result.rows.map((o) => (
            <tr key={o.id}>
              <td>
                <Link to={`/orders/${o.id}`}>#{o.id}</Link>
              </td>
              <td>{o.customer}</td>
              <td>{t.money(o.total)}</td>
              <td>
                <StatusBadge status={o.status} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <div className="pager">
        {result.page > 1 ? <Link to={link({ page: String(result.page - 1) })}>{t("previous")}</Link> : <span />}
        <span>{t("page", { page: result.page, pages: result.pages })}</span>
        {result.page < result.pages ? <Link to={link({ page: String(result.page + 1) })}>{t("next")}</Link> : <span />}
      </div>
    </section>
  );
}
'''

PLAIN["src/features/orders/OrderPage.tsx"] = r'''import { Link, useParams } from "react-router";
import { useOrder, useSetStatus } from "../../api/queries";
import { STATUSES } from "../../lib/orders";
import { useT } from "../../settings";
import { Card, LoadError, Loading, StatusBadge } from "../../ui/ui";

export function OrderPage() {
  const t = useT();
  const id = Number(useParams().id);
  const order = useOrder(id);
  const setStatus = useSetStatus(id);
  if (order.isPending) return <Loading />;
  if (order.isError) return <LoadError retry={() => void order.refetch()} />;
  const o = order.data;

  return (
    <>
      <h1>{t("orderTitle", { id: String(o.id) })}</h1>
      <Card>
        <dl>
          <dt>{t("customer")}</dt>
          <dd>{o.customer}</dd>
          <dt>{t("city")}</dt>
          <dd>{o.city}</dd>
          <dt>{t("date")}</dt>
          <dd>{t.date(o.createdAt)}</dd>
          <dt>{t("total")}</dt>
          <dd>{t.money(o.total)}</dd>
          <dt>{t("status")}</dt>
          <dd aria-live="polite">
            <StatusBadge status={o.status} />
          </dd>
        </dl>
        <p>{t("markAs")}</p>
        <div className="actions">
          {STATUSES.filter((s) => s !== o.status).map((s) => (
            <button key={s} type="button" className="secondary" disabled={setStatus.isPending} onClick={() => setStatus.mutate(s)}>
              {t(s)}
            </button>
          ))}
        </div>
        {setStatus.isError && (
          <p role="alert" className="error">
            {t("failed")}
          </p>
        )}
      </Card>
      <Link to="/orders">{t("allOrders")}</Link>
    </>
  );
}
'''

PLAIN["src/features/products/ProductForm.tsx"] = r'''import { useMemo, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import type { Product } from "../../api/schemas";
import { useT } from "../../settings";
import type { T } from "../../i18n/format";

const productSchema = (t: T) =>
  z.object({
    name: z.string().trim().min(2, t("nameError")).max(40, t("nameError")),
    price: z.coerce.number<string>().int(t("priceError")).positive(t("priceError")),
    stock: z.coerce.number<string>().int(t("stockError")).min(0, t("stockError")),
  });

type Fields = "name" | "price" | "stock";
type Props = { product: Product; onSave: (product: Product) => Promise<Partial<Record<Fields, string>> | void> };

export function ProductForm({ product, onSave }: Props) {
  const t = useT();
  const schema = useMemo(() => productSchema(t), [t]);
  const [saved, setSaved] = useState(false);
  const { register, handleSubmit, setError, formState } = useForm({
    resolver: zodResolver(schema),
    defaultValues: { name: product.name, price: String(product.price), stock: String(product.stock) },
  });
  const { errors, isSubmitting } = formState;

  const submit = handleSubmit(async (values) => {
    setSaved(false);
    const serverErrors = await onSave({ ...product, ...values });
    if (!serverErrors) return setSaved(true);
    for (const [field, message] of Object.entries(serverErrors)) setError(field as Fields, { message });
  });

  const field = (name: Fields, label: string, inputMode?: "numeric") => (
    <>
      <label htmlFor={name}>{label}</label>
      <input id={name} inputMode={inputMode} aria-invalid={!!errors[name]} aria-describedby={`${name}-error`} {...register(name)} />
      {errors[name] && (
        <p className="error" id={`${name}-error`}>
          {errors[name].message}
        </p>
      )}
    </>
  );

  return (
    <form onSubmit={submit} noValidate>
      {field("name", t("name"))}
      {field("price", t("price"), "numeric")}
      {field("stock", t("stock"), "numeric")}
      <p>
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? t("saving") : t("save")}
        </button>
      </p>
      {saved && (
        <p role="status" className="done">
          {t("saved")}
        </p>
      )}
    </form>
  );
}
'''

PLAIN["src/features/products/ProductsPage.tsx"] = r'''import { Link, useParams } from "react-router";
import { useProduct, useProducts, useSaveProduct } from "../../api/queries";
import { ApiError } from "../../api/client";
import { useT } from "../../settings";
import { Card, LoadError, Loading } from "../../ui/ui";
import { ProductForm } from "./ProductForm";

export function ProductsPage() {
  const t = useT();
  const products = useProducts();
  if (products.isPending) return <Loading />;
  if (products.isError) return <LoadError retry={() => void products.refetch()} />;
  return (
    <>
      <h1>{t("products")}</h1>
      <Card>
        <table>
          <thead>
            <tr>
              <th scope="col">{t("name")}</th>
              <th scope="col">{t("price")}</th>
              <th scope="col">{t("stock")}</th>
            </tr>
          </thead>
          <tbody>
            {products.data.map((p) => (
              <tr key={p.id}>
                <td>
                  <Link to={`/products/${p.id}`} aria-label={`${t("edit")}: ${p.name}`}>
                    {p.name}
                  </Link>
                </td>
                <td>{t.money(p.price)}</td>
                <td>{p.stock}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </>
  );
}

export function ProductPage() {
  const t = useT();
  const id = Number(useParams().id);
  const product = useProduct(id);
  const save = useSaveProduct();
  if (product.isPending) return <Loading />;
  if (product.isError) return <LoadError retry={() => void product.refetch()} />;
  return (
    <>
      <h1>{product.data.name}</h1>
      <Card>
        <ProductForm
          key={product.data.id}
          product={product.data}
          onSave={async (changed) => {
            try {
              await save.mutateAsync(changed);
            } catch (error) {
              if (error instanceof ApiError && error.status === 422) return error.errors;
              throw error;
            }
          }}
        />
      </Card>
      <Link to="/products">{t("products")}</Link>
    </>
  );
}
'''

# ================================================================== src/app
PLAIN["src/app/routes.tsx"] = r'''import { useEffect } from "react";
import { NavLink, Outlet } from "react-router";
import type { RouteObject } from "react-router";
import { OrderPage } from "../features/orders/OrderPage";
import { OrdersPage } from "../features/orders/OrdersPage";
import { OverviewPage } from "../features/overview/OverviewPage";
import { useSettings, useT } from "../settings";

function Layout() {
  const t = useT();
  const { lang, dark, toggleLanguage, toggleDark } = useSettings();

  useEffect(() => {
    const html = document.documentElement;
    html.lang = lang;
    html.dir = lang === "ar" ? "rtl" : "ltr";
    html.classList.toggle("dark", dark);
  }, [lang, dark]);

  return (
    <div className="app">
      <a className="skip" href="#main">
        {t("skip")}
      </a>
      <nav className="side" aria-label={t("brand")}>
        <span className="brand">{t("brand")}</span>
        <NavLink to="/" end>
          {t("overview")}
        </NavLink>
        <NavLink to="/orders">{t("orders")}</NavLink>
        <NavLink to="/products">{t("products")}</NavLink>
      </nav>
      <div>
        <header className="top">
          <button type="button" className="secondary" onClick={toggleLanguage} lang={lang === "en" ? "ar" : "en"}>
            {t("switchLanguage")}
          </button>
          <button type="button" className="secondary" aria-pressed={dark} onClick={toggleDark}>
            {t("dark")}
          </button>
        </header>
        <main id="main">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

function NotFound() {
  const t = useT();
  return <p role="alert">{t("notFound")}</p>;
}

export const routes: RouteObject[] = [
  {
    element: <Layout />,
    children: [
      { path: "/", element: <OverviewPage /> },
      { path: "/orders", element: <OrdersPage /> },
      { path: "/orders/:id", element: <OrderPage /> },
      // {w_c_lazy}
      { path: "/products", lazy: () => import("../features/products/ProductsPage").then((m) => ({ Component: m.ProductsPage })) },
      { path: "/products/:id", lazy: () => import("../features/products/ProductsPage").then((m) => ({ Component: m.ProductPage })) },
      { path: "*", element: <NotFound /> },
    ],
  },
];
'''

PLAIN["src/main.tsx"] = r'''import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { routes } from "./app/routes";

const router = createBrowserRouter(routes);
const queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 30_000, retry: 1 } } });

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  </StrictMode>,
);
'''

PAGE = r'''// {w_c_page}
import { createRoot } from "react-dom/client";
import { createMemoryRouter, RouterProvider } from "react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { fakeFetch, server } from "./src/api/fake-server";
import { routes } from "./src/app/routes";

window.fetch = fakeFetch;
Object.assign(window, { server }); // so a test can say: server.failNextChange = true

const router = createMemoryRouter(routes);
const queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 30_000, retry: false } } });

createRoot(document.getElementById("root")!).render(
  <QueryClientProvider client={queryClient}>
    <RouterProvider router={router} />
  </QueryClientProvider>,
);
'''
BROWSER["page.tsx"] = (PAGE, CSS)

# ================================================================== tests
PLAIN["vitest.config.ts"] = r'''import { defineConfig } from "vitest/config";

export default defineConfig({
  test: { environment: "jsdom", setupFiles: ["./vitest.setup.ts"], include: ["src/**/*.test.{ts,tsx}"] },
});
'''
PLAIN["vitest.setup.ts"] = r'''import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";

afterEach(cleanup);
'''

PLAIN["src/features/products/ProductForm.test.tsx"] = r'''import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { ProductForm } from "./ProductForm";

const mug = { id: 2, name: "Bit mug", price: 8500, stock: 40 };

describe("ProductForm", () => {
  it("{w_t_form}", async () => {
    const onSave = vi.fn();
    render(<ProductForm product={mug} onSave={onSave} />);
    await userEvent.clear(screen.getByLabelText("Name"));
    await userEvent.clear(screen.getByLabelText("Price in piastres"));
    await userEvent.type(screen.getByLabelText("Price in piastres"), "85.5");
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByText("Write a name of 2 to 40 characters.")).toBeInTheDocument();
    expect(screen.getByText("The price must be a whole number above zero.")).toBeInTheDocument();
    expect(onSave).not.toHaveBeenCalled();
  });

  it("{w_t_save}", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    render(<ProductForm product={mug} onSave={onSave} />);
    await userEvent.clear(screen.getByLabelText("Stock"));
    await userEvent.type(screen.getByLabelText("Stock"), "39");
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByRole("status")).toHaveTextContent("Saved.");
    expect(onSave).toHaveBeenCalledWith({ id: 2, name: "Bit mug", price: 8500, stock: 39 });
  });

  it("{w_t_server}", async () => {
    render(<ProductForm product={mug} onSave={async () => ({ name: "Another product already has this name." })} />);
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByText("Another product already has this name.")).toBeInTheDocument();
    expect(screen.getByLabelText("Name")).toHaveAttribute("aria-invalid", "true");
  });
});
'''

PLAIN["playwright.config.ts"] = r'''import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  reporter: "list",
  webServer: { command: "node ../../../serve.mjs 4175", url: "http://localhost:4175/vendor/react.js", reuseExistingServer: true },
  use: { baseURL: "http://localhost:4175/react/capstone/{lang}/", browserName: "chromium" },
});
'''

PLAIN["e2e/admin.spec.ts"] = r'''import { expect, test, type Page } from "@playwright/test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const words = { orders: "{w_e_orders}", paid: "{w_e_paid}", shipped: "{w_e_shipped}", overview: "{w_e_overview}" };

async function noViolations(page: Page) {
  await page.addScriptTag({ path: require.resolve("axe-core/axe.min.js") });
  // @ts-expect-error axe is added to the page by the script tag above
  const found: string[] = await page.evaluate(() => axe.run().then((r) => r.violations.map((v) => v.id)));
  expect(found).toEqual([]);
}

test.beforeEach(async ({ page }) => {
  await page.goto("page.html");
});

test("{w_t_ship}", async ({ page }) => {
  await page.getByRole("link", { name: words.orders }).click();
  await page.getByRole("link", { name: words.paid, exact: true }).click();
  await page.getByRole("row").nth(1).getByRole("link").click();
  await page.getByRole("button", { name: words.shipped }).click();
  await expect(page.locator("dd .badge")).toHaveText(words.shipped);
});

test("{w_t_axe}", async ({ page }) => {
  await expect(page.getByRole("heading", { name: words.overview })).toBeVisible();
  await noViolations(page);
  await page.getByRole("link", { name: words.orders }).click();
  await expect(page.getByRole("table")).toBeVisible();
  await noViolations(page);
});

test("{w_t_ar}", async ({ page }) => {
  await page.getByRole("button", { name: "{w_e_switch}" }).click();
  await expect(page.locator("html")).toHaveAttribute("dir", "{w_e_dir}");
  await expect(page.getByRole("heading", { name: "{w_e_heading}" })).toBeVisible();
});
'''

NODE["size.ts"] = r"""import { build } from "esbuild";
import { gzipSync } from "node:zlib";

// {w_c_size}
const BUDGET_KB = 150;

const result = await build({
  entryPoints: ["src/main.tsx"],
  bundle: true,
  minify: true,
  splitting: true, // lazy routes become separate files
  format: "esm",
  write: false,
  metafile: true,
  outdir: "dist",
  define: { "process.env.NODE_ENV": '"production"' },
  logLevel: "error",
});
const outputs = result.metafile.outputs;
const gzipKB = (path: string) => gzipSync(result.outputFiles.find((f) => f.path.endsWith(path))!.contents).length / 1024;
const packageOf = (file: string) => /node_modules\/((?:@[^/]+\/)?[^/]+)/.exec(file)?.[1] ?? "{w_s_ours}";

// {w_c_first}
const first = new Set<string>();
const visit = (path: string) => {
  if (first.has(path)) return;
  first.add(path);
  for (const i of outputs[path]!.imports) if (i.kind === "import-statement") visit(i.path);
};
visit("dist/main.js");

let firstKB = 0;
for (const [path, info] of Object.entries(outputs)) {
  const kb = gzipKB(path);
  const packages = [...new Set(Object.keys(info.inputs).map(packageOf))];
  if (first.has(path)) firstKB += kb;
  else console.log(`{w_s_later}: ${kb.toFixed(1)} KB gzip (${packages.join(" + ")})`);
}
console.log(`{w_s_first}: ${firstKB.toFixed(1)} KB gzip`);
console.log(firstKB <= BUDGET_KB ? `✓ {w_s_under} ${BUDGET_KB} KB` : `✗ {w_s_over} ${BUDGET_KB} KB`);
"""

for lang, words in T.items():
    words["lang"] = lang
kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER, title_key="w_title")
