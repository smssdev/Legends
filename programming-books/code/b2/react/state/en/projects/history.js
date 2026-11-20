var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/projects/history.tsx
import { useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_history = __commonJS({
  "en/projects/history.tsx"() {
    function StepCounter() {
      const [step, setStep] = useState(1);
      const [history, setHistory] = useState([0]);
      const value = history.at(-1) ?? 0;
      function change(by) {
        setHistory((h) => [...h, (h.at(-1) ?? 0) + by]);
      }
      function undo() {
        setHistory((h) => h.length > 1 ? h.slice(0, -1) : h);
      }
      return /* @__PURE__ */ jsxs("div", { className: "card", children: [
        /* @__PURE__ */ jsx("p", { className: "big", children: value }),
        /* @__PURE__ */ jsx("label", { htmlFor: "step", children: "Step" }),
        /* @__PURE__ */ jsx("input", { id: "step", type: "number", min: 1, value: step, onChange: (e) => setStep(Number(e.target.value) || 1) }),
        /* @__PURE__ */ jsxs("div", { className: "row", style: { marginTop: 10 }, children: [
          /* @__PURE__ */ jsxs("button", { onClick: () => change(-step), children: [
            "\u2212 ",
            step
          ] }),
          /* @__PURE__ */ jsxs("button", { onClick: () => change(step), children: [
            "+ ",
            step
          ] }),
          /* @__PURE__ */ jsx("button", { className: "secondary", onClick: undo, disabled: history.length === 1, children: "Undo" })
        ] }),
        /* @__PURE__ */ jsxs("p", { className: "muted", children: [
          "History: ",
          history.join(" \u2192 ")
        ] })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(StepCounter, {}));
  }
});
export default require_history();
