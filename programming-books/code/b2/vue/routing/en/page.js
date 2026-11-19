// vue/routing/en/page.ts
import { createApp } from "vue";
import { createMemoryHistory, createRouter } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";

// vue/routing/en/App.vue
import { resolveComponent as _resolveComponent, openBlock as _openBlock, createBlock as _createBlock } from "vue";
function render(_ctx, _cache) {
  const _component_RouterView = _resolveComponent("RouterView");
  return _openBlock(), _createBlock(_component_RouterView);
}
var _sfc = { render };
var App_default = _sfc;

// vue/routing/en/views/Layout.vue
import { createElementVNode as _createElementVNode, createTextVNode as _createTextVNode, resolveComponent as _resolveComponent2, withCtx as _withCtx, createVNode as _createVNode, openBlock as _openBlock2, createElementBlock as _createElementBlock } from "vue";
var _hoisted_1 = { class: "layout" };
function render2(_ctx, _cache) {
  const _component_RouterLink = _resolveComponent2("RouterLink");
  const _component_RouterView = _resolveComponent2("RouterView");
  return _openBlock2(), _createElementBlock("div", _hoisted_1, [
    _createElementVNode("nav", null, [
      _cache[2] || (_cache[2] = _createElementVNode(
        "span",
        { class: "brand" },
        "Bit's shop",
        -1
        /* CACHED */
      )),
      _createVNode(_component_RouterLink, {
        to: "/",
        "exact-active-class": "router-link-active",
        "active-class": ""
      }, {
        default: _withCtx(() => [..._cache[0] || (_cache[0] = [
          _createTextVNode(
            "Home",
            -1
            /* CACHED */
          )
        ])]),
        _: 1
        /* STABLE */
      }),
      _createVNode(_component_RouterLink, { to: "/products" }, {
        default: _withCtx(() => [..._cache[1] || (_cache[1] = [
          _createTextVNode(
            "Products",
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
var Layout_default = _sfc2;

// vue/routing/en/views/Home.vue
import { openBlock as _openBlock3, createElementBlock as _createElementBlock2 } from "vue";
var _hoisted_12 = { class: "card" };
function render3(_ctx, _cache) {
  return _openBlock3(), _createElementBlock2("p", _hoisted_12, "Welcome! Browse the products, or search for something.");
}
var _sfc3 = { render: render3 };
var Home_default = _sfc3;

// vue/routing/en/views/Products.vue
import { defineComponent as _defineComponent } from "vue";
import { renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock5, createElementBlock as _createElementBlock4, toDisplayString as _toDisplayString, createTextVNode as _createTextVNode2, resolveComponent as _resolveComponent3, normalizeClass as _normalizeClass, withCtx as _withCtx2, createVNode as _createVNode2, createElementVNode as _createElementVNode3, unref as _unref, createBlock as _createBlock2 } from "vue";
import { computed } from "vue";
import { useRoute } from "vue-router";
import { useQuery } from "@tanstack/vue-query";

// vue/routing/en/api.ts
var products = [
  { id: 1, name: "Code from Zero", description: "The friendly first book of the series.", price: 25, category: "books", favourite: false },
  { id: 2, name: "Bit mug", description: "A big mug for long coding nights.", price: 8, category: "gifts", favourite: false },
  { id: 3, name: "Bit cap", description: "Keeps the sun out of your eyes.", price: 12, category: "gifts", favourite: true },
  { id: 4, name: "Bit sticker", description: "For your laptop.", price: 3, category: "gifts", favourite: false }
];
var NotFoundError = class extends Error {
};
var wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function getProducts(category) {
  await wait(300);
  const list = category ? products.filter((p) => p.category === category) : products;
  return structuredClone(list);
}
async function getProduct(id) {
  await wait(300);
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  return structuredClone(product);
}

// vue/routing/en/views/Skeleton.vue
import { createElementVNode as _createElementVNode2, openBlock as _openBlock4, createElementBlock as _createElementBlock3 } from "vue";
var _hoisted_13 = {
  "aria-busy": "true",
  "aria-label": "Loading\u2026"
};
function render4(_ctx, _cache) {
  return _openBlock4(), _createElementBlock3("div", _hoisted_13, [..._cache[0] || (_cache[0] = [
    _createElementVNode2(
      "div",
      { class: "skeleton" },
      null,
      -1
      /* CACHED */
    ),
    _createElementVNode2(
      "div",
      { class: "skeleton" },
      null,
      -1
      /* CACHED */
    )
  ])]);
}
var _sfc4 = { render: render4 };
var Skeleton_default = _sfc4;

// vue/routing/en/views/Products.vue
var _hoisted_14 = { class: "card" };
var _hoisted_2 = { class: "filters" };
var _hoisted_3 = {
  key: 1,
  class: "error"
};
var _hoisted_4 = {
  key: 2,
  class: "list"
};
var _hoisted_5 = { class: "price" };
var _sfc5 = /* @__PURE__ */ _defineComponent({
  __name: "Products",
  setup(__props) {
    const CATEGORIES = [
      { value: null, label: "All" },
      { value: "books", label: "Books" },
      { value: "gifts", label: "Gifts" }
    ];
    const route = useRoute();
    const category = computed(() => typeof route.query.category === "string" ? route.query.category : null);
    const query = useQuery({
      queryKey: ["products", category],
      queryFn: () => getProducts(category.value)
    });
    return (_ctx, _cache) => {
      const _component_RouterLink = _resolveComponent3("RouterLink");
      return _openBlock5(), _createElementBlock4("section", _hoisted_14, [
        _createElementVNode3("div", _hoisted_2, [
          (_openBlock5(), _createElementBlock4(
            _Fragment,
            null,
            _renderList(CATEGORIES, (c) => {
              return _createVNode2(_component_RouterLink, {
                key: c.label,
                to: { query: c.value ? { category: c.value } : {} },
                class: _normalizeClass({ on: c.value === category.value })
              }, {
                default: _withCtx2(() => [
                  _createTextVNode2(
                    _toDisplayString(c.label),
                    1
                    /* TEXT */
                  )
                ]),
                _: 2
                /* DYNAMIC */
              }, 1032, ["to", "class"]);
            }),
            64
            /* STABLE_FRAGMENT */
          ))
        ]),
        _unref(query).isPending.value ? (_openBlock5(), _createBlock2(Skeleton_default, { key: 0 })) : _unref(query).isError.value ? (_openBlock5(), _createElementBlock4(
          "p",
          _hoisted_3,
          "Something went wrong: " + _toDisplayString(_unref(query).error.value?.message),
          1
          /* TEXT */
        )) : (_openBlock5(), _createElementBlock4("ul", _hoisted_4, [
          (_openBlock5(true), _createElementBlock4(
            _Fragment,
            null,
            _renderList(_unref(query).data.value, (p) => {
              return _openBlock5(), _createElementBlock4("li", {
                key: p.id
              }, [
                _createVNode2(_component_RouterLink, {
                  to: `/products/${p.id}`
                }, {
                  default: _withCtx2(() => [
                    _createTextVNode2(
                      _toDisplayString(p.name),
                      1
                      /* TEXT */
                    )
                  ]),
                  _: 2
                  /* DYNAMIC */
                }, 1032, ["to"]),
                _createElementVNode3(
                  "span",
                  _hoisted_5,
                  _toDisplayString(p.price) + " EGP",
                  1
                  /* TEXT */
                )
              ]);
            }),
            128
            /* KEYED_FRAGMENT */
          ))
        ]))
      ]);
    };
  }
});
var Products_default = _sfc5;

// vue/routing/en/views/Product.vue
import { defineComponent as _defineComponent2 } from "vue";
import { unref as _unref2, openBlock as _openBlock6, createBlock as _createBlock3, createCommentVNode as _createCommentVNode2, toDisplayString as _toDisplayString2, createElementBlock as _createElementBlock5, createElementVNode as _createElementVNode4, createTextVNode as _createTextVNode3, resolveComponent as _resolveComponent4, withCtx as _withCtx3, createVNode as _createVNode3 } from "vue";
import { useQuery as useQuery2 } from "@tanstack/vue-query";
var _hoisted_15 = {
  key: 1,
  class: "card error"
};
var _hoisted_22 = {
  key: 2,
  class: "card"
};
var _hoisted_32 = { class: "price" };
var _sfc6 = /* @__PURE__ */ _defineComponent2({
  __name: "Product",
  props: {
    id: {}
  },
  setup(__props) {
    const props = __props;
    const { data, error, isPending } = useQuery2({
      queryKey: ["product", () => props.id],
      queryFn: () => getProduct(props.id),
      // Retry network errors twice, but never a product that does not exist
      retry: (count, e) => !(e instanceof NotFoundError) && count < 2
    });
    return (_ctx, _cache) => {
      const _component_RouterLink = _resolveComponent4("RouterLink");
      return _unref2(isPending) ? (_openBlock6(), _createBlock3(Skeleton_default, { key: 0 })) : _unref2(error) ? (_openBlock6(), _createElementBlock5(
        "p",
        _hoisted_15,
        _toDisplayString2(_unref2(error) instanceof _unref2(NotFoundError) ? "There is no product with this number." : _unref2(error).message),
        1
        /* TEXT */
      )) : _unref2(data) ? (_openBlock6(), _createElementBlock5("article", _hoisted_22, [
        _createElementVNode4(
          "h2",
          null,
          _toDisplayString2(_unref2(data).name),
          1
          /* TEXT */
        ),
        _createElementVNode4(
          "p",
          null,
          _toDisplayString2(_unref2(data).description),
          1
          /* TEXT */
        ),
        _createElementVNode4(
          "p",
          _hoisted_32,
          _toDisplayString2(_unref2(data).price) + " EGP",
          1
          /* TEXT */
        ),
        _createVNode3(_component_RouterLink, { to: "/products" }, {
          default: _withCtx3(() => [..._cache[0] || (_cache[0] = [
            _createTextVNode3(
              "\u2190 Back to products",
              -1
              /* CACHED */
            )
          ])]),
          _: 1
          /* STABLE */
        })
      ])) : _createCommentVNode2("v-if", true);
    };
  }
});
var Product_default = _sfc6;

// vue/routing/en/views/NotFound.vue
import { createTextVNode as _createTextVNode4, resolveComponent as _resolveComponent5, withCtx as _withCtx4, createVNode as _createVNode4, openBlock as _openBlock7, createElementBlock as _createElementBlock6 } from "vue";
var _hoisted_16 = { class: "card" };
function render5(_ctx, _cache) {
  const _component_RouterLink = _resolveComponent5("RouterLink");
  return _openBlock7(), _createElementBlock6("p", _hoisted_16, [
    _cache[1] || (_cache[1] = _createTextVNode4(
      "Page not found ",
      -1
      /* CACHED */
    )),
    _createVNode4(_component_RouterLink, { to: "/" }, {
      default: _withCtx4(() => [..._cache[0] || (_cache[0] = [
        _createTextVNode4(
          "Home",
          -1
          /* CACHED */
        )
      ])]),
      _: 1
      /* STABLE */
    })
  ]);
}
var _sfc7 = { render: render5 };
var NotFound_default = _sfc7;

// vue/routing/en/routes.ts
var routes = [
  {
    path: "/",
    component: Layout_default,
    children: [
      { path: "", component: Home_default },
      {
        path: "products",
        children: [
          { path: "", component: Products_default },
          // Pass the id as a typed prop, so the component does not need to know about the router
          { path: ":id(\\d+)", component: Product_default, props: (route) => ({ id: Number(route.params.id) }) }
        ]
      },
      { path: ":path(.*)*", component: NotFound_default }
    ]
  }
];

// vue/routing/en/page.ts
var router = createRouter({ history: createMemoryHistory(), routes });
await router.push("/");
createApp(App_default).use(router).use(VueQueryPlugin, { queryClientConfig: { defaultOptions: { queries: { staleTime: 3e4 } } } }).mount("#app");
