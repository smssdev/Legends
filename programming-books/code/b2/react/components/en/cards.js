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

// en/cards.tsx
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_cards = __commonJS({
  "en/cards.tsx"() {
    init_products();
    function ProductCard({ product, onAdd }) {
      return /* @__PURE__ */ jsxs("article", { className: "card", children: [
        product.isNew && /* @__PURE__ */ jsx("span", { className: "badge", children: "New" }),
        /* @__PURE__ */ jsx("h3", { children: product.name }),
        /* @__PURE__ */ jsxs("p", { className: "price", children: [
          product.price.toFixed(2),
          " EGP"
        ] }),
        /* @__PURE__ */ jsx("button", { disabled: !product.inStock, onClick: () => onAdd?.(product.id), children: product.inStock ? "Add to cart" : "Sold out" })
      ] });
    }
    function Section({ title, children }) {
      return /* @__PURE__ */ jsxs("section", { children: [
        /* @__PURE__ */ jsx("h2", { children: title }),
        children
      ] });
    }
    function App() {
      return /* @__PURE__ */ jsx(Section, { title: "Bit's shop", children: /* @__PURE__ */ jsx("div", { className: "grid", children: products.map((product) => /* @__PURE__ */ jsx(ProductCard, { product }, product.id)) }) });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(App, {}));
  }
});
export default require_cards();
