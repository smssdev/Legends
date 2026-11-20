var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/impure.tsx
import { renderToStaticMarkup } from "react-dom/server";
import { jsx, jsxs } from "react/jsx-runtime";
var require_impure = __commonJS({
  "en/impure.tsx"() {
    var visitors = 0;
    function Counter() {
      visitors = visitors + 1;
      return /* @__PURE__ */ jsxs("p", { children: [
        "Visitors so far: ",
        visitors
      ] });
    }
    console.log("First render:", renderToStaticMarkup(/* @__PURE__ */ jsx(Counter, {})));
    console.log("Second render:", renderToStaticMarkup(/* @__PURE__ */ jsx(Counter, {})));
  }
});
export default require_impure();
