// ar/react/projects/route-focus.tsx
import { createRoot } from "react-dom/client";
import { createMemoryRouter, Link, Outlet, RouterProvider } from "react-router";

// ar/react/projects/RouteFocus.tsx
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

// ar/react/projects/route-focus.tsx
import { Fragment, jsx as jsx2, jsxs } from "react/jsx-runtime";
function Layout() {
  return /* @__PURE__ */ jsxs(Fragment, { children: [
    /* @__PURE__ */ jsxs("nav", { className: "card", style: { display: "flex", gap: 12 }, children: [
      /* @__PURE__ */ jsx2(Link, { to: "/", children: "\u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629" }),
      /* @__PURE__ */ jsx2(Link, { to: "/orders", children: "\u0637\u0644\u0628\u0627\u062A\u0643" })
    ] }),
    /* @__PURE__ */ jsx2("main", { children: /* @__PURE__ */ jsx2(Outlet, {}) }),
    /* @__PURE__ */ jsx2(RouteFocus, { appName: "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A" })
  ] });
}
var router = createMemoryRouter([
  {
    path: "/",
    element: /* @__PURE__ */ jsx2(Layout, {}),
    children: [
      { index: true, element: /* @__PURE__ */ jsx2("h1", { children: "\u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629" }) },
      { path: "orders", element: /* @__PURE__ */ jsx2("h1", { children: "\u0637\u0644\u0628\u0627\u062A\u0643" }) }
    ]
  }
]);
createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx2(RouterProvider, { router }));
