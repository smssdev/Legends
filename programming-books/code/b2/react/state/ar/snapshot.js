var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/snapshot.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_snapshot = __commonJS({
  "ar/snapshot.tsx"() {
    function Counter() {
      const [count, setCount] = useState(0);
      function addThreeWrong() {
        setCount(count + 1);
        setCount(count + 1);
        setCount(count + 1);
      }
      function addThree() {
        setCount((c) => c + 1);
        setCount((c) => c + 1);
        setCount((c) => c + 1);
      }
      return /* @__PURE__ */ jsxs("div", { className: "card", children: [
        /* @__PURE__ */ jsx("p", { className: "big", children: count }),
        /* @__PURE__ */ jsxs("div", { className: "row", children: [
          /* @__PURE__ */ jsx("button", { onClick: addThreeWrong, children: "\u200E+3 (\u062E\u0637\u0623)" }),
          /* @__PURE__ */ jsx("button", { onClick: addThree, children: "\u200E+3 (\u0635\u062D\u064A\u062D)" }),
          /* @__PURE__ */ jsx("button", { className: "secondary", onClick: () => setCount(0), children: "\u0635\u0641\u0651\u0631" })
        ] })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(Counter, {}));
  }
});
export default require_snapshot();
