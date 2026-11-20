var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/timer.tsx
import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_timer = __commonJS({
  "en/timer.tsx"() {
    function Timer() {
      const [running, setRunning] = useState(false);
      const [seconds, setSeconds] = useState(0);
      useEffect(() => {
        if (!running) return;
        const id = setInterval(() => setSeconds((s) => s + 1), 1e3);
        return () => clearInterval(id);
      }, [running]);
      useEffect(() => {
        document.title = `${seconds} seconds \xB7 Timer`;
      }, [seconds]);
      return /* @__PURE__ */ jsxs("div", { className: "card", children: [
        /* @__PURE__ */ jsxs("p", { className: "big", children: [
          seconds,
          " seconds"
        ] }),
        /* @__PURE__ */ jsx("button", { onClick: () => setRunning(!running), children: running ? "Stop" : "Start" })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(Timer, {}));
  }
});
export default require_timer();
