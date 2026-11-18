var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/status.tsx
import { createRoot } from "react-dom/client";
import { Fragment, jsx, jsxs } from "react/jsx-runtime";
var require_status = __commonJS({
  "ar/status.tsx"() {
    function OrderList({ state }) {
      if (state.status === "loading") {
        return /* @__PURE__ */ jsxs("p", { className: "muted", children: [
          /* @__PURE__ */ jsx("span", { className: "spinner" }),
          "\u062C\u0627\u0631\u064D \u062A\u062D\u0645\u064A\u0644 \u0637\u0644\u0628\u0627\u062A\u0643\u2026"
        ] });
      }
      if (state.status === "error") {
        return /* @__PURE__ */ jsxs("p", { className: "error", children: [
          "\u062A\u0639\u0630\u0651\u0631 \u062A\u062D\u0645\u064A\u0644 \u0637\u0644\u0628\u0627\u062A\u0643: ",
          state.message,
          /* @__PURE__ */ jsx("button", { className: "secondary", children: "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649" })
        ] });
      }
      if (state.orders.length === 0) {
        return /* @__PURE__ */ jsx("p", { className: "muted", children: "\u0644\u064A\u0633\u062A \u0644\u062F\u064A\u0643 \u0637\u0644\u0628\u0627\u062A \u0628\u0639\u062F." });
      }
      return /* @__PURE__ */ jsx("ul", { children: state.orders.map((order) => /* @__PURE__ */ jsx("li", { children: order }, order)) });
    }
    var examples = [
      { status: "loading" },
      { status: "error", message: "\u0623\u0646\u062A \u063A\u064A\u0631 \u0645\u062A\u0635\u0644" },
      { status: "success", orders: [] },
      { status: "success", orders: ["#1042 \xB7 \u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", "#1043 \xB7 \u0643\u0648\u0628 \u0628\u0650\u062A"] }
    ];
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx(Fragment, { children: examples.map((state, i) => /* @__PURE__ */ jsx("div", { className: "panel", children: /* @__PURE__ */ jsx(OrderList, { state }) }, i)) })
    );
  }
});
export default require_status();
