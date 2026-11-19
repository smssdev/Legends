// en/react/transition.tsx
import { useDeferredValue, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";

// en/react/SlowList.tsx
import { memo } from "react";
import { jsx } from "react/jsx-runtime";
function SlowRow({ name }) {
  const start = performance.now();
  while (performance.now() - start < 0.2) {
  }
  return /* @__PURE__ */ jsx("li", { children: name });
}
var SlowList = memo(function SlowList2({ items }) {
  return /* @__PURE__ */ jsx("ul", { children: items.slice(0, 2e3).map((name) => /* @__PURE__ */ jsx(SlowRow, { name }, name)) });
});

// en/react/transition.tsx
import { jsx as jsx2, jsxs } from "react/jsx-runtime";
var ALL = Array.from({ length: 5e3 }, (_, i) => `Bit item ${i + 1}`);
function Filter() {
  const [text, setText] = useState("");
  const deferred = useDeferredValue(text);
  const items = useMemo(() => ALL.filter((name) => name.includes(deferred)), [deferred]);
  const stale = text !== deferred;
  return /* @__PURE__ */ jsxs("div", { className: "card", children: [
    /* @__PURE__ */ jsx2("label", { htmlFor: "q", children: "Filter products" }),
    /* @__PURE__ */ jsx2("input", { id: "q", value: text, onChange: (e) => setText(e.target.value) }),
    /* @__PURE__ */ jsx2("p", { className: "muted", "aria-live": "polite", children: stale ? "Updating\u2026" : `Showing ${items.length} of ${ALL.length}` }),
    /* @__PURE__ */ jsx2("div", { className: stale ? "stale" : void 0, children: /* @__PURE__ */ jsx2(SlowList, { items }) })
  ] });
}
createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(Filter, {}));
