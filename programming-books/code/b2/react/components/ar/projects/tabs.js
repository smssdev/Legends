var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/projects/tabs.tsx
import { useId, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_tabs = __commonJS({
  "ar/projects/tabs.tsx"() {
    function Tabs({ tabs, label }) {
      const [active, setActive] = useState(0);
      const id = useId();
      const buttons = useRef([]);
      function select(index) {
        const next = (index + tabs.length) % tabs.length;
        setActive(next);
        buttons.current[next]?.focus();
      }
      function onKeyDown(event) {
        const rtl = document.dir === "rtl";
        if (event.key === "ArrowRight") select(active + (rtl ? -1 : 1));
        if (event.key === "ArrowLeft") select(active + (rtl ? 1 : -1));
        if (event.key === "Home") select(0);
        if (event.key === "End") select(tabs.length - 1);
      }
      return /* @__PURE__ */ jsxs("div", { className: "tabs", children: [
        /* @__PURE__ */ jsx("div", { role: "tablist", "aria-label": label, onKeyDown, children: tabs.map((tab, i) => /* @__PURE__ */ jsx(
          "button",
          {
            ref: (el) => {
              buttons.current[i] = el;
            },
            role: "tab",
            id: `${id}-tab-${i}`,
            "aria-selected": i === active,
            "aria-controls": `${id}-panel-${i}`,
            tabIndex: i === active ? 0 : -1,
            onClick: () => select(i),
            children: tab.label
          },
          tab.label
        )) }),
        tabs.map((tab, i) => /* @__PURE__ */ jsx(
          "div",
          {
            role: "tabpanel",
            id: `${id}-panel-${i}`,
            "aria-labelledby": `${id}-tab-${i}`,
            hidden: i !== active,
            children: tab.content
          },
          tab.label
        ))
      ] });
    }
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx(
        Tabs,
        {
          label: "\u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0645\u0646\u062A\u062C",
          tabs: [
            { label: "\u0627\u0644\u0648\u0635\u0641", content: /* @__PURE__ */ jsx("p", { children: "\u062F\u0644\u064A\u0644 \u0648\u062F\u0648\u062F \u064A\u0623\u062E\u0630\u0643 \u0645\u0646 \u0623\u0648\u0644 \u0633\u0637\u0631 \u0643\u0648\u062F \u0625\u0644\u0649 \u0623\u0648\u0644 \u062A\u0637\u0628\u064A\u0642 \u0644\u0643." }) },
            { label: "\u0627\u0644\u0645\u0631\u0627\u062C\u0639\u0627\u062A", content: /* @__PURE__ */ jsx("p", { children: "\xAB\u0648\u0627\u0636\u062D \u0648\u0644\u0637\u064A\u0641 \u0648\u0639\u0645\u0644\u064A. \u0623\u0646\u0647\u0627\u0647 \u0627\u0628\u0646\u064A \u0641\u064A \u0634\u0647\u0631.\xBB \u2605\u2605\u2605\u2605\u2605" }) },
            { label: "\u0627\u0644\u0634\u062D\u0646", content: /* @__PURE__ */ jsx("p", { children: "\u062A\u0648\u0635\u064A\u0644 \u0645\u062C\u0627\u0646\u064A \u062F\u0627\u062E\u0644 \u0645\u0635\u0631 \u0644\u0644\u0637\u0644\u0628\u0627\u062A \u0641\u0648\u0642 50 \u062C\u0646\u064A\u0647\u0627\u064B. \u064A\u0635\u0644 \u062E\u0644\u0627\u0644 2 \u0625\u0644\u0649 4 \u0623\u064A\u0627\u0645." }) }
          ]
        }
      )
    );
  }
});
export default require_tabs();
