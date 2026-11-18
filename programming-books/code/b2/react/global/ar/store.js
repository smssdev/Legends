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

// ar/cart-store.ts
import { create } from "zustand";
import { persist } from "zustand/middleware";
var useCart, selectCount, selectTotal;
var init_cart_store = __esm({
  "ar/cart-store.ts"() {
    useCart = create()(
      // persist يحفظ المخزن في localStorage ويحمّله في الزيارة التالية
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

// ar/store.tsx
import { createRoot } from "react-dom/client";
import { Fragment, jsx, jsxs } from "react/jsx-runtime";
var require_store = __commonJS({
  "ar/store.tsx"() {
    init_cart_store();
    var products = [
      { id: 1, name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", price: 25 },
      { id: 2, name: "\u0643\u0648\u0628 \u0628\u0650\u062A", price: 8 },
      { id: 3, name: "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A", price: 12 }
    ];
    function CartBadge() {
      const count = useCart(selectCount);
      return /* @__PURE__ */ jsxs("span", { className: "row", children: [
        "\u0627\u0644\u0633\u0644\u0629 ",
        /* @__PURE__ */ jsx("span", { className: "badge", children: count })
      ] });
    }
    function ProductList() {
      const add = useCart((s) => s.add);
      return /* @__PURE__ */ jsx("section", { className: "card", children: products.map((p) => /* @__PURE__ */ jsxs("div", { className: "row", style: { justifyContent: "space-between", padding: "4px 0" }, children: [
        /* @__PURE__ */ jsx("span", { children: p.name }),
        /* @__PURE__ */ jsx("button", { onClick: () => add(p), children: "\u0623\u0636\u0641" })
      ] }, p.id)) });
    }
    function CartSummary() {
      const lines = useCart((s) => s.lines);
      const total = useCart(selectTotal);
      const clear = useCart((s) => s.clear);
      const list = Object.values(lines);
      if (list.length === 0) return /* @__PURE__ */ jsx("p", { className: "card muted", children: "\u0627\u0644\u0633\u0644\u0629 \u0641\u0627\u0631\u063A\u0629." });
      return /* @__PURE__ */ jsxs("section", { className: "card", children: [
        /* @__PURE__ */ jsx("ul", { children: list.map((l) => /* @__PURE__ */ jsxs("li", { children: [
          /* @__PURE__ */ jsxs("span", { children: [
            l.quantity,
            " \xD7 ",
            l.product.name
          ] }),
          /* @__PURE__ */ jsxs("span", { children: [
            l.quantity * l.product.price,
            " \u062C\u0646\u064A\u0647\u0627\u064B"
          ] })
        ] }, l.product.id)) }),
        /* @__PURE__ */ jsx("p", { children: /* @__PURE__ */ jsxs("b", { children: [
          "\u0627\u0644\u0645\u062C\u0645\u0648\u0639: ",
          total,
          " \u062C\u0646\u064A\u0647\u0627\u064B"
        ] }) }),
        /* @__PURE__ */ jsx("button", { className: "secondary", onClick: clear, children: "\u0623\u0641\u0631\u063A \u0627\u0644\u0633\u0644\u0629" })
      ] });
    }
    localStorage.clear();
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsxs(Fragment, { children: [
        /* @__PURE__ */ jsxs("header", { children: [
          /* @__PURE__ */ jsx("span", { className: "brand", children: "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A" }),
          /* @__PURE__ */ jsx(CartBadge, {})
        ] }),
        /* @__PURE__ */ jsx(ProductList, {}),
        /* @__PURE__ */ jsx(CartSummary, {})
      ] })
    );
  }
});
export default require_store();
