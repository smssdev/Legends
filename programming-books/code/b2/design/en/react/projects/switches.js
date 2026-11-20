// en/react/projects/switches.tsx
import { useState as useState2 } from "react";
import { createRoot } from "react-dom/client";

// en/react/projects/Switch.tsx
import { useState } from "react";
import { jsx, jsxs } from "react/jsx-runtime";
function Switch({ label, checked, defaultChecked = false, onChange }) {
  const [inner, setInner] = useState(defaultChecked);
  const isControlled = checked !== void 0;
  const on = isControlled ? checked : inner;
  function toggle() {
    if (!isControlled) setInner(!on);
    onChange?.(!on);
  }
  return /* @__PURE__ */ jsxs("button", { type: "button", role: "switch", "aria-checked": on, className: "switch", onClick: toggle, children: [
    /* @__PURE__ */ jsx("span", { className: "track", "aria-hidden": "true", children: /* @__PURE__ */ jsx("span", { className: "thumb" }) }),
    label
  ] });
}

// en/react/projects/switches.tsx
import { jsx as jsx2, jsxs as jsxs2 } from "react/jsx-runtime";
function Settings() {
  const [dark, setDark] = useState2(false);
  return /* @__PURE__ */ jsxs2("div", { className: "gallery", "data-theme": dark ? "dark" : void 0, children: [
    /* @__PURE__ */ jsx2(Switch, { label: "Email me about new books", defaultChecked: true }),
    /* @__PURE__ */ jsx2(Switch, { label: "Wi-Fi" }),
    /* @__PURE__ */ jsx2(Switch, { label: "Dark theme", checked: dark, onChange: setDark })
  ] });
}
createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(Settings, {}));
