var __defProp = Object.defineProperty;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __esm = (fn, res, err) => function __init() {
  if (err) throw err[0];
  try {
    return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
  } catch (e) {
    throw err = [e], e;
  }
};
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};

// code/b2/react/capstone/en/src/api/schemas.ts
import * as z from "zod";
var OrderStatus, Order, Product;
var init_schemas = __esm({
  "code/b2/react/capstone/en/src/api/schemas.ts"() {
    OrderStatus = z.enum(["new", "paid", "shipped", "cancelled"]);
    Order = z.object({
      id: z.number().int(),
      customer: z.string(),
      city: z.string(),
      total: z.number().int().nonnegative(),
      // piastres
      status: OrderStatus,
      createdAt: z.iso.datetime()
    });
    Product = z.object({
      id: z.number().int(),
      name: z.string(),
      price: z.number().int().positive(),
      // piastres
      stock: z.number().int().nonnegative()
    });
  }
});

// code/b2/react/capstone/en/src/api/client.ts
import * as z2 from "zod";
async function request(path, schema, init) {
  const response = await fetch(path, { ...init, headers: { "Content-Type": "application/json" } });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const errors = body.errors;
    throw new ApiError(response.status, errors);
  }
  return schema.parse(body);
}
var ApiError, send, api;
var init_client = __esm({
  "code/b2/react/capstone/en/src/api/client.ts"() {
    init_schemas();
    ApiError = class extends Error {
      constructor(status, errors = {}) {
        super(`HTTP ${status}`);
        this.status = status;
        this.errors = errors;
      }
      status;
      errors;
    };
    send = (method, data) => ({ method, body: JSON.stringify(data) });
    api = {
      orders: () => request("/api/orders", z2.array(Order)),
      order: (id) => request(`/api/orders/${id}`, Order),
      setStatus: (id, status) => request(`/api/orders/${id}`, Order, send("PATCH", { status })),
      products: () => request("/api/products", z2.array(Product)),
      product: (id) => request(`/api/products/${id}`, Product),
      saveProduct: (product) => request(`/api/products/${product.id}`, Product, send("PUT", product))
    };
  }
});

// code/b2/react/capstone/en/src/api/queries.ts
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
function useSetStatus(id) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (status) => api.setStatus(id, status),
    // Show the new status at once; put the old one back if the server refuses
    onMutate: async (status) => {
      await client.cancelQueries({ queryKey: keys.order(id) });
      const before = client.getQueryData(keys.order(id));
      if (before) client.setQueryData(keys.order(id), { ...before, status });
      return { before };
    },
    onError: (_error, _status, context) => {
      if (context?.before) client.setQueryData(keys.order(id), context.before);
    },
    onSettled: () => client.invalidateQueries({ queryKey: keys.orders })
  });
}
function useSaveProduct() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (product) => api.saveProduct(product),
    onSuccess: (saved) => {
      client.setQueryData(keys.product(saved.id), saved);
      void client.invalidateQueries({ queryKey: keys.products, exact: true });
    }
  });
}
var keys, useOrders, useOrder, useProducts, useProduct;
var init_queries = __esm({
  "code/b2/react/capstone/en/src/api/queries.ts"() {
    init_client();
    keys = {
      orders: ["orders"],
      order: (id) => ["orders", id],
      products: ["products"],
      product: (id) => ["products", id]
    };
    useOrders = () => useQuery({ queryKey: keys.orders, queryFn: api.orders });
    useOrder = (id) => useQuery({ queryKey: keys.order(id), queryFn: () => api.order(id) });
    useProducts = () => useQuery({ queryKey: keys.products, queryFn: api.products });
    useProduct = (id) => useQuery({ queryKey: keys.product(id), queryFn: () => api.product(id) });
  }
});

