var __getOwnPropNames = Object.getOwnPropertyNames;
var __esm = (fn, res, err) => function __init() {
  if (err) throw err[0];
  try {
    return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
  } catch (e) {
    throw err = [e], e;
  }
};
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/projects/toasts.tsx
import { createContext, useCallback, useContext, useState } from "react";
import { createPortal } from "react-dom";
import { jsx, jsxs } from "react/jsx-runtime";
function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);
  const dismiss = useCallback((id) => setToasts((all) => all.filter((t) => t.id !== id)), []);
  const notify = useCallback(
    (text, action) => {
      const id = nextId++;
      setToasts((all) => [...all.slice(-2), { id, text, action }]);
      setTimeout(() => dismiss(id), 5e3);
    },
    [dismiss]
  );
  return /* @__PURE__ */ jsxs(ToastContext.Provider, { value: notify, children: [
    children,
    createPortal(
      /* @__PURE__ */ jsx("div", { className: "toasts", role: "status", "aria-live": "polite", "aria-label": "\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062A", children: toasts.map((t) => /* @__PURE__ */ jsxs("div", { className: "toast", children: [
        /* @__PURE__ */ jsx("span", { children: t.text }),
        t.action && /* @__PURE__ */ jsx(
          "button",
          {
            onClick: () => {
              t.action.run();
              dismiss(t.id);
            },
            children: t.action.label
          }
        ),
        /* @__PURE__ */ jsx("button", { className: "secondary", "aria-label": "\u0623\u063A\u0644\u0642", onClick: () => dismiss(t.id), children: "\xD7" })
      ] }, t.id)) }),
      document.body
    )
  ] });
}
function useToast() {
  const notify = useContext(ToastContext);
  if (!notify) throw new Error("useToast must be used inside <ToastProvider>");
  return notify;
}
var ToastContext, nextId;
var init_toasts = __esm({
  "ar/projects/toasts.tsx"() {
    ToastContext = createContext(null);
    nextId = 1;
  }
});

// ar/projects/toasts-page.tsx
import { useState as useState2 } from "react";
import { createRoot } from "react-dom/client";
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
var require_toasts_page = __commonJS({
  "ar/projects/toasts-page.tsx"() {
    init_toasts();
    var NAMES = ["\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", "\u0643\u0648\u0628 \u0628\u0650\u062A", "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A"];
    function Shelf() {
      const notify = useToast();
      const [items, setItems] = useState2(NAMES);
      function remove(name) {
        setItems((all) => all.filter((n) => n !== name));
        notify(`\u062D\u064F\u0630\u0641: ${name}`, { label: "\u062A\u0631\u0627\u062C\u0639", run: () => setItems((all) => [...all, name]) });
      }
      return /* @__PURE__ */ jsx2("section", { className: "card", children: items.map((name) => /* @__PURE__ */ jsxs2("div", { className: "row", style: { justifyContent: "space-between", padding: "4px 0" }, children: [
        /* @__PURE__ */ jsx2("span", { children: name }),
        /* @__PURE__ */ jsxs2("span", { className: "row", children: [
          /* @__PURE__ */ jsx2("button", { onClick: () => notify(`${name} \u0623\u064F\u0636\u064A\u0641 \u0625\u0644\u0649 \u0627\u0644\u0633\u0644\u0629`), children: "\u0623\u0636\u0641" }),
          /* @__PURE__ */ jsx2("button", { className: "secondary", onClick: () => remove(name), children: "\xD7" })
        ] })
      ] }, name)) });
    }
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx2(ToastProvider, { children: /* @__PURE__ */ jsx2(Shelf, {}) })
    );
  }
});
export default require_toasts_page();
