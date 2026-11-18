var __getOwnPropNames = Object.getOwnPropertyNames;
var __esm = (fn, res, err) => function __init() {
  if (err) throw err[0];
  try {
    return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
  } catch (e) {
    throw err = [e], e;
  }
};
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/projects/blog-routes.tsx
import { Link, NavLink, Outlet, useParams } from "react-router";
import { jsx, jsxs } from "react/jsx-runtime";
function Layout() {
  return /* @__PURE__ */ jsxs("div", { className: "layout", children: [
    /* @__PURE__ */ jsxs("nav", { children: [
      /* @__PURE__ */ jsx("span", { className: "brand", children: "\u0645\u062F\u0648\u0646\u0629 \u0628\u0650\u062A" }),
      /* @__PURE__ */ jsx(NavLink, { to: "/", end: true, children: "\u0627\u0644\u062A\u062F\u0648\u064A\u0646\u0627\u062A" })
    ] }),
    /* @__PURE__ */ jsx(Outlet, {})
  ] });
}
function PostList() {
  return /* @__PURE__ */ jsx("ul", { className: "list card", children: posts.map((post) => /* @__PURE__ */ jsxs("li", { children: [
    /* @__PURE__ */ jsx(Link, { to: `/posts/${post.slug}`, children: post.title }),
    /* @__PURE__ */ jsxs("span", { className: "muted", children: [
      post.minutes,
      " \u062F\u0642\u0627\u0626\u0642 \u0642\u0631\u0627\u0621\u0629"
    ] })
  ] }, post.slug)) });
}
function PostPage() {
  const { slug } = useParams();
  const post = posts.find((p) => p.slug === slug);
  if (!post) {
    return /* @__PURE__ */ jsxs("p", { className: "card", children: [
      "\u0647\u0630\u0647 \u0627\u0644\u062A\u062F\u0648\u064A\u0646\u0629 \u063A\u064A\u0631 \u0645\u0648\u062C\u0648\u062F\u0629. ",
      /* @__PURE__ */ jsx(Link, { to: "/", children: "\u0627\u0630\u0647\u0628 \u0625\u0644\u0649 \u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629" })
    ] });
  }
  return /* @__PURE__ */ jsxs("article", { className: "card", children: [
    /* @__PURE__ */ jsx("h2", { children: post.title }),
    /* @__PURE__ */ jsxs("p", { className: "muted", children: [
      "\u0628\u0642\u0644\u0645 \u0628\u0650\u062A \xB7 ",
      post.minutes,
      " \u062F\u0642\u0627\u0626\u0642 \u0642\u0631\u0627\u0621\u0629"
    ] }),
    /* @__PURE__ */ jsx("p", { children: post.body })
  ] });
}
var posts, routes;
var init_blog_routes = __esm({
  "ar/projects/blog-routes.tsx"() {
    posts = [
      { slug: "why-typescript", title: "\u0644\u0645\u0627\u0630\u0627 \u0623\u062D\u0628 TypeScript", body: "\u0627\u0644\u0623\u0646\u0648\u0627\u0639 \u062A\u0644\u062A\u0642\u0637 \u0627\u0644\u0623\u062E\u0637\u0627\u0621 \u0648\u0623\u0646\u0627 \u0623\u0643\u062A\u0628\u060C \u0641\u062A\u0628\u0642\u0649 \u0623\u0645\u0633\u064A\u0627\u062A\u064A \u0641\u0627\u0631\u063A\u0629.", minutes: 4 },
      { slug: "rules-for-state", title: "\u062B\u0644\u0627\u062B \u0642\u0648\u0627\u0639\u062F \u0644\u0644\u062D\u0627\u0644\u0629", body: "\u0627\u062D\u0641\u0638 \u0627\u0644\u0623\u0642\u0644\u060C \u0648\u0627\u0634\u062A\u0642 \u0627\u0644\u0628\u0627\u0642\u064A\u060C \u0648\u0644\u0627 \u062A\u063A\u064A\u0651\u0631\u0647\u0627 \u0641\u064A \u0645\u0643\u0627\u0646\u0647\u0627 \u0623\u0628\u062F\u0627\u064B.", minutes: 6 },
      { slug: "keys-explained", title: "\u0627\u0644\u0645\u0641\u0627\u062A\u064A\u062D \u0628\u0628\u0633\u0627\u0637\u0629", body: "\u0627\u0644\u0645\u0641\u062A\u0627\u062D \u064A\u062E\u0628\u0631 React \u0623\u064A \u0639\u0646\u0635\u0631 \u0647\u0648 \u0623\u064A\u0651\u0647 \u0628\u064A\u0646 \u0631\u0633\u0645\u064A\u0646.", minutes: 3 }
    ];
    routes = [
      {
        path: "/",
        element: /* @__PURE__ */ jsx(Layout, {}),
        children: [
          { index: true, element: /* @__PURE__ */ jsx(PostList, {}) },
          { path: "posts/:slug", element: /* @__PURE__ */ jsx(PostPage, {}) }
        ]
      }
    ];
  }
});

// ar/projects/blog-page.tsx
import { createRoot } from "react-dom/client";
import { createMemoryRouter, RouterProvider } from "react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { jsx as jsx2 } from "react/jsx-runtime";
var require_blog_page = __commonJS({
  "ar/projects/blog-page.tsx"() {
    init_blog_routes();
    var router = createMemoryRouter(routes);
    var queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 3e4 } } });
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx2(QueryClientProvider, { client: queryClient, children: /* @__PURE__ */ jsx2(RouterProvider, { router }) })
    );
  }
});
export default require_blog_page();
