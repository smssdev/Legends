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

// en/api.ts
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
  "en/api.ts"() {
    products = [
      { id: 1, name: "Code from Zero", description: "The friendly first book of the series.", price: 25, category: "books", favourite: false },
      { id: 2, name: "Bit mug", description: "A big mug for long coding nights.", price: 8, category: "gifts", favourite: false },
      { id: 3, name: "Bit cap", description: "Keeps the sun out of your eyes.", price: 12, category: "gifts", favourite: true },
      { id: 4, name: "Bit sticker", description: "For your laptop.", price: 3, category: "gifts", favourite: false }
    ];
    NotFoundError = class extends Error {
    };
    wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  }
});

// en/routes.tsx
import { Link, NavLink, Outlet, useParams, useRouteError, useSearchParams } from "react-router";
import { useQuery } from "@tanstack/react-query";
import { jsx, jsxs } from "react/jsx-runtime";
function Layout() {
  return /* @__PURE__ */ jsxs("div", { className: "layout", children: [
    /* @__PURE__ */ jsxs("nav", { children: [
      /* @__PURE__ */ jsx("span", { className: "brand", children: "Bit's shop" }),
      /* @__PURE__ */ jsx(NavLink, { to: "/", end: true, children: "Home" }),
      /* @__PURE__ */ jsx(NavLink, { to: "/products", children: "Products" })
    ] }),
    /* @__PURE__ */ jsx(Outlet, {})
  ] });
}
function Home() {
  return /* @__PURE__ */ jsx("p", { className: "card", children: "Welcome! Browse the products, or search for something." });
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
      "Something went wrong: ",
      query.error.message
    ] }),
    query.isSuccess && /* @__PURE__ */ jsx("ul", { className: "list", children: query.data.map((p) => /* @__PURE__ */ jsxs("li", { children: [
      /* @__PURE__ */ jsx(Link, { to: `/products/${p.id}`, children: p.name }),
      /* @__PURE__ */ jsxs("span", { className: "price", children: [
        p.price,
        " EGP"
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
    return /* @__PURE__ */ jsx("p", { className: "card error", children: missing ? "There is no product with this number." : query.error.message });
  }
  const p = query.data;
  return /* @__PURE__ */ jsxs("article", { className: "card", children: [
    /* @__PURE__ */ jsx("h2", { children: p.name }),
    /* @__PURE__ */ jsx("p", { children: p.description }),
    /* @__PURE__ */ jsxs("p", { className: "price", children: [
      p.price,
      " EGP"
    ] }),
    /* @__PURE__ */ jsx(Link, { to: "/products", children: "\u2190 Back to products" })
  ] });
}
function Skeleton() {
  return /* @__PURE__ */ jsxs("div", { "aria-busy": "true", "aria-label": "Loading\u2026", children: [
    /* @__PURE__ */ jsx("div", { className: "skeleton" }),
    /* @__PURE__ */ jsx("div", { className: "skeleton" })
  ] });
}
function ErrorPage() {
  const error = useRouteError();
  return /* @__PURE__ */ jsxs("p", { className: "card error", children: [
    "Something went wrong: ",
    String(error)
  ] });
}
function NotFound() {
  return /* @__PURE__ */ jsx("p", { className: "card", children: "Page not found" });
}
var CATEGORIES, routes;
var init_routes = __esm({
  "en/routes.tsx"() {
    init_api();
    CATEGORIES = [
      { value: null, label: "All" },
      { value: "books", label: "Books" },
      { value: "gifts", label: "Gifts" }
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

// en/page.tsx
import { createRoot } from "react-dom/client";
import { createMemoryRouter, RouterProvider } from "react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { jsx as jsx2 } from "react/jsx-runtime";
var require_page = __commonJS({
  "en/page.tsx"() {
    init_routes();
    var router = createMemoryRouter(routes);
    var queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 3e4 } } });
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx2(QueryClientProvider, { client: queryClient, children: /* @__PURE__ */ jsx2(RouterProvider, { router }) })
    );
  }
});
export default require_page();
