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

// en/cart-model.ts
var catalogue, FREE_DELIVERY;
var init_cart_model = __esm({
  "en/cart-model.ts"() {
    catalogue = [
      { id: 1, name: "Code from Zero", price: 25 },
      { id: 2, name: "Bit mug", price: 8 },
      { id: 3, name: "Bit cap", price: 12 }
    ];
    FREE_DELIVERY = 50;
  }
});

// en/cart.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_cart = __commonJS({
  "en/cart.tsx"() {
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
        lines.length === 0 ? /* @__PURE__ */ jsx("p", { className: "muted", children: "Your cart is empty." }) : /* @__PURE__ */ jsx("ul", { children: lines.map((line) => /* @__PURE__ */ jsxs("li", { children: [
          /* @__PURE__ */ jsxs("span", { children: [
            line.quantity,
            " \xD7 ",
            line.product.name
          ] }),
          /* @__PURE__ */ jsx("button", { className: "secondary", onClick: () => remove(line.product.id), children: "Remove" })
        ] }, line.product.id)) }),
        /* @__PURE__ */ jsxs("p", { children: [
          "Items: ",
          count,
          " \xB7 Total: ",
          /* @__PURE__ */ jsxs("b", { children: [
            total,
            " EGP"
          ] })
        ] }),
        /* @__PURE__ */ jsx("p", { className: missing <= 0 ? "ok" : "muted", children: missing <= 0 ? "Free delivery!" : `${missing} EGP more for free delivery` })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(Cart, {}));
  }
});
export default require_cart();
