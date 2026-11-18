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

// en/products.ts
var products;
var init_products = __esm({
  "en/products.ts"() {
    products = [
      { id: 1, name: "Code from Zero", price: 25, category: "books", isNew: true, inStock: true },
      { id: 2, name: "Bit mug", price: 8, category: "gifts", inStock: true },
      { id: 3, name: "Bit sticker", price: 3, category: "gifts", inStock: false },
      { id: 4, name: "Bit cap", price: 12, category: "gifts", isNew: true, inStock: true }
    ];
  }
});

// en/projects/catalogue.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_catalogue = __commonJS({
  "en/projects/catalogue.tsx"() {
    init_products();
    var FILTERS = [
      { value: "all", label: "All" },
      { value: "books", label: "Books" },
      { value: "gifts", label: "Gifts" }
    ];
    function ProductCard({ product }) {
      return /* @__PURE__ */ jsxs("article", { className: "card", children: [
        product.isNew && /* @__PURE__ */ jsx("span", { className: "badge", children: "New" }),
        /* @__PURE__ */ jsx("h3", { children: product.name }),
        /* @__PURE__ */ jsxs("p", { className: "price", children: [
          product.price.toFixed(2),
          " EGP"
        ] })
      ] });
    }
    function Catalogue() {
      const [filter, setFilter] = useState("all");
      const visible = filter === "all" ? products : products.filter((p) => p.category === filter);
      return /* @__PURE__ */ jsxs("section", { children: [
        /* @__PURE__ */ jsx("h2", { children: "Catalogue" }),
        /* @__PURE__ */ jsx("div", { className: "filters", role: "group", "aria-label": "Catalogue", children: FILTERS.map(({ value, label }) => /* @__PURE__ */ jsx(
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
          "Showing ",
          visible.length,
          " of ",
          products.length,
          " products"
        ] }),
        /* @__PURE__ */ jsx("div", { className: "grid", children: visible.map((product) => /* @__PURE__ */ jsx(ProductCard, { product }, product.id)) })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(Catalogue, {}));
  }
});
export default require_catalogue();
