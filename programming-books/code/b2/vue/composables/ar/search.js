// vue/composables/ar/search.ts
import { createApp } from "vue";

// vue/composables/ar/Search.vue
import { defineComponent as _defineComponent } from "vue";
import { createElementVNode as _createElementVNode, vModelText as _vModelText, withDirectives as _withDirectives, unref as _unref, openBlock as _openBlock, createElementBlock as _createElementBlock, createCommentVNode as _createCommentVNode, toDisplayString as _toDisplayString, renderList as _renderList, Fragment as _Fragment } from "vue";
import { ref as ref3 } from "vue";

// vue/composables/ar/composables/useDebounced.ts
import { ref, toValue, watch } from "vue";
function useDebounced(source, ms = 300) {
  const value = ref(toValue(source));
  watch(
    () => toValue(source),
    (now, _before, onCleanup) => {
      const id = setTimeout(() => value.value = now, ms);
      onCleanup(() => clearTimeout(id));
    }
  );
  return value;
}

// vue/composables/ar/composables/useSearch.ts
import { ref as ref2, toValue as toValue2, watch as watch2 } from "vue";

// vue/composables/ar/products.ts
var catalogue = [
  { id: 1, name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", price: 25 },
  { id: 2, name: "\u0643\u0648\u0628 \u0628\u0650\u062A", price: 8 },
  { id: 3, name: "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A", price: 12 },
  { id: 4, name: "\u0645\u0644\u0635\u0642 \u0628\u0650\u062A", price: 3 }
];
function searchProducts(query, signal) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      const q = query.trim().toLowerCase();
      resolve(catalogue.filter((p) => p.name.toLowerCase().includes(q)));
    }, 400);
    signal.addEventListener("abort", () => {
      clearTimeout(timer);
      reject(signal.reason);
    });
  });
}

// vue/composables/ar/composables/useSearch.ts
function useSearch(query) {
  const results = ref2([]);
  const loading = ref2(false);
  const error = ref2(null);
  watch2(
    () => toValue2(query).trim(),
    async (q, _before, onCleanup) => {
      error.value = null;
      if (!q) {
        results.value = [];
        return;
      }
      const controller = new AbortController();
      onCleanup(() => controller.abort());
      loading.value = true;
      try {
        results.value = await searchProducts(q, controller.signal);
      } catch (e) {
        if (controller.signal.aborted) return;
        error.value = e.message;
      }
      loading.value = false;
    },
    { immediate: true }
  );
  return { results, loading, error };
}

// vue/composables/ar/Search.vue
var _hoisted_1 = {
  key: 0,
  role: "status",
  class: "muted"
};
var _hoisted_2 = {
  key: 1,
  role: "alert"
};
var _hoisted_3 = { role: "status" };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Search",
  setup(__props) {
    const query = ref3("");
    const { results, loading, error } = useSearch(useDebounced(query, 250));
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock(
        _Fragment,
        null,
        [
          _cache[1] || (_cache[1] = _createElementVNode(
            "label",
            { for: "q" },
            "\u0627\u0628\u062D\u062B \u0641\u064A \u0627\u0644\u0645\u0646\u062A\u062C\u0627\u062A",
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
          _unref(loading) ? (_openBlock(), _createElementBlock("p", _hoisted_1, "\u062C\u0627\u0631\u064D \u0627\u0644\u0628\u062D\u062B\u2026")) : _unref(error) ? (_openBlock(), _createElementBlock(
            "p",
            _hoisted_2,
            "\u062A\u0639\u0630\u0651\u0631 \u0627\u0644\u0628\u062D\u062B: " + _toDisplayString(_unref(error)),
            1
            /* TEXT */
          )) : query.value ? (_openBlock(), _createElementBlock(
            _Fragment,
            { key: 2 },
            [
              _createElementVNode(
                "p",
                _hoisted_3,
                _toDisplayString(_unref(results).length) + " \u0646\u062A\u0627\u0626\u062C",
                1
                /* TEXT */
              ),
              _createElementVNode("ul", null, [
                (_openBlock(true), _createElementBlock(
                  _Fragment,
                  null,
                  _renderList(_unref(results), (p) => {
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

// vue/composables/ar/search.ts
createApp(Search_default).mount("#app");