// code/b2/react/capstone/en/src/i18n/messages.ts
var en, ar, messages;
var init_messages = __esm({
  "code/b2/react/capstone/en/src/i18n/messages.ts"() {
    en = {
      brand: "Bit's shop admin",
      skip: "Skip to content",
      overview: "Overview",
      orders: "Orders",
      products: "Products",
      switchLanguage: "\u0627\u0644\u0639\u0631\u0628\u064A\u0629",
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
      saving: "Saving\u2026",
      saved: "Saved.",
      nameError: "Write a name of 2 to 40 characters.",
      priceError: "The price must be a whole number above zero.",
      stockError: "Stock must be a whole number, 0 or more.",
      loadError: "Could not load the data.",
      retry: "Try again",
      loading: "Loading\u2026",
      notFound: "There is no page at this address."
    };
    ar = {
      brand: "\u0625\u062F\u0627\u0631\u0629 \u0645\u062A\u062C\u0631 \u0628\u0650\u062A",
      skip: "\u062A\u062E\u0637\u064E\u0651 \u0625\u0644\u0649 \u0627\u0644\u0645\u062D\u062A\u0648\u0649",
      overview: "\u0646\u0638\u0631\u0629 \u0639\u0627\u0645\u0629",
      orders: "\u0627\u0644\u0637\u0644\u0628\u0627\u062A",
      products: "\u0627\u0644\u0645\u0646\u062A\u062C\u0627\u062A",
      switchLanguage: "English",
      dark: "\u0627\u0644\u0645\u0638\u0647\u0631 \u0627\u0644\u062F\u0627\u0643\u0646",
      revenue: "\u0627\u0644\u0625\u064A\u0631\u0627\u062F\u0627\u062A",
      ordersCount: "\u0627\u0644\u0637\u0644\u0628\u0627\u062A",
      average: "\u0645\u062A\u0648\u0633\u0637 \u0627\u0644\u0637\u0644\u0628",
      toShip: "\u0628\u0627\u0646\u062A\u0638\u0627\u0631 \u0627\u0644\u0634\u062D\u0646",
      lastWeek: "\u0627\u0644\u0625\u064A\u0631\u0627\u062F\u0627\u062A \u0641\u064A \u0622\u062E\u0631 7 \u0623\u064A\u0627\u0645",
      all: "\u0627\u0644\u0643\u0644",
      new: "\u062C\u062F\u064A\u062F",
      paid: "\u0645\u062F\u0641\u0648\u0639",
      shipped: "\u0645\u0634\u062D\u0648\u0646",
      cancelled: "\u0645\u0644\u063A\u0649",
      search: "\u0627\u0628\u062D\u062B \u0628\u0627\u0633\u0645 \u0627\u0644\u0639\u0645\u064A\u0644",
      order: "\u0627\u0644\u0637\u0644\u0628",
      customer: "\u0627\u0644\u0639\u0645\u064A\u0644",
      city: "\u0627\u0644\u0645\u062F\u064A\u0646\u0629",
      total: "\u0627\u0644\u0625\u062C\u0645\u0627\u0644\u064A",
      date: "\u0627\u0644\u062A\u0627\u0631\u064A\u062E",
      status: "\u0627\u0644\u062D\u0627\u0644\u0629",
      found: "{count} \u0637\u0644\u0628\u0627\u064B",
      page: "\u0635\u0641\u062D\u0629 {page} \u0645\u0646 {pages}",
      previous: "\u0627\u0644\u0633\u0627\u0628\u0642",
      next: "\u0627\u0644\u062A\u0627\u0644\u064A",
      none: "\u0644\u0627 \u0637\u0644\u0628\u0627\u062A \u062A\u0637\u0627\u0628\u0642 \u0647\u0630\u0647 \u0627\u0644\u0645\u0631\u0634\u062D\u0627\u062A.",
      orderTitle: "\u0627\u0644\u0637\u0644\u0628 \u0631\u0642\u0645 {id}",
      markAs: "\u063A\u064A\u0651\u0631 \u0627\u0644\u062D\u0627\u0644\u0629 \u0625\u0644\u0649",
      allOrders: "\u0643\u0644 \u0627\u0644\u0637\u0644\u0628\u0627\u062A",
      failed: "\u062A\u0639\u0630\u0651\u0631 \u0627\u0644\u062D\u0641\u0638\u060C \u0641\u0623\u064F\u0644\u063A\u064A \u0627\u0644\u062A\u063A\u064A\u064A\u0631. \u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649.",
      name: "\u0627\u0644\u0627\u0633\u0645",
      price: "\u0627\u0644\u0633\u0639\u0631 \u0628\u0627\u0644\u0642\u0631\u0648\u0634",
      stock: "\u0627\u0644\u0645\u062E\u0632\u0648\u0646",
      edit: "\u062A\u0639\u062F\u064A\u0644",
      save: "\u0627\u062D\u0641\u0638",
      saving: "\u062C\u0627\u0631\u064D \u0627\u0644\u062D\u0641\u0638\u2026",
      saved: "\u062D\u064F\u0641\u0638.",
      nameError: "\u0627\u0643\u062A\u0628 \u0627\u0633\u0645\u0627\u064B \u0645\u0646 2 \u0625\u0644\u0649 40 \u062D\u0631\u0641\u0627\u064B.",
      priceError: "\u0627\u0644\u0633\u0639\u0631 \u0639\u062F\u062F \u0635\u062D\u064A\u062D \u0623\u0643\u0628\u0631 \u0645\u0646 \u0635\u0641\u0631.",
      stockError: "\u0627\u0644\u0645\u062E\u0632\u0648\u0646 \u0639\u062F\u062F \u0635\u062D\u064A\u062D\u060C \u0635\u0641\u0631 \u0623\u0648 \u0623\u0643\u062B\u0631.",
      loadError: "\u062A\u0639\u0630\u0651\u0631 \u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0628\u064A\u0627\u0646\u0627\u062A.",
      retry: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
      loading: "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0645\u064A\u0644\u2026",
      notFound: "\u0644\u0627 \u0635\u0641\u062D\u0629 \u0639\u0644\u0649 \u0647\u0630\u0627 \u0627\u0644\u0639\u0646\u0648\u0627\u0646."
    };
    messages = { en, ar };
  }
});

