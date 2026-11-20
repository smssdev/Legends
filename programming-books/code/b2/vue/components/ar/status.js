// vue/components/ar/status.ts
import { createApp } from "vue";

// vue/components/ar/StatusDemo.vue
import { defineComponent as _defineComponent2 } from "vue";
import { renderList as _renderList2, Fragment as _Fragment2, openBlock as _openBlock2, createElementBlock as _createElementBlock2, createVNode as _createVNode, createElementVNode as _createElementVNode2 } from "vue";

// vue/components/ar/OrderList.vue
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
          "\u062C\u0627\u0631\u064D \u062A\u062D\u0645\u064A\u0644 \u0637\u0644\u0628\u0627\u062A\u0643\u2026",
          -1
          /* CACHED */
        )
      ])])) : __props.state.status === "error" ? (_openBlock(), _createElementBlock("p", _hoisted_2, [
        _createTextVNode(
          " \u062A\u0639\u0630\u0651\u0631 \u062A\u062D\u0645\u064A\u0644 \u0637\u0644\u0628\u0627\u062A\u0643: " + _toDisplayString(__props.state.message) + " ",
          1
          /* TEXT */
        ),
        _cache[1] || (_cache[1] = _createElementVNode(
          "button",
          {
            type: "button",
            class: "secondary"
          },
          "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062E\u0631\u0649",
          -1
          /* CACHED */
        ))
      ])) : __props.state.orders.length === 0 ? (_openBlock(), _createElementBlock("p", _hoisted_3, "\u0644\u064A\u0633\u062A \u0644\u062F\u064A\u0643 \u0637\u0644\u0628\u0627\u062A \u0628\u0639\u062F.")) : (_openBlock(), _createElementBlock("ul", _hoisted_4, [
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

// vue/components/ar/StatusDemo.vue
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "StatusDemo",
  setup(__props) {
    const examples = [
      { status: "loading" },
      { status: "error", message: "\u0623\u0646\u062A \u063A\u064A\u0631 \u0645\u062A\u0635\u0644" },
      { status: "success", orders: [] },
      { status: "success", orders: ["#1042 \xB7 \u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", "#1043 \xB7 \u0643\u0648\u0628 \u0628\u0650\u062A"] }
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

// vue/components/ar/status.ts
createApp(StatusDemo_default).mount("#app");
