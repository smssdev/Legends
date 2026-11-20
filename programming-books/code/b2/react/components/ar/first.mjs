var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/first.tsx
import { renderToStaticMarkup } from "react-dom/server";
import { jsx } from "react/jsx-runtime";
var require_first = __commonJS({
  "ar/first.tsx"() {
    function Greeting() {
      return /* @__PURE__ */ jsx("h1", { children: "\u0623\u0647\u0644\u0627\u064B \u064A\u0627 \u0633\u0627\u0631\u0629!" });
    }
    console.log(renderToStaticMarkup(/* @__PURE__ */ jsx(Greeting, {})));
  }
});
export default require_first();
