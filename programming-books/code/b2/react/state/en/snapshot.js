var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/snapshot.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_snapshot = __commonJS({
  "en/snapshot.tsx"() {
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
          /* @__PURE__ */ jsx("button", { onClick: addThreeWrong, children: "+3 (wrong)" }),
          /* @__PURE__ */ jsx("button", { onClick: addThree, children: "+3 (right)" }),
          /* @__PURE__ */ jsx("button", { className: "secondary", onClick: () => setCount(0), children: "Reset" })
        ] })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(Counter, {}));
  }
});
export default require_snapshot();
