var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/status.tsx
import { createRoot } from "react-dom/client";
import { Fragment, jsx, jsxs } from "react/jsx-runtime";
var require_status = __commonJS({
  "en/status.tsx"() {
    function OrderList({ state }) {
      if (state.status === "loading") {
        return /* @__PURE__ */ jsxs("p", { className: "muted", children: [
          /* @__PURE__ */ jsx("span", { className: "spinner" }),
          "Loading your orders\u2026"
        ] });
      }
      if (state.status === "error") {
        return /* @__PURE__ */ jsxs("p", { className: "error", children: [
          "Could not load your orders: ",
          state.message,
          /* @__PURE__ */ jsx("button", { className: "secondary", children: "Try again" })
        ] });
      }
      if (state.orders.length === 0) {
        return /* @__PURE__ */ jsx("p", { className: "muted", children: "You have no orders yet." });
      }
      return /* @__PURE__ */ jsx("ul", { children: state.orders.map((order) => /* @__PURE__ */ jsx("li", { children: order }, order)) });
    }
    var examples = [
      { status: "loading" },
      { status: "error", message: "you are offline" },
      { status: "success", orders: [] },
      { status: "success", orders: ["#1042 \xB7 Code from Zero", "#1043 \xB7 Bit mug"] }
    ];
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx(Fragment, { children: examples.map((state, i) => /* @__PURE__ */ jsx("div", { className: "panel", children: /* @__PURE__ */ jsx(OrderList, { state }) }, i)) })
    );
  }
});
export default require_status();
