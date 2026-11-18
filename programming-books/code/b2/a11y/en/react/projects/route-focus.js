// en/react/projects/route-focus.tsx
import { createRoot } from "react-dom/client";
import { createMemoryRouter, Link, Outlet, RouterProvider } from "react-router";

// en/react/projects/RouteFocus.tsx
import { useEffect, useRef, useState } from "react";
import { useLocation } from "react-router";
import { jsx } from "react/jsx-runtime";
function RouteFocus({ appName }) {
  const location = useLocation();
  const first = useRef(true);
  const [message, setMessage] = useState("");
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    const heading = document.querySelector("main h1");
    if (!heading) return;
    document.title = `${heading.textContent} \xB7 ${appName}`;
    heading.tabIndex = -1;
    heading.focus();
    setMessage(heading.textContent ?? "");
  }, [location.pathname, appName]);
  return /* @__PURE__ */ jsx("p", { role: "status", className: "sr-only", children: message });
}

// en/react/projects/route-focus.tsx
import { Fragment, jsx as jsx2, jsxs } from "react/jsx-runtime";
function Layout() {
  return /* @__PURE__ */ jsxs(Fragment, { children: [
    /* @__PURE__ */ jsxs("nav", { className: "card", style: { display: "flex", gap: 12 }, children: [
      /* @__PURE__ */ jsx2(Link, { to: "/", children: "Home" }),
      /* @__PURE__ */ jsx2(Link, { to: "/orders", children: "Your orders" })
    ] }),
    /* @__PURE__ */ jsx2("main", { children: /* @__PURE__ */ jsx2(Outlet, {}) }),
    /* @__PURE__ */ jsx2(RouteFocus, { appName: "Bit's shop" })
  ] });
}
var router = createMemoryRouter([
  {
    path: "/",
    element: /* @__PURE__ */ jsx2(Layout, {}),
    children: [
      { index: true, element: /* @__PURE__ */ jsx2("h1", { children: "Home" }) },
      { path: "orders", element: /* @__PURE__ */ jsx2("h1", { children: "Your orders" }) }
    ]
  }
]);
createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(RouterProvider, { router }));
