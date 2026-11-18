// ar/react/projects/feedback.tsx
import { createRoot } from "react-dom/client";

// ar/react/projects/Alert.tsx
import { jsx, jsxs } from "react/jsx-runtime";
var ICONS = { info: "\u2139", success: "\u2713", warning: "!", danger: "\u2715" };
function Alert({ tone = "info", children }) {
  const role = tone === "danger" ? "alert" : "status";
  return /* @__PURE__ */ jsxs("div", { className: `alert alert-${tone}`, role, children: [
    /* @__PURE__ */ jsx("span", { "aria-hidden": "true", children: ICONS[tone] }),
    /* @__PURE__ */ jsx("span", { children })
  ] });
}

// ar/react/projects/Badge.tsx
import { jsx as jsx2 } from "react/jsx-runtime";
function Badge({ tone = "neutral", children }) {
  return /* @__PURE__ */ jsx2("span", { className: `badge badge-${tone}`, children });
}

// ar/react/projects/feedback.tsx
import { jsx as jsx3, jsxs as jsxs2 } from "react/jsx-runtime";
createRoot(document.getElementById("root")).render(
  /* @__PURE__ */ jsxs2("div", { className: "gallery", children: [
    /* @__PURE__ */ jsxs2("div", { className: "row", children: [
      /* @__PURE__ */ jsx3("b", { children: "\u0627\u0644\u0637\u0644\u0628 #1042" }),
      /* @__PURE__ */ jsx3(Badge, { tone: "success", children: "\u0645\u062F\u0641\u0648\u0639" }),
      /* @__PURE__ */ jsx3(Badge, { tone: "warning", children: "\u0642\u064A\u062F \u0627\u0644\u0627\u0646\u062A\u0638\u0627\u0631" }),
      /* @__PURE__ */ jsx3(Badge, { tone: "danger", children: "\u0645\u0633\u062A\u0631\u062F" }),
      /* @__PURE__ */ jsx3(Badge, { children: "\u062C\u062F\u064A\u062F" })
    ] }),
    /* @__PURE__ */ jsxs2("div", { children: [
      /* @__PURE__ */ jsx3(Alert, { children: "\u064A\u064F\u0634\u062D\u0646 \u0637\u0644\u0628\u0643 \u063A\u062F\u0627\u064B." }),
      /* @__PURE__ */ jsx3(Alert, { tone: "success", children: "\u0648\u0635\u0644 \u0627\u0644\u062F\u0641\u0639. \u0634\u0643\u0631\u0627\u064B \u0644\u0643!" }),
      /* @__PURE__ */ jsx3(Alert, { tone: "warning", children: "\u0628\u0642\u064A\u062A \u0642\u0637\u0639\u062A\u0627\u0646 \u0641\u0642\u0637 \u0641\u064A \u0627\u0644\u0645\u062E\u0632\u0648\u0646." }),
      /* @__PURE__ */ jsx3(Alert, { tone: "danger", children: "\u0631\u064F\u0641\u0636\u062A \u0627\u0644\u0628\u0637\u0627\u0642\u0629. \u062C\u0631\u0651\u0628 \u0628\u0637\u0627\u0642\u0629 \u0623\u062E\u0631\u0649 \u0645\u0646 \u0641\u0636\u0644\u0643." })
    ] })
  ] })
);
