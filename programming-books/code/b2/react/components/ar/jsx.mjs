var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/jsx.tsx
import { renderToStaticMarkup } from "react-dom/server";
import { Fragment, jsx, jsxs } from "react/jsx-runtime";
var require_jsx = __commonJS({
  "ar/jsx.tsx"() {
    function CartSummary({ count, total }) {
      const isEmpty = count === 0;
      return /* @__PURE__ */ jsxs(Fragment, { children: [
        /* @__PURE__ */ jsxs("p", { className: "summary", children: [
          count,
          " \u0639\u0646\u0627\u0635\u0631 \u0641\u064A \u0633\u0644\u062A\u0643: ",
          total.toFixed(2),
          " \u062C\u0646\u064A\u0647\u0627\u064B"
        ] }),
        /* @__PURE__ */ jsx("button", { disabled: isEmpty, style: { fontWeight: 700 }, children: "\u0623\u0636\u0641 \u0625\u0644\u0649 \u0627\u0644\u0633\u0644\u0629" })
      ] });
    }
    console.log(renderToStaticMarkup(/* @__PURE__ */ jsx(CartSummary, { count: 3, total: 41 })));
  }
});
export default require_jsx();
