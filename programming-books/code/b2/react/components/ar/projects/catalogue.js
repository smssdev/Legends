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

// ar/products.ts
var products;
var init_products = __esm({
  "ar/products.ts"() {
    products = [
      { id: 1, name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", price: 25, category: "books", isNew: true, inStock: true },
      { id: 2, name: "\u0643\u0648\u0628 \u0628\u0650\u062A", price: 8, category: "gifts", inStock: true },
      { id: 3, name: "\u0645\u0644\u0635\u0642 \u0628\u0650\u062A", price: 3, category: "gifts", inStock: false },
      { id: 4, name: "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A", price: 12, category: "gifts", isNew: true, inStock: true }
    ];
  }
});

// ar/projects/catalogue.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_catalogue = __commonJS({
  "ar/projects/catalogue.tsx"() {
    init_products();
    var FILTERS = [
      { value: "all", label: "\u0627\u0644\u0643\u0644" },
      { value: "books", label: "\u0643\u062A\u0628" },
      { value: "gifts", label: "\u0647\u062F\u0627\u064A\u0627" }
    ];
    function ProductCard({ product }) {
      return /* @__PURE__ */ jsxs("article", { className: "card", children: [
        product.isNew && /* @__PURE__ */ jsx("span", { className: "badge", children: "\u062C\u062F\u064A\u062F" }),
        /* @__PURE__ */ jsx("h3", { children: product.name }),
        /* @__PURE__ */ jsxs("p", { className: "price", children: [
          product.price.toFixed(2),
          " \u062C\u0646\u064A\u0647\u0627\u064B"
        ] })
      ] });
    }
    function Catalogue() {
      const [filter, setFilter] = useState("all");
      const visible = filter === "all" ? products : products.filter((p) => p.category === filter);
      return /* @__PURE__ */ jsxs("section", { children: [
        /* @__PURE__ */ jsx("h2", { children: "\u0627\u0644\u0643\u062A\u0627\u0644\u0648\u062C" }),
        /* @__PURE__ */ jsx("div", { className: "filters", role: "group", "aria-label": "\u0627\u0644\u0643\u062A\u0627\u0644\u0648\u062C", children: FILTERS.map(({ value, label }) => /* @__PURE__ */ jsx(
          "button",
          {
            className: value === filter ? "" : "secondary",
            "aria-pressed": value === filter,
            onClick: () => setFilter(value),
            children: label
          },
          value
        )) }),
        /* @__PURE__ */ jsxs("p", { className: "count", children: [
          "\u064A\u0638\u0647\u0631 ",
          visible.length,
          " \u0645\u0646 ",
          products.length,
          " \u0645\u0646\u062A\u062C\u0627\u062A"
        ] }),
        /* @__PURE__ */ jsx("div", { className: "grid", children: visible.map((product) => /* @__PURE__ */ jsx(ProductCard, { product }, product.id)) })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(Catalogue, {}));
  }
});
export default require_catalogue();
