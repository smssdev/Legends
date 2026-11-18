var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/jsx.tsx
import { renderToStaticMarkup } from "react-dom/server";
import { Fragment, jsx, jsxs } from "react/jsx-runtime";
var require_jsx = __commonJS({
  "en/jsx.tsx"() {
    function CartSummary({ count, total }) {
      const isEmpty = count === 0;
      return /* @__PURE__ */ jsxs(Fragment, { children: [
        /* @__PURE__ */ jsxs("p", { className: "summary", children: [
          count,
          " items in your cart: ",
          total.toFixed(2),
          " EGP"
        ] }),
        /* @__PURE__ */ jsx("button", { disabled: isEmpty, style: { fontWeight: 700 }, children: "Add to cart" })
      ] });
    }
    console.log(renderToStaticMarkup(/* @__PURE__ */ jsx(CartSummary, { count: 3, total: 41 })));
  }
});
export default require_jsx();
