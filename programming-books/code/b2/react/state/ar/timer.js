var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/timer.tsx
import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_timer = __commonJS({
  "ar/timer.tsx"() {
    function Timer() {
      const [running, setRunning] = useState(false);
      const [seconds, setSeconds] = useState(0);
      useEffect(() => {
        if (!running) return;
        const id = setInterval(() => setSeconds((s) => s + 1), 1e3);
        return () => clearInterval(id);
      }, [running]);
      useEffect(() => {
        document.title = `${seconds} \u062B\u0627\u0646\u064A\u0629 \xB7 \u0627\u0644\u0645\u0624\u0642\u062A`;
      }, [seconds]);
      return /* @__PURE__ */ jsxs("div", { className: "card", children: [
        /* @__PURE__ */ jsxs("p", { className: "big", children: [
          seconds,
          " \u062B\u0627\u0646\u064A\u0629"
        ] }),
        /* @__PURE__ */ jsx("button", { onClick: () => setRunning(!running), children: running ? "\u0623\u0648\u0642\u0641" : "\u0627\u0628\u062F\u0623" })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(Timer, {}));
  }
});
export default require_timer();