// code/b2/react/capstone/en/src/i18n/format.ts
function makeT(lang) {
  const money = new Intl.NumberFormat(locales[lang], { style: "currency", currency: "EGP", maximumFractionDigits: 0 });
  const date = new Intl.DateTimeFormat(locales[lang], { day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });
  const weekday = new Intl.DateTimeFormat(locales[lang], { weekday: "short", timeZone: "UTC" });
  const number2 = new Intl.NumberFormat(locales[lang]);
  const t = (key, values = {}) => messages[lang][key].replace(/\{(\w+)\}/g, (_, name) => {
    const value = values[name];
    return typeof value === "number" ? number2.format(value) : String(value);
  });
  return Object.assign(t, {
    lang,
    money: (piastres) => money.format(piastres / 100),
    date: (iso2) => date.format(new Date(iso2)),
    weekday: (day2) => weekday.format(new Date(day2))
  });
}
var locales;
var init_format = __esm({
  "code/b2/react/capstone/en/src/i18n/format.ts"() {
    init_messages();
    locales = { en: "en-EG", ar: "ar-EG" };
  }
});

// code/b2/react/capstone/en/src/settings.ts
import { useMemo } from "react";
import { create } from "zustand";
import { persist } from "zustand/middleware";
function useT() {
  const lang = useSettings((s) => s.lang);
  return useMemo(() => makeT(lang), [lang]);
}
var useSettings;
var init_settings = __esm({
  "code/b2/react/capstone/en/src/settings.ts"() {
    init_format();
    useSettings = create()(
      persist(
        (set) => ({
          lang: globalThis.document?.documentElement.lang === "ar" ? "ar" : "en",
          dark: false,
          toggleLanguage: () => set((s) => ({ lang: s.lang === "en" ? "ar" : "en" })),
          toggleDark: () => set((s) => ({ dark: !s.dark }))
        }),
        { name: "admin-settings" }
      )
    );
  }
});

// code/b2/react/capstone/en/src/ui/ui.tsx
import { jsx, jsxs } from "react/jsx-runtime";
function Card({ title, children }) {
  return /* @__PURE__ */ jsxs("section", { className: "card", children: [
    title && /* @__PURE__ */ jsx("h2", { children: title }),
    children
  ] });
}
function StatusBadge({ status }) {
  const t = useT();
  return /* @__PURE__ */ jsx("span", { className: `badge ${status}`, children: t(status) });
}
function Loading() {
  const t = useT();
  return /* @__PURE__ */ jsxs("div", { "aria-busy": "true", "aria-label": t("loading"), children: [
    /* @__PURE__ */ jsx("div", { className: "skeleton" }),
    /* @__PURE__ */ jsx("div", { className: "skeleton" }),
    /* @__PURE__ */ jsx("div", { className: "skeleton" })
  ] });
}
function LoadError({ retry }) {
  const t = useT();
  return /* @__PURE__ */ jsxs("div", { role: "alert", className: "card", children: [
    /* @__PURE__ */ jsx("p", { children: t("loadError") }),
    /* @__PURE__ */ jsx("button", { type: "button", onClick: retry, children: t("retry") })
  ] });
}
var init_ui = __esm({
  "code/b2/react/capstone/en/src/ui/ui.tsx"() {
    init_settings();
  }
});

