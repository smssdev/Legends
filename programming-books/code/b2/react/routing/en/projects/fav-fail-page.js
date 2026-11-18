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
async function getProduct(id) {
  await wait(300);
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  return structuredClone(product);
}
async function setFavourite(id, favourite) {
  await wait(400);
  if (server.failNextSave) {
    server.failNextSave = false;
    throw new Error("The server is busy");
  }
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  product.favourite = favourite;
  return structuredClone(product);
}
var products, NotFoundError, wait, server;
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
    server = { failNextSave: false };
  }
});

// en/projects/favourite.tsx
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { jsx, jsxs } from "react/jsx-runtime";
function FavouriteButton({ id }) {
  const client = useQueryClient();
  const key = ["product", id];
  const product = useQuery({ queryKey: key, queryFn: () => getProduct(id) });
  const mutation = useMutation({
    mutationFn: (favourite) => setFavourite(id, favourite),
    // 1. Before the server answers: change the cache, and remember the old value
    onMutate: async (favourite) => {
      await client.cancelQueries({ queryKey: key });
      const previous = client.getQueryData(key);
      client.setQueryData(key, (old) => old ? { ...old, favourite } : old);
      return { previous };
    },
    // 2. If it fails: put the old value back
    onError: (_error, _favourite, context) => {
      client.setQueryData(key, context?.previous);
    },
    // 3. Either way: ask the server for the truth
    onSettled: () => client.invalidateQueries({ queryKey: key })
  });
  if (!product.data) return /* @__PURE__ */ jsx("p", { className: "muted", children: "Loading\u2026" });
  const on = product.data.favourite;
  return /* @__PURE__ */ jsxs("div", { className: "card", children: [
    /* @__PURE__ */ jsx("h2", { children: product.data.name }),
    /* @__PURE__ */ jsx("button", { "aria-pressed": on, className: on ? "" : "secondary", onClick: () => mutation.mutate(!on), children: on ? "\u2665 Favourite" : "\u2661 Favourite" }),
    mutation.isPending && /* @__PURE__ */ jsx("span", { className: "muted", children: " Saving\u2026" }),
    mutation.isError && /* @__PURE__ */ jsx("p", { className: "error", children: "Could not save. The change was undone." })
  ] });
}
var init_favourite = __esm({
  "en/projects/favourite.tsx"() {
    init_api();
  }
});

// en/projects/fav-fail-page.tsx
import { createRoot } from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { jsx as jsx2 } from "react/jsx-runtime";
var require_fav_fail_page = __commonJS({
  "en/projects/fav-fail-page.tsx"() {
    init_favourite();
    init_api();
    server.failNextSave = true;
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx2(QueryClientProvider, { client: new QueryClient(), children: /* @__PURE__ */ jsx2(FavouriteButton, { id: 2 }) })
    );
  }
});
export default require_fav_fail_page();
