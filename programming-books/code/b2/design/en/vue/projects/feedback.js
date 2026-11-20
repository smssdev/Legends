// design/en/vue/projects/feedback.ts
import { createApp } from "vue";

// design/en/vue/projects/Feedback.vue
import { defineComponent as _defineComponent3 } from "vue";
import { createElementVNode as _createElementVNode2, createTextVNode as _createTextVNode, withCtx as _withCtx, createVNode as _createVNode, openBlock as _openBlock3, createElementBlock as _createElementBlock3 } from "vue";

// design/en/vue/projects/Alert.vue
import { defineComponent as _defineComponent } from "vue";
import { createCommentVNode as _createCommentVNode, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, renderSlot as _renderSlot, normalizeClass as _normalizeClass, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
var _hoisted_1 = ["role"];
var _hoisted_2 = { "aria-hidden": "true" };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Alert",
  props: {
    tone: { default: "info" }
  },
  setup(__props) {
    const ICONS = { info: "\u2139", success: "\u2713", warning: "!", danger: "\u2715" };
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock(
        _Fragment,
        null,
        [
          _createCommentVNode(" Errors interrupt (alert); everything else waits for a pause (status) "),
          _createElementVNode("div", {
            class: _normalizeClass(["alert", `alert-${__props.tone}`]),
            role: __props.tone === "danger" ? "alert" : "status"
          }, [
            _createElementVNode(
              "span",
              _hoisted_2,
              _toDisplayString(ICONS[__props.tone]),
              1
              /* TEXT */
            ),
            _createElementVNode("span", null, [
              _renderSlot(_ctx.$slots, "default")
            ])
          ], 10, _hoisted_1)
        ],
        2112
        /* STABLE_FRAGMENT, DEV_ROOT_FRAGMENT */
      );
    };
  }
});
var Alert_default = _sfc;

// design/en/vue/projects/Badge.vue
import { defineComponent as _defineComponent2 } from "vue";
import { renderSlot as _renderSlot2, normalizeClass as _normalizeClass2, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Badge",
  props: {
    tone: { default: "neutral" }
  },
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2(
        "span",
        {
          class: _normalizeClass2(["badge", `badge-${__props.tone}`])
        },
        [
          _renderSlot2(_ctx.$slots, "default")
        ],
        2
        /* CLASS */
      );
    };
  }
});
var Badge_default = _sfc2;

// design/en/vue/projects/Feedback.vue
var _hoisted_12 = { class: "gallery" };
var _hoisted_22 = { class: "row" };
var _sfc3 = /* @__PURE__ */ _defineComponent3({
  __name: "Feedback",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock3(), _createElementBlock3("div", _hoisted_12, [
        _createElementVNode2("div", _hoisted_22, [
          _cache[4] || (_cache[4] = _createElementVNode2(
            "b",
            null,
            "Order #1042",
            -1
            /* CACHED */
          )),
          _createVNode(Badge_default, { tone: "success" }, {
            default: _withCtx(() => [..._cache[0] || (_cache[0] = [
              _createTextVNode(
                "Paid",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Badge_default, { tone: "warning" }, {
            default: _withCtx(() => [..._cache[1] || (_cache[1] = [
              _createTextVNode(
                "Pending",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Badge_default, { tone: "danger" }, {
            default: _withCtx(() => [..._cache[2] || (_cache[2] = [
              _createTextVNode(
                "Refunded",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Badge_default, null, {
            default: _withCtx(() => [..._cache[3] || (_cache[3] = [
              _createTextVNode(
                "New",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          })
        ]),
        _createElementVNode2("div", null, [
          _createVNode(Alert_default, null, {
            default: _withCtx(() => [..._cache[5] || (_cache[5] = [
              _createTextVNode(
                "Your order ships tomorrow.",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Alert_default, { tone: "success" }, {
            default: _withCtx(() => [..._cache[6] || (_cache[6] = [
              _createTextVNode(
                "Payment received. Thank you!",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Alert_default, { tone: "warning" }, {
            default: _withCtx(() => [..._cache[7] || (_cache[7] = [
              _createTextVNode(
                "Only 2 left in stock.",
                -1
                /* CACHED */
              )
            ])]),
            _: 1
            /* STABLE */
          }),
          _createVNode(Alert_default, { tone: "danger" }, {
            default: _withCtx(() => [..._cache[8] || (_cache[8] = [
              _createTextVNode(
                "The card was declined. Please try another one.",
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
var Feedback_default = _sfc3;

// design/en/vue/projects/feedback.ts
createApp(Feedback_default).mount("#app");
