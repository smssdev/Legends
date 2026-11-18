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
    throw new Error("\u0627\u0644\u062E\u0627\u062F\u0645 \u0645\u0634\u063A\u0648\u0644");
  }
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  product.favourite = favourite;
  return structuredClone(product);
}
var products, NotFoundError, wait, server;
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
    server = { failNextSave: false };
  }
});

// ar/projects/favourite.tsx
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
  if (!product.data) return /* @__PURE__ */ jsx("p", { className: "muted", children: "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0645\u064A\u0644\u2026" });
  const on = product.data.favourite;
  return /* @__PURE__ */ jsxs("div", { className: "card", children: [
    /* @__PURE__ */ jsx("h2", { children: product.data.name }),
    /* @__PURE__ */ jsx("button", { "aria-pressed": on, className: on ? "" : "secondary", onClick: () => mutation.mutate(!on), children: on ? "\u2665 \u0645\u0641\u0636\u0651\u0644" : "\u2661 \u0645\u0641\u0636\u0651\u0644" }),
    mutation.isPending && /* @__PURE__ */ jsx("span", { className: "muted", children: " \u062C\u0627\u0631\u064D \u0627\u0644\u062D\u0641\u0638\u2026" }),
    mutation.isError && /* @__PURE__ */ jsx("p", { className: "error", children: "\u062A\u0639\u0630\u0651\u0631 \u0627\u0644\u062D\u0641\u0638\u060C \u0648\u0623\u064F\u0644\u063A\u064A \u0627\u0644\u062A\u063A\u064A\u064A\u0631." })
  ] });
}
var init_favourite = __esm({
  "ar/projects/favourite.tsx"() {
    init_api();
  }
});

// ar/projects/fav-fail-page.tsx
import { createRoot } from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { jsx as jsx2 } from "react/jsx-runtime";
var require_fav_fail_page = __commonJS({
  "ar/projects/fav-fail-page.tsx"() {
    init_favourite();
    init_api();
    server.failNextSave = true;
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx2(QueryClientProvider, { client: new QueryClient(), children: /* @__PURE__ */ jsx2(FavouriteButton, { id: 2 }) })
    );
  }
});
export default require_fav_fail_page();
