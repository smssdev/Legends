// design/ar/vue/buttons.ts
import { createApp } from "vue";

// design/ar/vue/Buttons.vue
import { defineComponent as _defineComponent3 } from "vue";
import { createVNode as _createVNode2, createElementVNode as _createElementVNode2, Fragment as _Fragment, openBlock as _openBlock3, createElementBlock as _createElementBlock3 } from "vue";

// design/ar/vue/Gallery.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createTextVNode as _createTextVNode, withCtx as _withCtx, createVNode as _createVNode, createElementVNode as _createElementVNode, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";

// design/ar/vue/Button.vue
import { defineComponent as _defineComponent } from "vue";
import { openBlock as _openBlock, createElementBlock as _createElementBlock, createCommentVNode as _createCommentVNode, renderSlot as _renderSlot, normalizeClass as _normalizeClass } from "vue";
var _hoisted_1 = ["type", "disabled", "aria-busy"];
var _hoisted_2 = {
  key: 0,
  class: "spinner",
  "aria-hidden": "true"
};
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Button",
  props: {
    variant: { default: "primary" },
    size: { default: "md" },
    loading: { type: Boolean, default: false },
    disabled: { type: Boolean },
    type: { default: "button" }
  },
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("button", {
        type: __props.type,
        class: _normalizeClass(["btn", `btn-${__props.variant}`, `btn-${__props.size}`]),
        disabled: __props.disabled || __props.loading,
        "aria-busy": __props.loading || void 0
      }, [
        __props.loading ? (_openBlock(), _createElementBlock("span", _hoisted_2)) : _createCommentVNode("v-if", true),
        _renderSlot(_ctx.$slots, "default")
      ], 10, _hoisted_1);
    };
  }
});
var Button_default = _sfc;

// design/ar/vue/Gallery.vue
var _hoisted_12 = { class: "gallery" };
var _hoisted_22 = { class: "row" };
var _hoisted_3 = { class: "row" };
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Gallery",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2("div", _hoisted_12, [
        _createElementVNode("div", _hoisted_22, [
          _createVNode(Button_default, null, {
            default: _withCtx(() => [..._cache[0] || (_cache[0] = [
              _createTextVNode(
                "\u0623\u0633\u0627\u0633\u064A",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Button_default, { variant: "secondary" }, {
            default: _withCtx(() => [..._cache[1] || (_cache[1] = [
              _createTextVNode(
                "\u062B\u0627\u0646\u0648\u064A",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Button_default, { variant: "danger" }, {
            default: _withCtx(() => [..._cache[2] || (_cache[2] = [
              _createTextVNode(
                "\u062E\u0637\u0631",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Button_default, { variant: "ghost" }, {
            default: _withCtx(() => [..._cache[3] || (_cache[3] = [
              _createTextVNode(
                "\u0634\u0641\u0627\u0641",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          })
        ]),
        _createElementVNode("div", _hoisted_3, [
          _createVNode(Button_default, { size: "sm" }, {
            default: _withCtx(() => [..._cache[4] || (_cache[4] = [
              _createTextVNode(
                "\u0635\u063A\u064A\u0631",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Button_default, { size: "lg" }, {
            default: _withCtx(() => [..._cache[5] || (_cache[5] = [
              _createTextVNode(
                "\u0643\u0628\u064A\u0631",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Button_default, { loading: "" }, {
            default: _withCtx(() => [..._cache[6] || (_cache[6] = [
              _createTextVNode(
                "\u062C\u0627\u0631\u064D \u0627\u0644\u062D\u0641\u0638\u2026",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Button_default, { disabled: "" }, {
            default: _withCtx(() => [..._cache[7] || (_cache[7] = [
              _createTextVNode(
                "\u0623\u0644\u063A\u0650",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          })
        ])
      ]);
    };
  }
});
var Gallery_default = _sfc2;

// design/ar/vue/Buttons.vue
var _hoisted_13 = {
  "data-theme": "dark",
  style: { "margin-top": "12px" }
};
var _sfc3 = /* @__PURE__ */ _defineComponent3({
  __name: "Buttons",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock3(), _createElementBlock3(
        _Fragment,
        null,
        [
          _createVNode2(Gallery_default),
          _createElementVNode2("div", _hoisted_13, [
            _createVNode2(Gallery_default)
          ])
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var Buttons_default = _sfc3;

// design/ar/vue/buttons.ts
createApp(Buttons_default).mount("#app");
