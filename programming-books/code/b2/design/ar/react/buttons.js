// ar/react/buttons.tsx
import { createRoot } from "react-dom/client";

// ar/react/Button.tsx
import { jsx, jsxs } from "react/jsx-runtime";
function Button({ variant = "primary", size = "md", loading = false, className, children, disabled, ...rest }) {
  const classes = ["btn", `btn-${variant}`, `btn-${size}`, className].filter(Boolean).join(" ");
  return /* @__PURE__ */ jsxs("button", { type: "button", className: classes, disabled: disabled || loading, "aria-busy": loading || void 0, ...rest, children: [
    loading && /* @__PURE__ */ jsx("span", { className: "spinner", "aria-hidden": "true" }),
    children
  ] });
}

// ar/react/buttons.tsx
import { Fragment, jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
function Gallery() {
  return /* @__PURE__ */ jsxs2("div", { className: "gallery", children: [
    /* @__PURE__ */ jsxs2("div", { className: "row", children: [
      /* @__PURE__ */ jsx2(Button, { children: "\u0623\u0633\u0627\u0633\u064A" }),
      /* @__PURE__ */ jsx2(Button, { variant: "secondary", children: "\u062B\u0627\u0646\u0648\u064A" }),
      /* @__PURE__ */ jsx2(Button, { variant: "danger", children: "\u062E\u0637\u0631" }),
      /* @__PURE__ */ jsx2(Button, { variant: "ghost", children: "\u0634\u0641\u0627\u0641" })
    ] }),
    /* @__PURE__ */ jsxs2("div", { className: "row", children: [
      /* @__PURE__ */ jsx2(Button, { size: "sm", children: "\u0635\u063A\u064A\u0631" }),
      /* @__PURE__ */ jsx2(Button, { size: "lg", children: "\u0643\u0628\u064A\u0631" }),
      /* @__PURE__ */ jsx2(Button, { loading: true, children: "\u062C\u0627\u0631\u064D \u0627\u0644\u062D\u0641\u0638\u2026" }),
      /* @__PURE__ */ jsx2(Button, { disabled: true, children: "\u0623\u0644\u063A\u0650" })
    ] })
  ] });
}
var root = createRoot(document.getElementById("root"));
root.render(
  /* @__PURE__ */ jsxs2(Fragment, { children: [
    /* @__PURE__ */ jsx2(Gallery, {}),
    /* @__PURE__ */ jsx2("div", { "data-theme": "dark", style: { marginTop: 12 }, children: /* @__PURE__ */ jsx2(Gallery, {}) })
  ] })
);
