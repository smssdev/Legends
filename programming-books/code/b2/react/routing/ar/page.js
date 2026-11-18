var __getOwnPropNames = Object.getOwnPropertyNames;
var __esm = (fn, res, err) => function __init() {
  if (err) throw err[0];
  try {
    return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
  } catch (e) {
    throw err = [e], e;
  }
};
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/api.ts
async function getProducts(category) {
  await wait(300);
  const list = category ? products.filter((p) => p.category === category) : products;
  return structuredClone(list);
}
async function getProduct(id) {
  await wait(300);
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  return structuredClone(product);
}
var products, NotFoundError, wait;
var init_api = __esm({
  "ar/api.ts"() {
    products = [
      { id: 1, name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", description: "\u0627\u0644\u0643\u062A\u0627\u0628 \u0627\u0644\u0623\u0648\u0644 \u0627\u0644\u0648\u062F\u0648\u062F \u0641\u064A \u0627\u0644\u0633\u0644\u0633\u0644\u0629.", price: 25, category: "books", favourite: false },
      { id: 2, name: "\u0643\u0648\u0628 \u0628\u0650\u062A", description: "\u0643\u0648\u0628 \u0643\u0628\u064A\u0631 \u0644\u0644\u064A\u0627\u0644\u064A \u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0627\u0644\u0637\u0648\u064A\u0644\u0629.", price: 8, category: "gifts", favourite: false },
      { id: 3, name: "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A", description: "\u062A\u062D\u0645\u064A \u0639\u064A\u0646\u064A\u0643 \u0645\u0646 \u0627\u0644\u0634\u0645\u0633.", price: 12, category: "gifts", favourite: true },
      { id: 4, name: "\u0645\u0644\u0635\u0642 \u0628\u0650\u062A", description: "\u0644\u062D\u0627\u0633\u0648\u0628\u0643 \u0627\u0644\u0645\u062D\u0645\u0648\u0644.", price: 3, category: "gifts", favourite: false }
    ];
    NotFoundError = class extends Error {
    };
    wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  }
});

// ar/routes.tsx
import { Link, NavLink, Outlet, useParams, useRouteError, useSearchParams } from "react-router";
import { useQuery } from "@tanstack/react-query";
import { jsx, jsxs } from "react/jsx-runtime";
function Layout() {
  return /* @__PURE__ */ jsxs("div", { className: "layout", children: [
    /* @__PURE__ */ jsxs("nav", { children: [
      /* @__PURE__ */ jsx("span", { className: "brand", children: "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A" }),
      /* @__PURE__ */ jsx(NavLink, { to: "/", end: true, children: "\u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629" }),
      /* @__PURE__ */ jsx(NavLink, { to: "/products", children: "\u0627\u0644\u0645\u0646\u062A\u062C\u0627\u062A" })
    ] }),
    /* @__PURE__ */ jsx(Outlet, {})
  ] });
}
function Home() {
  return /* @__PURE__ */ jsx("p", { className: "card", children: "\u0623\u0647\u0644\u0627\u064B \u0628\u0643! \u062A\u0635\u0641\u0651\u062D \u0627\u0644\u0645\u0646\u062A\u062C\u0627\u062A\u060C \u0623\u0648 \u0627\u0628\u062D\u062B \u0639\u0646 \u0634\u064A\u0621." });
}
function Products() {
  const [params] = useSearchParams();
  const category = params.get("category");
  const query = useQuery({
    queryKey: ["products", category],
    queryFn: () => getProducts(category)
  });
  return /* @__PURE__ */ jsxs("section", { className: "card", children: [
    /* @__PURE__ */ jsx("div", { className: "filters", children: CATEGORIES.map((c) => /* @__PURE__ */ jsx(Link, { to: c.value ? `?category=${c.value}` : ".", className: c.value === category ? "on" : "", children: c.label }, c.label)) }),
    query.isPending && /* @__PURE__ */ jsx(Skeleton, {}),
    query.isError && /* @__PURE__ */ jsxs("p", { className: "error", children: [
      "\u062D\u062F\u062B \u062E\u0637\u0623: ",
      query.error.message
    ] }),
    query.isSuccess && /* @__PURE__ */ jsx("ul", { className: "list", children: query.data.map((p) => /* @__PURE__ */ jsxs("li", { children: [
      /* @__PURE__ */ jsx(Link, { to: `/products/${p.id}`, children: p.name }),
      /* @__PURE__ */ jsxs("span", { className: "price", children: [
        p.price,
        " \u062C\u0646\u064A\u0647\u0627\u064B"
      ] })
    ] }, p.id)) })
  ] });
}
function Product() {
  const { id } = useParams();
  const query = useQuery({
    queryKey: ["product", Number(id)],
    queryFn: () => getProduct(Number(id)),
    retry: (count, error) => !(error instanceof NotFoundError) && count < 2
  });
  if (query.isPending) return /* @__PURE__ */ jsx(Skeleton, {});
  if (query.isError) {
    const missing = query.error instanceof NotFoundError;
    return /* @__PURE__ */ jsx("p", { className: "card error", children: missing ? "\u0644\u0627 \u064A\u0648\u062C\u062F \u0645\u0646\u062A\u062C \u0628\u0647\u0630\u0627 \u0627\u0644\u0631\u0642\u0645." : query.error.message });
  }
  const p = query.data;
  return /* @__PURE__ */ jsxs("article", { className: "card", children: [
    /* @__PURE__ */ jsx("h2", { children: p.name }),
    /* @__PURE__ */ jsx("p", { children: p.description }),
    /* @__PURE__ */ jsxs("p", { className: "price", children: [
      p.price,
      " \u062C\u0646\u064A\u0647\u0627\u064B"
    ] }),
    /* @__PURE__ */ jsx(Link, { to: "/products", children: "\u2192 \u0639\u0648\u062F\u0629 \u0625\u0644\u0649 \u0627\u0644\u0645\u0646\u062A\u062C\u0627\u062A" })
  ] });
}
function Skeleton() {
  return /* @__PURE__ */ jsxs("div", { "aria-busy": "true", "aria-label": "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0645\u064A\u0644\u2026", children: [
    /* @__PURE__ */ jsx("div", { className: "skeleton" }),
    /* @__PURE__ */ jsx("div", { className: "skeleton" })
  ] });
}
function ErrorPage() {
  const error = useRouteError();
  return /* @__PURE__ */ jsxs("p", { className: "card error", children: [
    "\u062D\u062F\u062B \u062E\u0637\u0623: ",
    String(error)
  ] });
}
function NotFound() {
  return /* @__PURE__ */ jsx("p", { className: "card", children: "\u0627\u0644\u0635\u0641\u062D\u0629 \u063A\u064A\u0631 \u0645\u0648\u062C\u0648\u062F\u0629" });
}
var CATEGORIES, routes;
var init_routes = __esm({
  "ar/routes.tsx"() {
    init_api();
    CATEGORIES = [
      { value: null, label: "\u0627\u0644\u0643\u0644" },
      { value: "books", label: "\u0643\u062A\u0628" },
      { value: "gifts", label: "\u0647\u062F\u0627\u064A\u0627" }
    ];
    routes = [
      {
        path: "/",
        element: /* @__PURE__ */ jsx(Layout, {}),
        errorElement: /* @__PURE__ */ jsx(ErrorPage, {}),
        children: [
          { index: true, element: /* @__PURE__ */ jsx(Home, {}) },
          { path: "products", element: /* @__PURE__ */ jsx(Products, {}) },
          { path: "products/:id", element: /* @__PURE__ */ jsx(Product, {}) },
          { path: "*", element: /* @__PURE__ */ jsx(NotFound, {}) }
        ]
      }
    ];
  }
});

// ar/page.tsx
import { createRoot } from "react-dom/client";
import { createMemoryRouter, RouterProvider } from "react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { jsx as jsx2 } from "react/jsx-runtime";
var require_page = __commonJS({
  "ar/page.tsx"() {
    init_routes();
    var router = createMemoryRouter(routes);
    var queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 3e4 } } });
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx2(QueryClientProvider, { client: queryClient, children: /* @__PURE__ */ jsx2(RouterProvider, { router }) })
    );
  }
});
export default require_page();