// code/b2/react/capstone/en/src/features/products/ProductForm.tsx
import { useMemo as useMemo2, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z3 from "zod";
import { Fragment as Fragment4, jsx as jsx5, jsxs as jsxs5 } from "react/jsx-runtime";
function ProductForm({ product, onSave }) {
  const t = useT();
  const schema = useMemo2(() => productSchema(t), [t]);
  const [saved, setSaved] = useState(false);
  const { register, handleSubmit, setError, formState } = useForm({
    resolver: zodResolver(schema),
    defaultValues: { name: product.name, price: String(product.price), stock: String(product.stock) }
  });
  const { errors, isSubmitting } = formState;
  const submit = handleSubmit(async (values) => {
    setSaved(false);
    const serverErrors = await onSave({ ...product, ...values });
    if (!serverErrors) return setSaved(true);
    for (const [field2, message] of Object.entries(serverErrors)) setError(field2, { message });
  });
  const field = (name, label, inputMode) => /* @__PURE__ */ jsxs5(Fragment4, { children: [
    /* @__PURE__ */ jsx5("label", { htmlFor: name, children: label }),
    /* @__PURE__ */ jsx5("input", { id: name, inputMode, "aria-invalid": !!errors[name], "aria-describedby": `${name}-error`, ...register(name) }),
    errors[name] && /* @__PURE__ */ jsx5("p", { className: "error", id: `${name}-error`, children: errors[name].message })
  ] });
  return /* @__PURE__ */ jsxs5("form", { onSubmit: submit, noValidate: true, children: [
    field("name", t("name")),
    field("price", t("price"), "numeric"),
    field("stock", t("stock"), "numeric"),
    /* @__PURE__ */ jsx5("p", { children: /* @__PURE__ */ jsx5("button", { type: "submit", disabled: isSubmitting, children: isSubmitting ? t("saving") : t("save") }) }),
    saved && /* @__PURE__ */ jsx5("p", { role: "status", className: "done", children: t("saved") })
  ] });
}
var productSchema;
var init_ProductForm = __esm({
  "code/b2/react/capstone/en/src/features/products/ProductForm.tsx"() {
    init_settings();
    productSchema = (t) => z3.object({
      name: z3.string().trim().min(2, t("nameError")).max(40, t("nameError")),
      price: z3.coerce.number().int(t("priceError")).positive(t("priceError")),
      stock: z3.coerce.number().int(t("stockError")).min(0, t("stockError"))
    });
  }
});

// code/b2/react/capstone/en/src/features/products/ProductsPage.tsx
var ProductsPage_exports = {};
__export(ProductsPage_exports, {
  ProductPage: () => ProductPage,
  ProductsPage: () => ProductsPage
});
import { Link as Link3, useParams as useParams2 } from "react-router";
import { Fragment as Fragment5, jsx as jsx6, jsxs as jsxs6 } from "react/jsx-runtime";
function ProductsPage() {
  const t = useT();
  const products2 = useProducts();
  if (products2.isPending) return /* @__PURE__ */ jsx6(Loading, {});
  if (products2.isError) return /* @__PURE__ */ jsx6(LoadError, { retry: () => void products2.refetch() });
  return /* @__PURE__ */ jsxs6(Fragment5, { children: [
    /* @__PURE__ */ jsx6("h1", { children: t("products") }),
    /* @__PURE__ */ jsx6(Card, { children: /* @__PURE__ */ jsxs6("table", { children: [
      /* @__PURE__ */ jsx6("thead", { children: /* @__PURE__ */ jsxs6("tr", { children: [
        /* @__PURE__ */ jsx6("th", { scope: "col", children: t("name") }),
        /* @__PURE__ */ jsx6("th", { scope: "col", children: t("price") }),
        /* @__PURE__ */ jsx6("th", { scope: "col", children: t("stock") })
      ] }) }),
      /* @__PURE__ */ jsx6("tbody", { children: products2.data.map((p) => /* @__PURE__ */ jsxs6("tr", { children: [
        /* @__PURE__ */ jsx6("td", { children: /* @__PURE__ */ jsx6(Link3, { to: `/products/${p.id}`, "aria-label": `${t("edit")}: ${p.name}`, children: p.name }) }),
        /* @__PURE__ */ jsx6("td", { children: t.money(p.price) }),
        /* @__PURE__ */ jsx6("td", { children: p.stock })
      ] }, p.id)) })
    ] }) })
  ] });
}
function ProductPage() {
  const t = useT();
  const id = Number(useParams2().id);
  const product = useProduct(id);
  const save = useSaveProduct();
  if (product.isPending) return /* @__PURE__ */ jsx6(Loading, {});
  if (product.isError) return /* @__PURE__ */ jsx6(LoadError, { retry: () => void product.refetch() });
  return /* @__PURE__ */ jsxs6(Fragment5, { children: [
    /* @__PURE__ */ jsx6("h1", { children: product.data.name }),
    /* @__PURE__ */ jsx6(Card, { children: /* @__PURE__ */ jsx6(
      ProductForm,
      {
        product: product.data,
        onSave: async (changed) => {
          try {
            await save.mutateAsync(changed);
          } catch (error) {
            if (error instanceof ApiError && error.status === 422) return error.errors;
            throw error;
          }
        }
      },
      product.data.id
    ) }),
    /* @__PURE__ */ jsx6(Link3, { to: "/products", children: t("products") })
  ] });
}
var init_ProductsPage = __esm({
  "code/b2/react/capstone/en/src/features/products/ProductsPage.tsx"() {
    init_queries();
    init_client();
    init_settings();
    init_ui();
    init_ProductForm();
  }
});

// code/b2/react/capstone/en/page.tsx
import { createRoot } from "react-dom/client";
import { createMemoryRouter, RouterProvider } from "react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

// code/b2/react/capstone/en/src/api/fake-server.ts
var day = 24 * 60 * 60 * 1e3;
var today = Math.floor(Date.now() / day) * day;
var seed = 7;
var random = () => (seed = seed * 16807 % 2147483647) / 2147483647;
var pick = (list) => list[Math.floor(random() * list.length)];
var names = "Sara Adel|Omar Farouk|Mona Samir|Youssef Hany|Laila Nabil|Karim Fathy|Nour Hassan|Ali Mostafa|Hana Wael".split("|");
var cities = "Cairo|Giza|Alexandria|Mansoura|Aswan".split("|");
var statuses = ["new", "paid", "paid", "shipped", "shipped", "shipped", "cancelled"];
var orders = Array.from({ length: 36 }, (_, i) => ({
  id: 1036 - i,
  customer: names[i % names.length],
  city: pick(cities),
  total: 2500 + Math.round(random() * 40) * 500,
  status: i < 3 ? "new" : pick(statuses),
  createdAt: new Date(today + 20 * 60 * 60 * 1e3 - Math.floor(i / 4.5) * day - Math.floor(random() * 8) * 60 * 60 * 1e3).toISOString()
}));
var products = [
  { id: 1, name: "Code from Zero", price: 25e3, stock: 12 },
  { id: 2, name: "Bit mug", price: 8500, stock: 40 },
  { id: 3, name: "Bit cap", price: 12e3, stock: 0 },
  { id: 4, name: "Bit sticker", price: 1500, stock: 300 }
];
var server = { delay: 250, failNextChange: false };
var json = (data, status = 200) => new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });
async function fakeFetch(input, init) {
  await new Promise((resolve) => setTimeout(resolve, server.delay));
  const path = new URL(String(input), "http://shop").pathname;
  const method = init?.method ?? "GET";
  const body = init?.body ? JSON.parse(String(init.body)) : {};
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
    if (method === "PATCH") found.status = body.status;
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

// code/b2/react/capstone/en/src/app/routes.tsx
import { useEffect } from "react";
import { NavLink, Outlet } from "react-router";

// code/b2/react/capstone/en/src/features/orders/OrderPage.tsx
init_queries();
import { Link, useParams } from "react-router";

// code/b2/react/capstone/en/src/lib/orders.ts
var PAGE_SIZE = 8;
var STATUSES = ["new", "paid", "shipped", "cancelled"];
function readFilters(params) {
  const status = params.get("status");
  return {
    status: STATUSES.includes(status) ? status : "all",
    q: params.get("q") ?? "",
    page: Math.max(1, Number(params.get("page")) || 1)
  };
}
function filterOrders(orders2, { status, q, page }) {
  const query = q.trim().toLocaleLowerCase();
  const matching = orders2.filter((o) => status === "all" || o.status === status).filter((o) => !query || o.customer.toLocaleLowerCase().includes(query)).toSorted((a, b) => b.createdAt.localeCompare(a.createdAt));
  const pages = Math.max(1, Math.ceil(matching.length / PAGE_SIZE));
  const current = Math.min(page, pages);
  return { rows: matching.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE), page: current, pages, count: matching.length };
}
function overview(orders2, now) {
  const earning = orders2.filter((o) => o.status === "paid" || o.status === "shipped");
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
    orders: orders2.filter((o) => o.status !== "cancelled").length,
    average: earning.length ? Math.round(revenue / earning.length) : 0,
    toShip: orders2.filter((o) => o.status === "paid").length,
    days
  };
}

