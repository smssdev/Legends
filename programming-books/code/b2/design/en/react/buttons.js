// en/react/buttons.tsx
import { createRoot } from "react-dom/client";

// en/react/Button.tsx
import { jsx, jsxs } from "react/jsx-runtime";
function Button({ variant = "primary", size = "md", loading = false, className, children, disabled, ...rest }) {
  const classes = ["btn", `btn-${variant}`, `btn-${size}`, className].filter(Boolean).join(" ");
  return /* @__PURE__ */ jsxs("button", { type: "button", className: classes, disabled: disabled || loading, "aria-busy": loading || void 0, ...rest, children: [
    loading && /* @__PURE__ */ jsx("span", { className: "spinner", "aria-hidden": "true" }),
    children
  ] });
}

// en/react/buttons.tsx
import { Fragment, jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
function Gallery() {
  return /* @__PURE__ */ jsxs2("div", { className: "gallery", children: [
    /* @__PURE__ */ jsxs2("div", { className: "row", children: [
      /* @__PURE__ */ jsx2(Button, { children: "Primary" }),
      /* @__PURE__ */ jsx2(Button, { variant: "secondary", children: "Secondary" }),
      /* @__PURE__ */ jsx2(Button, { variant: "danger", children: "Danger" }),
      /* @__PURE__ */ jsx2(Button, { variant: "ghost", children: "Ghost" })
    ] }),
    /* @__PURE__ */ jsxs2("div", { className: "row", children: [
      /* @__PURE__ */ jsx2(Button, { size: "sm", children: "Small" }),
      /* @__PURE__ */ jsx2(Button, { size: "lg", children: "Large" }),
      /* @__PURE__ */ jsx2(Button, { loading: true, children: "Saving\u2026" }),
      /* @__PURE__ */ jsx2(Button, { disabled: true, children: "Cancel" })
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
