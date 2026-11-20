var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/first.tsx
import { renderToStaticMarkup } from "react-dom/server";
import { jsx } from "react/jsx-runtime";
var require_first = __commonJS({
  "en/first.tsx"() {
    function Greeting() {
      return /* @__PURE__ */ jsx("h1", { children: "Hello, Sara!" });
    }
    console.log(renderToStaticMarkup(/* @__PURE__ */ jsx(Greeting, {})));
  }
});
export default require_first();
