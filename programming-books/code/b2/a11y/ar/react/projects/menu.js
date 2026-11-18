// ar/react/projects/menu.tsx
import { createRoot } from "react-dom/client";

// ar/react/projects/MenuButton.tsx
import { useEffect, useId, useRef, useState } from "react";
import { jsx, jsxs } from "react/jsx-runtime";
function MenuButton({ label, items }) {
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const id = useId();
  const button = useRef(null);
  const itemRefs = useRef([]);
  useEffect(() => {
    if (open) itemRefs.current[active]?.focus();
  }, [open, active]);
  function openAt(index) {
    setActive(index);
    setOpen(true);
  }
  function close() {
    setOpen(false);
    button.current?.focus();
  }
  function onButtonKey(event) {
    if (event.key === "ArrowDown") event.preventDefault(), openAt(0);
    if (event.key === "ArrowUp") event.preventDefault(), openAt(items.length - 1);
  }
  function onMenuKey(event) {
    const last = items.length - 1;
    if (event.key === "ArrowDown") setActive((i) => i === last ? 0 : i + 1);
    else if (event.key === "ArrowUp") setActive((i) => i === 0 ? last : i - 1);
    else if (event.key === "Home") setActive(0);
    else if (event.key === "End") setActive(last);
    else if (event.key === "Escape" || event.key === "Tab") close();
    else return;
    event.preventDefault();
  }
  return /* @__PURE__ */ jsxs("div", { className: "menu-wrap", children: [
    /* @__PURE__ */ jsxs(
      "button",
      {
        ref: button,
        id: `${id}-button`,
        "aria-haspopup": "menu",
        "aria-expanded": open,
        "aria-controls": `${id}-menu`,
        onClick: () => open ? close() : openAt(0),
        onKeyDown: onButtonKey,
        children: [
          label,
          " \u25BE"
        ]
      }
    ),
    open && /* @__PURE__ */ jsx("ul", { role: "menu", id: `${id}-menu`, "aria-labelledby": `${id}-button`, onKeyDown: onMenuKey, children: items.map((item, i) => /* @__PURE__ */ jsx("li", { role: "none", children: /* @__PURE__ */ jsx(
      "button",
      {
        ref: (el) => {
          itemRefs.current[i] = el;
        },
        role: "menuitem",
        tabIndex: -1,
        className: item.danger ? "danger-text" : void 0,
        onClick: () => {
          item.onSelect();
          close();
        },
        children: item.label
      }
    ) }, item.label)) })
  ] });
}

// ar/react/projects/menu.tsx
import { jsx as jsx2 } from "react/jsx-runtime";
var noop = () => {
};
createRoot(document.getElementById("root")).render(
  /* @__PURE__ */ jsx2("div", { className: "card", children: /* @__PURE__ */ jsx2(
    MenuButton,
    {
      label: "\u0625\u062C\u0631\u0627\u0621\u0627\u062A \u0627\u0644\u0637\u0644\u0628 #1042",
      items: [
        { label: "\u062A\u062A\u0628\u0651\u0639", onSelect: noop },
        { label: "\u0646\u0632\u0651\u0644 \u0627\u0644\u0641\u0627\u062A\u0648\u0631\u0629", onSelect: noop },
        { label: "\u0623\u0631\u062C\u0639 \u0645\u0646\u062A\u062C\u0627\u062A", onSelect: noop },
        { label: "\u0623\u0644\u063A\u0650 \u0627\u0644\u0637\u0644\u0628", danger: true, onSelect: noop }
      ]
    }
  ) })
);
