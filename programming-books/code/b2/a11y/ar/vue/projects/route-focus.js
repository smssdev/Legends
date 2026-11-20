// a11y/ar/vue/projects/route-focus.ts
import { createApp, h } from "vue";
import { createMemoryHistory, createRouter } from "vue-router";

// a11y/ar/vue/projects/FocusApp.vue
import { defineComponent as _defineComponent } from "vue";
import { createTextVNode as _createTextVNode, resolveComponent as _resolveComponent, withCtx as _withCtx, createVNode as _createVNode, createElementVNode as _createElementVNode, unref as _unref, toDisplayString as _toDisplayString, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";

// a11y/ar/vue/projects/routeFocus.ts
import { nextTick, ref } from "vue";
var announcement = ref("");
function routeFocus(router2, appName) {
  router2.afterEach(async (_to, from) => {
    if (from.matched.length === 0) return;
    await nextTick();
    const heading = document.querySelector("main h1");
    if (!heading) return;
    document.title = `${heading.textContent} \xB7 ${appName}`;
    heading.tabIndex = -1;
    heading.focus();
    announcement.value = heading.textContent ?? "";
  });
}

// a11y/ar/vue/projects/FocusApp.vue
var _hoisted_1 = {
  class: "card",
  style: { "display": "flex", "gap": "12px" }
};
var _hoisted_2 = {
  role: "status",
  class: "sr-only"
};
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "FocusApp",
  setup(__props) {
    return (_ctx, _cache) => {
      const _component_RouterLink = _resolveComponent("RouterLink");
      const _component_RouterView = _resolveComponent("RouterView");
      return _openBlock(), _createElementBlock(
        _Fragment,
        null,
        [
          _createElementVNode("nav", _hoisted_1, [
            _createVNode(_component_RouterLink, { to: "/" }, {
              default: _withCtx(() => [..._cache[0] || (_cache[0] = [
                _createTextVNode(
                  "\u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629",
                  -1
                  /* CACHED */
                )
              ])]),
              _: 1
              /* STABLE */
            }),
            _createVNode(_component_RouterLink, { to: "/orders" }, {
              default: _withCtx(() => [..._cache[1] || (_cache[1] = [
                _createTextVNode(
                  "\u0637\u0644\u0628\u0627\u062A\u0643",
                  -1
                  /* CACHED */
                )
              ])]),
              _: 1
              /* STABLE */
            })
          ]),
          _createElementVNode("main", null, [
            _createVNode(_component_RouterView)
          ]),
          _createElementVNode(
            "p",
            _hoisted_2,
            _toDisplayString(_unref(announcement)),
            1
            /* TEXT */
          )
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var FocusApp_default = _sfc;

// a11y/ar/vue/projects/route-focus.ts
var router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", component: { render: () => h("h1", "\u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629") } },
    { path: "/orders", component: { render: () => h("h1", "\u0637\u0644\u0628\u0627\u062A\u0643") } }
  ]
});
routeFocus(router, "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A");
await router.push("/");
createApp(FocusApp_default).use(router).mount("#app");
