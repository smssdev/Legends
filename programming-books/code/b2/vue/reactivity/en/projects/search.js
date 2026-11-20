// vue/reactivity/en/projects/search.ts
import { createApp } from "vue";

// vue/reactivity/en/projects/Search.vue
import { defineComponent as _defineComponent } from "vue";
import { createElementVNode as _createElementVNode, vModelText as _vModelText, withDirectives as _withDirectives, toDisplayString as _toDisplayString, openBlock as _openBlock, createElementBlock as _createElementBlock, createCommentVNode as _createCommentVNode, renderList as _renderList, Fragment as _Fragment } from "vue";
import { onWatcherCleanup, ref, watch } from "vue";

// vue/reactivity/en/cart-model.ts
var catalogue = [
  { id: 1, name: "Code from Zero", price: 25 },
  { id: 2, name: "Bit mug", price: 8 },
  { id: 3, name: "Bit cap", price: 12 }
];

// vue/reactivity/en/fake-api.ts
function searchProducts(query, signal) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      const q = query.trim().toLowerCase();
      resolve(catalogue.filter((p) => p.name.toLowerCase().includes(q)));
    }, 600 - query.length * 100);
    signal.addEventListener("abort", () => {
      clearTimeout(timer);
      reject(signal.reason);
    });
  });
}

// vue/reactivity/en/projects/Search.vue
var _hoisted_1 = {
  key: 0,
  class: "muted",
  role: "status"
};
var _hoisted_2 = { role: "status" };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Search",
  setup(__props) {
    const query = ref("");
    const results = ref([]);
    const loading = ref(false);
    watch(query, async (q) => {
      if (!q.trim()) {
        results.value = [];
        return;
      }
      const controller = new AbortController();
      onWatcherCleanup(() => controller.abort());
      loading.value = true;
      try {
        results.value = await searchProducts(q, controller.signal);
        loading.value = false;
      } catch {
      }
    });
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock(
        _Fragment,
        null,
        [
          _cache[1] || (_cache[1] = _createElementVNode(
            "label",
            { for: "q" },
            "Search products",
            -1
            /* CACHED */
          )),
          _withDirectives(_createElementVNode(
            "input",
            {
              id: "q",
              "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => query.value = $event),
              type: "search",
              autocomplete: "off"
            },
            null,
            512
            /* NEED_PATCH */
          ), [
            [_vModelText, query.value]
          ]),
          loading.value ? (_openBlock(), _createElementBlock(
            "p",
            _hoisted_1,
            "Searching for \u201C" + _toDisplayString(query.value) + "\u201D\u2026",
            1
            /* TEXT */
          )) : query.value ? (_openBlock(), _createElementBlock(
            _Fragment,
            { key: 1 },
            [
              _createElementVNode(
                "p",
                _hoisted_2,
                _toDisplayString(results.value.length) + " results",
                1
                /* TEXT */
              ),
              _createElementVNode("ul", null, [
                (_openBlock(true), _createElementBlock(
                  _Fragment,
                  null,
                  _renderList(results.value, (p) => {
                    return _openBlock(), _createElementBlock(
                      "li",
                      {
                        key: p.id
                      },
                      _toDisplayString(p.name),
                      1
                      /* TEXT */
                    );
                  }),
                  128
                  /* KEYED_FRAGMENT */
                ))
              ])
            ],
            64
            /* STABLE_FRAGMENT */
          )) : _createCommentVNode("v-if", true)
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var Search_default = _sfc;

// vue/reactivity/en/projects/search.ts
createApp(Search_default).mount("#app");
