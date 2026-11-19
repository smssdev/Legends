// vue/reactivity/en/order.ts
import { createApp } from "vue";

// vue/reactivity/en/Order.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createElementVNode as _createElementVNode2, createVNode as _createVNode, toDisplayString as _toDisplayString2, Fragment as _Fragment, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";
import { ref } from "vue";

// vue/reactivity/en/QuantityInput.vue
import { useModel as _useModel, mergeModels as _mergeModels, defineComponent as _defineComponent } from "vue";
import { createElementVNode as _createElementVNode, toDisplayString as _toDisplayString, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
var _hoisted_1 = ["aria-label"];
var _hoisted_2 = ["disabled"];
var _hoisted_3 = ["disabled"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "QuantityInput",
  props: /* @__PURE__ */ _mergeModels({
    max: {},
    label: {}
  }, {
    "modelValue": { required: true },
    "modelModifiers": {}
  }),
  emits: ["update:modelValue"],
  setup(__props) {
    const quantity = _useModel(__props, "modelValue");
    const props = __props;
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("div", {
        class: "quantity",
        role: "group",
        "aria-label": __props.label
      }, [
        _createElementVNode("button", {
          type: "button",
          class: "secondary",
          disabled: quantity.value <= 1,
          "aria-label": "\u22121",
          onClick: _cache[0] || (_cache[0] = ($event) => quantity.value--)
        }, "\u2212", 8, _hoisted_2),
        _createElementVNode(
          "output",
          null,
          _toDisplayString(quantity.value),
          1
          /* TEXT */
        ),
        _createElementVNode("button", {
          type: "button",
          class: "secondary",
          disabled: quantity.value >= props.max,
          "aria-label": "+1",
          onClick: _cache[1] || (_cache[1] = ($event) => quantity.value++)
        }, "+", 8, _hoisted_3)
      ], 8, _hoisted_1);
    };
  }
});
var QuantityInput_default = _sfc;

// vue/reactivity/en/Order.vue
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Order",
  setup(__props) {
    const mugs = ref(1);
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2(
        _Fragment,
        null,
        [
          _cache[1] || (_cache[1] = _createElementVNode2(
            "p",
            null,
            "Bit mug",
            -1
            /* CACHED */
          )),
          _createVNode(QuantityInput_default, {
            modelValue: mugs.value,
            "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => mugs.value = $event),
            max: 5,
            label: "Quantity"
          }, null, 8, ["modelValue"]),
          _createElementVNode2(
            "p",
            null,
            "You ordered: " + _toDisplayString2(mugs.value) + " \xB7 Total: " + _toDisplayString2(mugs.value * 8) + " EGP",
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
var Order_default = _sfc2;

// vue/reactivity/en/order.ts
createApp(Order_default).mount("#app");
