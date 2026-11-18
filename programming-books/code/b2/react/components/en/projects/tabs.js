var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/projects/tabs.tsx
import { useId, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_tabs = __commonJS({
  "en/projects/tabs.tsx"() {
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
          label: "Product details",
          tabs: [
            { label: "Description", content: /* @__PURE__ */ jsx("p", { children: "A friendly guide that takes you from your first line of code to your first app." }) },
            { label: "Reviews", content: /* @__PURE__ */ jsx("p", { children: "\u201CClear, kind and practical. My son finished it in a month.\u201D \u2605\u2605\u2605\u2605\u2605" }) },
            { label: "Shipping", content: /* @__PURE__ */ jsx("p", { children: "Free delivery in Egypt for orders over 50 EGP. Arrives in 2\u20134 days." }) }
          ]
        }
      )
    );
  }
});
export default require_tabs();
