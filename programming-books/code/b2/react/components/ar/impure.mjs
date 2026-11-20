var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/impure.tsx
import { renderToStaticMarkup } from "react-dom/server";
import { jsx, jsxs } from "react/jsx-runtime";
var require_impure = __commonJS({
  "ar/impure.tsx"() {
    var visitors = 0;
    function Counter() {
      visitors = visitors + 1;
      return /* @__PURE__ */ jsxs("p", { children: [
        "\u0627\u0644\u0632\u0648\u0627\u0631 \u062D\u062A\u0649 \u0627\u0644\u0622\u0646: ",
        visitors
      ] });
    }
    console.log("\u0627\u0644\u0631\u0633\u0645 \u0627\u0644\u0623\u0648\u0644:", renderToStaticMarkup(/* @__PURE__ */ jsx(Counter, {})));
    console.log("\u0627\u0644\u0631\u0633\u0645 \u0627\u0644\u062B\u0627\u0646\u064A:", renderToStaticMarkup(/* @__PURE__ */ jsx(Counter, {})));
  }
});
export default require_impure();
