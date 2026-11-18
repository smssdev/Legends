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
var catalogue, FREE_DELIVERY;
var init_cart_model = __esm({
  "ar/cart-model.ts"() {
    catalogue = [
      { id: 1, name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", price: 25 },
      { id: 2, name: "\u0643\u0648\u0628 \u0628\u0650\u062A", price: 8 },
      { id: 3, name: "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A", price: 12 }
    ];
    FREE_DELIVERY = 50;
  }
});

// ar/cart.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_cart = __commonJS({
  "ar/cart.tsx"() {
    init_cart_model();
    function Cart() {
      const [lines, setLines] = useState([]);
      const count = lines.reduce((sum, line) => sum + line.quantity, 0);
      const total = lines.reduce((sum, line) => sum + line.quantity * line.product.price, 0);
      const missing = FREE_DELIVERY - total;
      function add(product) {
        setLines((current) => {
          const found = current.find((line) => line.product.id === product.id);
          if (!found) return [...current, { product, quantity: 1 }];
          return current.map((line) => line === found ? { ...line, quantity: line.quantity + 1 } : line);
        });
      }
      function remove(id) {
        setLines((current) => current.filter((line) => line.product.id !== id));
      }
      return /* @__PURE__ */ jsxs("div", { className: "card", children: [
        /* @__PURE__ */ jsx("div", { className: "row", children: catalogue.map((product) => /* @__PURE__ */ jsxs("button", { className: "secondary", onClick: () => add(product), children: [
          "+ ",
          product.name
        ] }, product.id)) }),
        lines.length === 0 ? /* @__PURE__ */ jsx("p", { className: "muted", children: "\u0633\u0644\u062A\u0643 \u0641\u0627\u0631\u063A\u0629." }) : /* @__PURE__ */ jsx("ul", { children: lines.map((line) => /* @__PURE__ */ jsxs("li", { children: [
          /* @__PURE__ */ jsxs("span", { children: [
            line.quantity,
            " \xD7 ",
            line.product.name
          ] }),
          /* @__PURE__ */ jsx("button", { className: "secondary", onClick: () => remove(line.product.id), children: "\u0627\u062D\u0630\u0641" })
        ] }, line.product.id)) }),
        /* @__PURE__ */ jsxs("p", { children: [
          "\u0627\u0644\u0639\u0646\u0627\u0635\u0631: ",
          count,
          " \xB7 \u0627\u0644\u0645\u062C\u0645\u0648\u0639: ",
          /* @__PURE__ */ jsxs("b", { children: [
            total,
            " \u062C\u0646\u064A\u0647\u0627\u064B"
          ] })
        ] }),
        /* @__PURE__ */ jsx("p", { className: missing <= 0 ? "ok" : "muted", children: missing <= 0 ? "\u062A\u0648\u0635\u064A\u0644 \u0645\u062C\u0627\u0646\u064A!" : `${missing} \u062C\u0646\u064A\u0647\u0627\u064B \u0623\u062E\u0631\u0649 \u0644\u0644\u062A\u0648\u0635\u064A\u0644 \u0627\u0644\u0645\u062C\u0627\u0646\u064A` })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(Cart, {}));
  }
});
export default require_cart();
