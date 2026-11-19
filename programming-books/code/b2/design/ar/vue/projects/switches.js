// design/ar/vue/projects/switches.ts
import { createApp } from "vue";

// design/ar/vue/projects/Settings.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createVNode as _createVNode, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";
import { ref } from "vue";

// design/ar/vue/projects/Switch.vue
import { useModel as _useModel, mergeModels as _mergeModels, defineComponent as _defineComponent } from "vue";
import { createElementVNode as _createElementVNode, toDisplayString as _toDisplayString, createTextVNode as _createTextVNode, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
var _hoisted_1 = ["aria-checked"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Switch",
  props: /* @__PURE__ */ _mergeModels({
    label: {}
  }, {
    "modelValue": { type: Boolean, ...{ default: false } },
    "modelModifiers": {}
  }),
  emits: ["update:modelValue"],
  setup(__props) {
    const on = _useModel(__props, "modelValue");
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("button", {
        type: "button",
        role: "switch",
        "aria-checked": on.value,
        class: "switch",
        onClick: _cache[0] || (_cache[0] = ($event) => on.value = !on.value)
      }, [
        _cache[1] || (_cache[1] = _createElementVNode(
          "span",
          {
            class: "track",
            "aria-hidden": "true"
          },
          [
            _createElementVNode("span", { class: "thumb" })
          ],
          -1
          /* CACHED */
        )),
        _createTextVNode(
          " " + _toDisplayString(__props.label),
          1
          /* TEXT */
        )
      ], 8, _hoisted_1);
    };
  }
});
var Switch_default = _sfc;

// design/ar/vue/projects/Settings.vue
var _hoisted_12 = ["data-theme"];
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Settings",
  setup(__props) {
    const dark = ref(false);
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2("div", {
        class: "gallery",
        "data-theme": dark.value ? "dark" : void 0
      }, [
        _createVNode(Switch_default, { label: "\u0631\u0627\u0633\u0644\u0646\u064A \u0639\u0646 \u0627\u0644\u0643\u062A\u0628 \u0627\u0644\u062C\u062F\u064A\u062F\u0629" }),
        _createVNode(Switch_default, { label: "\u0627\u0644\u0648\u0627\u064A \u0641\u0627\u064A" }),
        _createVNode(Switch_default, {
          modelValue: dark.value,
          "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => dark.value = $event),
          label: "\u0627\u0644\u0645\u0638\u0647\u0631 \u0627\u0644\u062F\u0627\u0643\u0646"
        }, null, 8, ["modelValue"])
      ], 8, _hoisted_12);
    };
  }
});
var Settings_default = _sfc2;

// design/ar/vue/projects/switches.ts
createApp(Settings_default).mount("#app");
