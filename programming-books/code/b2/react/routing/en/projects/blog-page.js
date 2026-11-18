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

// en/projects/blog-routes.tsx
import { Link, NavLink, Outlet, useParams } from "react-router";
import { jsx, jsxs } from "react/jsx-runtime";
function Layout() {
  return /* @__PURE__ */ jsxs("div", { className: "layout", children: [
    /* @__PURE__ */ jsxs("nav", { children: [
      /* @__PURE__ */ jsx("span", { className: "brand", children: "Bit's blog" }),
      /* @__PURE__ */ jsx(NavLink, { to: "/", end: true, children: "Posts" })
    ] }),
    /* @__PURE__ */ jsx(Outlet, {})
  ] });
}
function PostList() {
  return /* @__PURE__ */ jsx("ul", { className: "list card", children: posts.map((post) => /* @__PURE__ */ jsxs("li", { children: [
    /* @__PURE__ */ jsx(Link, { to: `/posts/${post.slug}`, children: post.title }),
    /* @__PURE__ */ jsxs("span", { className: "muted", children: [
      post.minutes,
      " min read"
    ] })
  ] }, post.slug)) });
}
function PostPage() {
  const { slug } = useParams();
  const post = posts.find((p) => p.slug === slug);
  if (!post) {
    return /* @__PURE__ */ jsxs("p", { className: "card", children: [
      "This post does not exist. ",
      /* @__PURE__ */ jsx(Link, { to: "/", children: "Go to the home page" })
    ] });
  }
  return /* @__PURE__ */ jsxs("article", { className: "card", children: [
    /* @__PURE__ */ jsx("h2", { children: post.title }),
    /* @__PURE__ */ jsxs("p", { className: "muted", children: [
      "by Bit \xB7 ",
      post.minutes,
      " min read"
    ] }),
    /* @__PURE__ */ jsx("p", { children: post.body })
  ] });
}
var posts, routes;
var init_blog_routes = __esm({
  "en/projects/blog-routes.tsx"() {
    posts = [
      { slug: "why-typescript", title: "Why I love TypeScript", body: "Types catch mistakes while I type, so my evenings are free.", minutes: 4 },
      { slug: "rules-for-state", title: "Three rules for state", body: "Keep it minimal, derive the rest, and never change it in place.", minutes: 6 },
      { slug: "keys-explained", title: "Keys, explained", body: "A key tells React which item is which between two renders.", minutes: 3 }
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

// en/projects/blog-page.tsx
import { createRoot } from "react-dom/client";
import { createMemoryRouter, RouterProvider } from "react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { jsx as jsx2 } from "react/jsx-runtime";
var require_blog_page = __commonJS({
  "en/projects/blog-page.tsx"() {
    init_blog_routes();
    var router = createMemoryRouter(routes);
    var queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 3e4 } } });
    createRoot(document.getElementById("root")).render(
      /* @__PURE__ */ jsx2(QueryClientProvider, { client: queryClient, children: /* @__PURE__ */ jsx2(RouterProvider, { router }) })
    );
  }
});
export default require_blog_page();
