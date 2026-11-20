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

// ar/cards.tsx
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_cards = __commonJS({
  "ar/cards.tsx"() {
    init_products();
    function ProductCard({ product, onAdd }) {
      return /* @__PURE__ */ jsxs("article", { className: "card", children: [
        product.isNew && /* @__PURE__ */ jsx("span", { className: "badge", children: "\u062C\u062F\u064A\u062F" }),
        /* @__PURE__ */ jsx("h3", { children: product.name }),
        /* @__PURE__ */ jsxs("p", { className: "price", children: [
          product.price.toFixed(2),
          " \u062C\u0646\u064A\u0647\u0627\u064B"
        ] }),
        /* @__PURE__ */ jsx("button", { disabled: !product.inStock, onClick: () => onAdd?.(product.id), children: product.inStock ? "\u0623\u0636\u0641 \u0625\u0644\u0649 \u0627\u0644\u0633\u0644\u0629" : "\u0646\u0641\u062F\u062A \u0627\u0644\u0643\u0645\u064A\u0629" })
      ] });
    }
    function Section({ title, children }) {
      return /* @__PURE__ */ jsxs("section", { children: [
        /* @__PURE__ */ jsx("h2", { children: title }),
        children
      ] });
    }
    function App() {
      return /* @__PURE__ */ jsx(Section, { title: "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A", children: /* @__PURE__ */ jsx("div", { className: "grid", children: products.map((product) => /* @__PURE__ */ jsx(ProductCard, { product }, product.id)) }) });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(App, {}));
  }
});
export default require_cards();
