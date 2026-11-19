// vue/reactivity/en/projects/history.ts
import { createApp } from "vue";

// vue/reactivity/en/projects/History.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, vModelText as _vModelText, withDirectives as _withDirectives, createTextVNode as _createTextVNode, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { computed, ref } from "vue";
var _hoisted_1 = {
  class: "value",
  "aria-live": "polite"
};
var _hoisted_2 = { class: "row" };
var _hoisted_3 = ["disabled"];
var _hoisted_4 = { class: "muted" };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "History",
  setup(__props) {
    const step = ref(1);
    const history = ref([0]);
    const value = computed(() => history.value.at(-1) ?? 0);
    function change(by) {
      history.value.push(value.value + by);
    }
    function undo() {
      if (history.value.length > 1) history.value.pop();
    }
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock(
        _Fragment,
        null,
        [
          _createElementVNode(
            "p",
            _hoisted_1,
            _toDisplayString(value.value),
            1
            /* TEXT */
          ),
          _createElementVNode("div", _hoisted_2, [
            _createElementVNode(
              "button",
              {
                type: "button",
                class: "secondary",
                onClick: _cache[0] || (_cache[0] = ($event) => change(-step.value))
              },
              "\u2212" + _toDisplayString(step.value),
              1
              /* TEXT */
            ),
            _createElementVNode(
              "button",
              {
                type: "button",
                onClick: _cache[1] || (_cache[1] = ($event) => change(step.value))
              },
              "+" + _toDisplayString(step.value),
              1
              /* TEXT */
            ),
            _createElementVNode("button", {
              type: "button",
              class: "secondary",
              disabled: history.value.length === 1,
              onClick: undo
            }, "Undo", 8, _hoisted_3)
          ]),
          _createElementVNode("label", null, [
            _cache[3] || (_cache[3] = _createTextVNode(
              "Step ",
              -1
              /* CACHED */
            )),
            _withDirectives(_createElementVNode(
              "input",
              {
                id: "step",
                "onUpdate:modelValue": _cache[2] || (_cache[2] = ($event) => step.value = $event),
                type: "number",
                min: "1",
                max: "10"
              },
              null,
              512
              /* NEED_PATCH */
            ), [
              [
                _vModelText,
                step.value,
                void 0,
                { number: true }
              ]
            ])
          ]),
          _createElementVNode(
            "p",
            _hoisted_4,
            "History: " + _toDisplayString(history.value.join(" \u2192 ")),
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
var History_default = _sfc;

// vue/reactivity/en/projects/history.ts
createApp(History_default).mount("#app");