// code/b2/react/capstone/en/src/features/orders/OrderPage.tsx
init_settings();
init_ui();
import { Fragment, jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
function OrderPage() {
  const t = useT();
  const id = Number(useParams().id);
  const order = useOrder(id);
  const setStatus = useSetStatus(id);
  if (order.isPending) return /* @__PURE__ */ jsx2(Loading, {});
  if (order.isError) return /* @__PURE__ */ jsx2(LoadError, { retry: () => void order.refetch() });
  const o = order.data;
  return /* @__PURE__ */ jsxs2(Fragment, { children: [
    /* @__PURE__ */ jsx2("h1", { children: t("orderTitle", { id: String(o.id) }) }),
    /* @__PURE__ */ jsxs2(Card, { children: [
      /* @__PURE__ */ jsxs2("dl", { children: [
        /* @__PURE__ */ jsx2("dt", { children: t("customer") }),
        /* @__PURE__ */ jsx2("dd", { children: o.customer }),
        /* @__PURE__ */ jsx2("dt", { children: t("city") }),
        /* @__PURE__ */ jsx2("dd", { children: o.city }),
        /* @__PURE__ */ jsx2("dt", { children: t("date") }),
        /* @__PURE__ */ jsx2("dd", { children: t.date(o.createdAt) }),
        /* @__PURE__ */ jsx2("dt", { children: t("total") }),
        /* @__PURE__ */ jsx2("dd", { children: t.money(o.total) }),
        /* @__PURE__ */ jsx2("dt", { children: t("status") }),
        /* @__PURE__ */ jsx2("dd", { "aria-live": "polite", children: /* @__PURE__ */ jsx2(StatusBadge, { status: o.status }) })
      ] }),
      /* @__PURE__ */ jsx2("p", { children: t("markAs") }),
      /* @__PURE__ */ jsx2("div", { className: "actions", children: STATUSES.filter((s) => s !== o.status).map((s) => /* @__PURE__ */ jsx2("button", { type: "button", className: "secondary", disabled: setStatus.isPending, onClick: () => setStatus.mutate(s), children: t(s) }, s)) }),
      setStatus.isError && /* @__PURE__ */ jsx2("p", { role: "alert", className: "error", children: t("failed") })
    ] }),
    /* @__PURE__ */ jsx2(Link, { to: "/orders", children: t("allOrders") })
  ] });
}

// code/b2/react/capstone/en/src/features/orders/OrdersPage.tsx
init_queries();
import { Link as Link2, useSearchParams } from "react-router";
init_settings();
init_ui();
import { Fragment as Fragment2, jsx as jsx3, jsxs as jsxs3 } from "react/jsx-runtime";
function OrdersPage() {
  const t = useT();
  const orders2 = useOrders();
  const [params, setParams] = useSearchParams();
  const filters = readFilters(params);
  const link = (changes) => {
    const next = new URLSearchParams(params);
    for (const [key, value] of Object.entries(changes)) {
      if (value === null) next.delete(key);
      else next.set(key, value);
    }
    return `?${next}`;
  };
  return /* @__PURE__ */ jsxs3(Fragment2, { children: [
    /* @__PURE__ */ jsx3("h1", { children: t("orders") }),
    /* @__PURE__ */ jsx3("nav", { className: "filters", "aria-label": t("status"), children: ["all", ...STATUSES].map((s) => /* @__PURE__ */ jsx3(Link2, { to: link({ status: s === "all" ? null : s, page: null }), "aria-current": filters.status === s ? "page" : void 0, children: t(s) }, s)) }),
    /* @__PURE__ */ jsx3("label", { htmlFor: "q", className: "sr-only", children: t("search") }),
    /* @__PURE__ */ jsx3(
      "input",
      {
        id: "q",
        type: "search",
        placeholder: t("search"),
        value: filters.q,
        onChange: (e) => setParams(link({ q: e.target.value || null, page: null }).slice(1), { replace: true })
      }
    ),
    orders2.isPending && /* @__PURE__ */ jsx3(Loading, {}),
    orders2.isError && /* @__PURE__ */ jsx3(LoadError, { retry: () => void orders2.refetch() }),
    orders2.isSuccess && /* @__PURE__ */ jsx3(OrdersTable, { result: filterOrders(orders2.data, filters), link })
  ] });
}
function OrdersTable({ result, link }) {
  const t = useT();
  if (result.count === 0) return /* @__PURE__ */ jsx3("p", { role: "status", children: t("none") });
  return /* @__PURE__ */ jsxs3("section", { className: "card", children: [
    /* @__PURE__ */ jsxs3("table", { children: [
      /* @__PURE__ */ jsx3("caption", { className: "sr-only", children: t("found", { count: result.count }) }),
      /* @__PURE__ */ jsx3("thead", { children: /* @__PURE__ */ jsxs3("tr", { children: [
        /* @__PURE__ */ jsx3("th", { scope: "col", children: t("order") }),
        /* @__PURE__ */ jsx3("th", { scope: "col", children: t("customer") }),
        /* @__PURE__ */ jsx3("th", { scope: "col", children: t("total") }),
        /* @__PURE__ */ jsx3("th", { scope: "col", children: t("status") })
      ] }) }),
      /* @__PURE__ */ jsx3("tbody", { children: result.rows.map((o) => /* @__PURE__ */ jsxs3("tr", { children: [
        /* @__PURE__ */ jsx3("td", { children: /* @__PURE__ */ jsxs3(Link2, { to: `/orders/${o.id}`, children: [
          "#",
          o.id
        ] }) }),
        /* @__PURE__ */ jsx3("td", { children: o.customer }),
        /* @__PURE__ */ jsx3("td", { children: t.money(o.total) }),
        /* @__PURE__ */ jsx3("td", { children: /* @__PURE__ */ jsx3(StatusBadge, { status: o.status }) })
      ] }, o.id)) })
    ] }),
    /* @__PURE__ */ jsxs3("div", { className: "pager", children: [
      result.page > 1 ? /* @__PURE__ */ jsx3(Link2, { to: link({ page: String(result.page - 1) }), children: t("previous") }) : /* @__PURE__ */ jsx3("span", {}),
      /* @__PURE__ */ jsx3("span", { children: t("page", { page: result.page, pages: result.pages }) }),
      result.page < result.pages ? /* @__PURE__ */ jsx3(Link2, { to: link({ page: String(result.page + 1) }), children: t("next") }) : /* @__PURE__ */ jsx3("span", {})
    ] })
  ] });
}

// code/b2/react/capstone/en/src/features/overview/OverviewPage.tsx
init_queries();
init_settings();
init_ui();
import { Fragment as Fragment3, jsx as jsx4, jsxs as jsxs4 } from "react/jsx-runtime";
function OverviewPage() {
  const t = useT();
  const orders2 = useOrders();
  if (orders2.isPending) return /* @__PURE__ */ jsx4(Loading, {});
  if (orders2.isError) return /* @__PURE__ */ jsx4(LoadError, { retry: () => void orders2.refetch() });
  const o = overview(orders2.data, /* @__PURE__ */ new Date());
  const highest = Math.max(1, ...o.days.map((d) => d.total));
  const kpis = [
    [t("revenue"), t.money(o.revenue)],
    [t("ordersCount"), String(o.orders)],
    [t("average"), t.money(o.average)],
    [t("toShip"), String(o.toShip)]
  ];
  return /* @__PURE__ */ jsxs4(Fragment3, { children: [
    /* @__PURE__ */ jsx4("h1", { children: t("overview") }),
    /* @__PURE__ */ jsx4("div", { className: "kpis", children: kpis.map(([label, value]) => /* @__PURE__ */ jsxs4("figure", { className: "card kpi", children: [
      /* @__PURE__ */ jsx4("p", { children: label }),
      /* @__PURE__ */ jsx4("strong", { children: value })
    ] }, label)) }),
    /* @__PURE__ */ jsx4(Card, { title: t("lastWeek"), children: /* @__PURE__ */ jsx4("ol", { className: "bars", children: o.days.map((d) => /* @__PURE__ */ jsxs4("li", { children: [
      /* @__PURE__ */ jsx4("span", { className: "bar", style: { blockSize: `${d.total / highest * 100}%` } }),
      /* @__PURE__ */ jsx4("span", { "aria-hidden": "true", children: t.weekday(d.day) }),
      /* @__PURE__ */ jsx4("span", { className: "sr-only", children: `${t.weekday(d.day)}: ${t.money(d.total)}` })
    ] }, d.day)) }) })
  ] });
}

// code/b2/react/capstone/en/src/app/routes.tsx
init_settings();
import { jsx as jsx7, jsxs as jsxs7 } from "react/jsx-runtime";
function Layout() {
  const t = useT();
  const { lang, dark, toggleLanguage, toggleDark } = useSettings();
  useEffect(() => {
    const html = document.documentElement;
    html.lang = lang;
    html.dir = lang === "ar" ? "rtl" : "ltr";
    html.classList.toggle("dark", dark);
  }, [lang, dark]);
  return /* @__PURE__ */ jsxs7("div", { className: "app", children: [
    /* @__PURE__ */ jsx7("a", { className: "skip", href: "#main", children: t("skip") }),
    /* @__PURE__ */ jsxs7("nav", { className: "side", "aria-label": t("brand"), children: [
      /* @__PURE__ */ jsx7("span", { className: "brand", children: t("brand") }),
      /* @__PURE__ */ jsx7(NavLink, { to: "/", end: true, children: t("overview") }),
      /* @__PURE__ */ jsx7(NavLink, { to: "/orders", children: t("orders") }),
      /* @__PURE__ */ jsx7(NavLink, { to: "/products", children: t("products") })
    ] }),
    /* @__PURE__ */ jsxs7("div", { children: [
      /* @__PURE__ */ jsxs7("header", { className: "top", children: [
        /* @__PURE__ */ jsx7("button", { type: "button", className: "secondary", onClick: toggleLanguage, lang: lang === "en" ? "ar" : "en", children: t("switchLanguage") }),
        /* @__PURE__ */ jsx7("button", { type: "button", className: "secondary", "aria-pressed": dark, onClick: toggleDark, children: t("dark") })
      ] }),
      /* @__PURE__ */ jsx7("main", { id: "main", children: /* @__PURE__ */ jsx7(Outlet, {}) })
    ] })
  ] });
}
function NotFound() {
  const t = useT();
  return /* @__PURE__ */ jsx7("p", { role: "alert", children: t("notFound") });
}
var routes = [
  {
    element: /* @__PURE__ */ jsx7(Layout, {}),
    children: [
      { path: "/", element: /* @__PURE__ */ jsx7(OverviewPage, {}) },
      { path: "/orders", element: /* @__PURE__ */ jsx7(OrdersPage, {}) },
      { path: "/orders/:id", element: /* @__PURE__ */ jsx7(OrderPage, {}) },
      // Loaded only when opened: the form library is not part of the first download
      { path: "/products", lazy: () => Promise.resolve().then(() => (init_ProductsPage(), ProductsPage_exports)).then((m) => ({ Component: m.ProductsPage })) },
      { path: "/products/:id", lazy: () => Promise.resolve().then(() => (init_ProductsPage(), ProductsPage_exports)).then((m) => ({ Component: m.ProductPage })) },
      { path: "*", element: /* @__PURE__ */ jsx7(NotFound, {}) }
    ]
  }
];

// code/b2/react/capstone/en/page.tsx
import { jsx as jsx8 } from "react/jsx-runtime";
window.fetch = fakeFetch;
Object.assign(window, { server });
var router = createMemoryRouter(routes);
var queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 3e4, retry: false } } });
createRoot(document.getElementById("root")).render(
  /* @__PURE__ */ jsx8(QueryClientProvider, { client: queryClient, children: /* @__PURE__ */ jsx8(RouterProvider, { router }) })
);
