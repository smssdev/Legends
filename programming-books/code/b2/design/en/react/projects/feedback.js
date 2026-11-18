// en/react/projects/feedback.tsx
import { createRoot } from "react-dom/client";

// en/react/projects/Alert.tsx
import { jsx, jsxs } from "react/jsx-runtime";
var ICONS = { info: "\u2139", success: "\u2713", warning: "!", danger: "\u2715" };
function Alert({ tone = "info", children }) {
  const role = tone === "danger" ? "alert" : "status";
  return /* @__PURE__ */ jsxs("div", { className: `alert alert-${tone}`, role, children: [
    /* @__PURE__ */ jsx("span", { "aria-hidden": "true", children: ICONS[tone] }),
    /* @__PURE__ */ jsx("span", { children })
  ] });
}

// en/react/projects/Badge.tsx
import { jsx as jsx2 } from "react/jsx-runtime";
function Badge({ tone = "neutral", children }) {
  return /* @__PURE__ */ jsx2("span", { className: `badge badge-${tone}`, children });
}

// en/react/projects/feedback.tsx
import { jsx as jsx3, jsxs as jsxs2 } from "react/jsx-runtime";
createRoot(document.getElementById("root")).render(
  /* @__PURE__ */ jsxs2("div", { className: "gallery", children: [
    /* @__PURE__ */ jsxs2("div", { className: "row", children: [
      /* @__PURE__ */ jsx3("b", { children: "Order #1042" }),
      /* @__PURE__ */ jsx3(Badge, { tone: "success", children: "Paid" }),
      /* @__PURE__ */ jsx3(Badge, { tone: "warning", children: "Pending" }),
      /* @__PURE__ */ jsx3(Badge, { tone: "danger", children: "Refunded" }),
      /* @__PURE__ */ jsx3(Badge, { children: "New" })
    ] }),
    /* @__PURE__ */ jsxs2("div", { children: [
      /* @__PURE__ */ jsx3(Alert, { children: "Your order ships tomorrow." }),
      /* @__PURE__ */ jsx3(Alert, { tone: "success", children: "Payment received. Thank you!" }),
      /* @__PURE__ */ jsx3(Alert, { tone: "warning", children: "Only 2 left in stock." }),
      /* @__PURE__ */ jsx3(Alert, { tone: "danger", children: "The card was declined. Please try another one." })
    ] })
  ] })
);
