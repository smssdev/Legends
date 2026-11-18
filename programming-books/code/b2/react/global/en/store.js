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

// en/cart-store.ts
import { create } from "zustand";
import { persist } from "zustand/middleware";
var useCart, selectCount, selectTotal;
var init_cart_store = __esm({
  "en/cart-store.ts"() {
    useCart = create()(
      // persist saves the store in localStorage and loads it on the next visit
      persist(
        (set) => ({
          lines: {},
          add: (product) => set((state) => {
            const line = state.lines[product.id];
            return { lines: { ...state.lines, [product.id]: { product, quantity: (line?.quantity ?? 0) + 1 } } };
          }),
          clear: () => set({ lines: {} })
        }),
        { name: "cart" }
      )
    );
    selectCount = (s) => Object.values(s.lines).reduce((n, l) => n + l.quantity, 0);
    selectTotal = (s) => Object.values(s.lines).reduce((n, l) => n + l.quantity * l.product.price, 0);
  }
});

// en/store.tsx
import { createRoot } from "react-dom/client";
import { Fragment, jsx, jsxs } from "react/jsx-runtime";
var require_store = __commonJS({
  "en/store.tsx"() {
    init_cart_store();
    var products = [
      { id: 1, name: "Code from Zero", price: 25 },
      { id: 2, name: "Bit mug", price: 8 },
      { id: 3, name: "Bit cap", price: 12 }
    ];
    function CartBadge() {
      const count = useCart(selectCount);
      return /* @__PURE__ */ jsxs("span", { className: "row", children: [
        "Cart ",
        /* @__PURE__ */ jsx("span", { className: "badge", children: count })
      ] });
    }
    function ProductList() {
      const add = useCart((s) => s.add);
      return /* @__PURE__ */ jsx("section", { className: "card", children: products.map((p) => /* @__PURE__ */ jsxs("div", { className: "row", style: { justifyContent: "space-between", padding: "4px 0" }, children: [
        /* @__PURE__ */ jsx("span", { children: p.name }),
        /* @__PURE__ */ jsx("button", { onClick: () => add(p), children: "Add" })
      ] }, p.id)) });
    }
    function CartSummary() {
      const lines = useCart((s) => s.lines);
      const total = useCart(selectTotal);
      const clear = useCart((s) => s.clear);
      const list = Object.values(lines);
      if (list.length === 0) return /* @__PURE__ */ jsx("p", { className: "card muted", children: "The cart is empty." });
      return /* @__PURE__ */ jsxs("section", { className: "card", children: [
        /* @__PURE__ */ jsx("ul", { children: list.map((l) => /* @__PURE__ */ jsxs("li", { children: [
          /* @__PURE__ */ jsxs("span", { children: [
            l.quantity,
            " \xD7 ",
            l.product.name
          ] }),
          /* @__PURE__ */ jsxs("span", { children: [
            l.quantity * l.product.price,
            " EGP"
          ] })
        ] }, l.product.id)) }),
        /* @__PURE__ */ jsx("p", { children: /* @__PURE__ */ jsxs("b", { children: [
          "Total: ",
          total,
          " EGP"
        ] }) }),
        /* @__PURE__ */ jsx("button", { className: "secondary", onClick: clear, children: "Empty the cart" })
      ] });
    }
    localStorage.clear();
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsxs(Fragment, { children: [
        /* @__PURE__ */ jsxs("header", { children: [
          /* @__PURE__ */ jsx("span", { className: "brand", children: "Bit's shop" }),
          /* @__PURE__ */ jsx(CartBadge, {})
        ] }),
        /* @__PURE__ */ jsx(ProductList, {}),
        /* @__PURE__ */ jsx(CartSummary, {})
      ] })
    );
  }
});
export default require_store();
