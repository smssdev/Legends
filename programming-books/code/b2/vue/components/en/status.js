// vue/components/en/status.ts
import { createApp } from "vue";

// vue/components/en/StatusDemo.vue
import { defineComponent as _defineComponent2 } from "vue";
import { renderList as _renderList2, Fragment as _Fragment2, openBlock as _openBlock2, createElementBlock as _createElementBlock2, createVNode as _createVNode, createElementVNode as _createElementVNode2 } from "vue";

// vue/components/en/OrderList.vue
import { defineComponent as _defineComponent } from "vue";
import { createElementVNode as _createElementVNode, createTextVNode as _createTextVNode, openBlock as _openBlock, createElementBlock as _createElementBlock, toDisplayString as _toDisplayString, renderList as _renderList, Fragment as _Fragment } from "vue";
var _hoisted_1 = {
  key: 0,
  class: "muted"
};
var _hoisted_2 = {
  key: 1,
  class: "error"
};
var _hoisted_3 = {
  key: 2,
  class: "muted"
};
var _hoisted_4 = { key: 3 };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "OrderList",
  props: {
    state: {}
  },
  setup(__props) {
    return (_ctx, _cache) => {
      return __props.state.status === "loading" ? (_openBlock(), _createElementBlock("p", _hoisted_1, [..._cache[0] || (_cache[0] = [
        _createElementVNode(
          "span",
          { class: "spinner" },
          null,
          -1
          /* CACHED */
        ),
        _createTextVNode(
          "Loading your orders\u2026",
          -1
          /* CACHED */
        )
      ])])) : __props.state.status === "error" ? (_openBlock(), _createElementBlock("p", _hoisted_2, [
        _createTextVNode(
          " Could not load your orders: " + _toDisplayString(__props.state.message) + " ",
          1
          /* TEXT */
        ),
        _cache[1] || (_cache[1] = _createElementVNode(
          "button",
          {
            type: "button",
            class: "secondary"
          },
          "Try again",
          -1
          /* CACHED */
        ))
      ])) : __props.state.orders.length === 0 ? (_openBlock(), _createElementBlock("p", _hoisted_3, "You have no orders yet.")) : (_openBlock(), _createElementBlock("ul", _hoisted_4, [
        (_openBlock(true), _createElementBlock(
          _Fragment,
          null,
          _renderList(__props.state.orders, (order) => {
            return _openBlock(), _createElementBlock(
              "li",
              { key: order },
              _toDisplayString(order),
              1
              /* TEXT */
            );
          }),
          128
          /* KEYED_FRAGMENT */
        ))
      ]));
    };
  }
});
var OrderList_default = _sfc;

// vue/components/en/StatusDemo.vue
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "StatusDemo",
  setup(__props) {
    const examples = [
      { status: "loading" },
      { status: "error", message: "you are offline" },
      { status: "success", orders: [] },
      { status: "success", orders: ["#1042 \xB7 Code from Zero", "#1043 \xB7 Bit mug"] }
    ];
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2(
        _Fragment2,
        null,
        _renderList2(examples, (state, i) => {
          return _createElementVNode2("div", {
            key: i,
            class: "panel"
          }, [
            _createVNode(OrderList_default, { state }, null, 8, ["state"])
          ]);
        }),
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var StatusDemo_default = _sfc2;

// vue/components/en/status.ts
createApp(StatusDemo_default).mount("#app");
