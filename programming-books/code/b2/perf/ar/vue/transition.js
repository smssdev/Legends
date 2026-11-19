// perf/ar/vue/transition.ts
import { createApp } from "vue";

// perf/ar/vue/Filter.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createElementVNode as _createElementVNode, vModelText as _vModelText, withDirectives as _withDirectives, toDisplayString as _toDisplayString2, createVNode as _createVNode, normalizeClass as _normalizeClass, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";
import { computed, ref, shallowRef } from "vue";
import { refDebounced } from "@vueuse/core";

// perf/ar/vue/SlowList.vue
import { defineComponent as _defineComponent } from "vue";
import { renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock, toDisplayString as _toDisplayString } from "vue";
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "SlowList",
  props: {
    items: {}
  },
  setup(__props) {
    function slow(name) {
      const start = performance.now();
      while (performance.now() - start < 0.2) {
      }
      return name;
    }
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("ul", null, [
        (_openBlock(true), _createElementBlock(
          _Fragment,
          null,
          _renderList(__props.items.slice(0, 2e3), (name) => {
            return _openBlock(), _createElementBlock(
              "li",
              { key: name },
              _toDisplayString(slow(name)),
              1
              /* TEXT */
            );
          }),
          128
          /* KEYED_FRAGMENT */
        ))
      ]);
    };
  }
});
var SlowList_default = _sfc;

// perf/ar/vue/Filter.vue
var _hoisted_1 = { class: "card" };
var _hoisted_2 = {
  class: "muted",
  "aria-live": "polite"
};
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Filter",
  setup(__props) {
    const ALL = shallowRef(Array.from({ length: 5e3 }, (_, i) => `\u0645\u0646\u062A\u062C \u0628\u0650\u062A ${i + 1}`));
    const text = ref("");
    const deferred = refDebounced(text, 250);
    const items = computed(() => ALL.value.filter((name) => name.includes(deferred.value)));
    const stale = computed(() => text.value !== deferred.value);
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2("div", _hoisted_1, [
        _cache[1] || (_cache[1] = _createElementVNode(
          "label",
          { for: "q" },
          "\u0635\u0641\u0650\u0651 \u0627\u0644\u0645\u0646\u062A\u062C\u0627\u062A",
          -1
          /* CACHED */
        )),
        _withDirectives(_createElementVNode(
          "input",
          {
            id: "q",
            "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => text.value = $event)
          },
          null,
          512
          /* NEED_PATCH */
        ), [
          [_vModelText, text.value]
        ]),
        _createElementVNode(
          "p",
          _hoisted_2,
          _toDisplayString2(stale.value ? "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u062F\u064A\u062B\u2026" : `\u064A\u0638\u0647\u0631 ${items.value.length} \u0645\u0646 ${ALL.value.length}`),
          1
          /* TEXT */
        ),
        _createElementVNode(
          "div",
          {
            class: _normalizeClass({ stale: stale.value })
          },
          [
            _createVNode(SlowList_default, { items: items.value }, null, 8, ["items"])
          ],
          2
          /* CLASS */
        )
      ]);
    };
  }
});
var Filter_default = _sfc2;

// perf/ar/vue/transition.ts
createApp(Filter_default).mount("#app");
