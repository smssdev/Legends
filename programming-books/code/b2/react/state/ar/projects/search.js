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

// ar/cart-model.ts
var catalogue;
var init_cart_model = __esm({
  "ar/cart-model.ts"() {
    catalogue = [
      { id: 1, name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", price: 25 },
      { id: 2, name: "\u0643\u0648\u0628 \u0628\u0650\u062A", price: 8 },
      { id: 3, name: "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A", price: 12 }
    ];
  }
});

// ar/fake-api.ts
function searchProducts(query, signal) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      const q = query.trim().toLowerCase();
      resolve(catalogue.filter((p) => p.name.toLowerCase().includes(q)));
    }, 600 - query.length * 100);
    signal.addEventListener("abort", () => {
      clearTimeout(timer);
      reject(signal.reason);
    });
  });
}
var init_fake_api = __esm({
  "ar/fake-api.ts"() {
    init_cart_model();
  }
});

// ar/projects/search.tsx
import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_search = __commonJS({
  "ar/projects/search.tsx"() {
    init_fake_api();
    function useDebounced(value, ms) {
      const [debounced, setDebounced] = useState(value);
      useEffect(() => {
        const id = setTimeout(() => setDebounced(value), ms);
        return () => clearTimeout(id);
      }, [value, ms]);
      return debounced;
    }
    function Search() {
      const [query, setQuery] = useState("");
      const [result, setResult] = useState({ status: "idle" });
      const debounced = useDebounced(query, 300);
      useEffect(() => {
        if (!debounced.trim()) {
          setResult({ status: "idle" });
          return;
        }
        const controller = new AbortController();
        setResult({ status: "loading", query: debounced });
        searchProducts(debounced, controller.signal).then((products) => setResult({ status: "done", query: debounced, products })).catch((error) => {
          if (controller.signal.aborted) return;
          setResult({ status: "error", message: String(error) });
        });
        return () => controller.abort();
      }, [debounced]);
      return /* @__PURE__ */ jsxs("div", { className: "card", children: [
        /* @__PURE__ */ jsx("label", { htmlFor: "q", children: "\u0627\u0628\u062D\u062B \u0641\u064A \u0627\u0644\u0645\u0646\u062A\u062C\u0627\u062A" }),
        /* @__PURE__ */ jsx("input", { id: "q", type: "search", value: query, onChange: (e) => setQuery(e.target.value) }),
        result.status === "loading" && /* @__PURE__ */ jsxs("p", { className: "muted", children: [
          "\u062C\u0627\u0631\u064D \u0627\u0644\u0628\u062D\u062B \u0639\u0646 \u201C",
          result.query,
          "\u201D\u2026"
        ] }),
        result.status === "error" && /* @__PURE__ */ jsx("p", { role: "alert", children: result.message }),
        result.status === "done" && (result.products.length === 0 ? /* @__PURE__ */ jsxs("p", { className: "muted", children: [
          "\u0644\u0627 \u0645\u0646\u062A\u062C\u0627\u062A \u062A\u0637\u0627\u0628\u0642 \u201C",
          result.query,
          "\u201D."
        ] }) : /* @__PURE__ */ jsx("ul", { "aria-label": "\u0646\u062A\u0627\u0626\u062C", children: result.products.map((p) => /* @__PURE__ */ jsxs("li", { children: [
          /* @__PURE__ */ jsx("span", { children: p.name }),
          /* @__PURE__ */ jsxs("b", { children: [
            p.price,
            " \u062C\u0646\u064A\u0647\u0627\u064B"
          ] })
        ] }, p.id)) }))
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(Search, {}));
  }
});
export default require_search();
