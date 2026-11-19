// vue/routing/en/projects/blog-page.ts
import { createApp } from "vue";
import { createMemoryHistory, createRouter } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";

// vue/routing/en/projects/BlogApp.vue
import { resolveComponent as _resolveComponent, openBlock as _openBlock, createBlock as _createBlock } from "vue";
function render(_ctx, _cache) {
  const _component_RouterView = _resolveComponent("RouterView");
  return _openBlock(), _createBlock(_component_RouterView);
}
var _sfc = { render };
var BlogApp_default = _sfc;

// vue/routing/en/projects/BlogLayout.vue
import { createElementVNode as _createElementVNode, createTextVNode as _createTextVNode, resolveComponent as _resolveComponent2, withCtx as _withCtx, createVNode as _createVNode, openBlock as _openBlock2, createElementBlock as _createElementBlock } from "vue";
var _hoisted_1 = { class: "layout" };
function render2(_ctx, _cache) {
  const _component_RouterLink = _resolveComponent2("RouterLink");
  const _component_RouterView = _resolveComponent2("RouterView");
  return _openBlock2(), _createElementBlock("div", _hoisted_1, [
    _createElementVNode("nav", null, [
      _cache[1] || (_cache[1] = _createElementVNode(
        "span",
        { class: "brand" },
        "Bit's blog",
        -1
        /* CACHED */
      )),
      _createVNode(_component_RouterLink, { to: "/" }, {
        default: _withCtx(() => [..._cache[0] || (_cache[0] = [
          _createTextVNode(
            "Posts",
            -1
            /* CACHED */
          )
        ])]),
        _: 1
        /* STABLE */
      })
    ]),
    _createVNode(_component_RouterView)
  ]);
}
var _sfc2 = { render: render2 };
var BlogLayout_default = _sfc2;

// vue/routing/en/projects/PostList.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock3, createElementBlock as _createElementBlock2, toDisplayString as _toDisplayString, createTextVNode as _createTextVNode2, resolveComponent as _resolveComponent3, withCtx as _withCtx2, createVNode as _createVNode2, createElementVNode as _createElementVNode2 } from "vue";

// vue/routing/en/projects/posts.ts
var posts = [
  { slug: "why-typescript", title: "Why I love TypeScript", body: "Types catch mistakes while I type, so my evenings are free.", minutes: 4 },
  { slug: "rules-for-state", title: "Three rules for state", body: "Keep it minimal, compute the rest, and give each piece one owner.", minutes: 6 },
  { slug: "keys-explained", title: "Keys, explained", body: "A key tells Vue which item is which between two updates.", minutes: 3 }
];

// vue/routing/en/projects/PostList.vue
var _hoisted_12 = { class: "list card" };
var _hoisted_2 = { class: "muted" };
var _sfc3 = /* @__PURE__ */ _defineComponent({
  __name: "PostList",
  setup(__props) {
    return (_ctx, _cache) => {
      const _component_RouterLink = _resolveComponent3("RouterLink");
      return _openBlock3(), _createElementBlock2("ul", _hoisted_12, [
        (_openBlock3(true), _createElementBlock2(
          _Fragment,
          null,
          _renderList(_unref(posts), (post) => {
            return _openBlock3(), _createElementBlock2("li", {
              key: post.slug
            }, [
              _createVNode2(_component_RouterLink, {
                to: { name: "post", params: { slug: post.slug } }
              }, {
                default: _withCtx2(() => [
                  _createTextVNode2(
                    _toDisplayString(post.title),
                    1
                    /* TEXT */
                  )
                ]),
                _: 2
                /* DYNAMIC */
              }, 1032, ["to"]),
              _createElementVNode2(
                "span",
                _hoisted_2,
                _toDisplayString(post.minutes) + " min read",
                1
                /* TEXT */
              )
            ]);
          }),
          128
          /* KEYED_FRAGMENT */
        ))
      ]);
    };
  }
});
var PostList_default = _sfc3;

// vue/routing/en/projects/PostPage.vue
import { defineComponent as _defineComponent2 } from "vue";
import { toDisplayString as _toDisplayString2, createElementVNode as _createElementVNode3, openBlock as _openBlock4, createElementBlock as _createElementBlock3, createTextVNode as _createTextVNode3, resolveComponent as _resolveComponent4, withCtx as _withCtx3, createVNode as _createVNode3 } from "vue";
import { computed } from "vue";
var _hoisted_13 = {
  key: 0,
  class: "card"
};
var _hoisted_22 = { class: "muted" };
var _hoisted_3 = {
  key: 1,
  class: "card"
};
var _sfc4 = /* @__PURE__ */ _defineComponent2({
  __name: "PostPage",
  props: {
    slug: {}
  },
  setup(__props) {
    const props = __props;
    const post = computed(() => posts.find((p) => p.slug === props.slug));
    return (_ctx, _cache) => {
      const _component_RouterLink = _resolveComponent4("RouterLink");
      return post.value ? (_openBlock4(), _createElementBlock3("article", _hoisted_13, [
        _createElementVNode3(
          "h2",
          null,
          _toDisplayString2(post.value.title),
          1
          /* TEXT */
        ),
        _createElementVNode3(
          "p",
          _hoisted_22,
          "by Bit \xB7 " + _toDisplayString2(post.value.minutes) + " min read",
          1
          /* TEXT */
        ),
        _createElementVNode3(
          "p",
          null,
          _toDisplayString2(post.value.body),
          1
          /* TEXT */
        )
      ])) : (_openBlock4(), _createElementBlock3("p", _hoisted_3, [
        _cache[1] || (_cache[1] = _createTextVNode3(
          "This post does not exist. ",
          -1
          /* CACHED */
        )),
        _createVNode3(_component_RouterLink, { to: "/" }, {
          default: _withCtx3(() => [..._cache[0] || (_cache[0] = [
            _createTextVNode3(
              "Go to the home page",
              -1
              /* CACHED */
            )
          ])]),
          _: 1
          /* STABLE */
        })
      ]));
    };
  }
});
var PostPage_default = _sfc4;

// vue/routing/en/projects/blog-routes.ts
var routes = [
  {
    path: "/",
    component: BlogLayout_default,
    children: [
      { path: "", name: "posts", component: PostList_default },
      { path: "posts/:slug", name: "post", component: PostPage_default, props: true }
    ]
  }
];

// vue/routing/en/projects/blog-page.ts
var router = createRouter({ history: createMemoryHistory(), routes });
await router.push("/");
createApp(BlogApp_default).use(router).use(VueQueryPlugin, { queryClientConfig: { defaultOptions: { queries: { staleTime: 3e4 } } } }).mount("#app");
