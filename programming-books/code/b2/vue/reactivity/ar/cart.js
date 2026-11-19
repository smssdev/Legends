// vue/reactivity/ar/cart.ts
import { createApp } from "vue";

// vue/reactivity/ar/Cart.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, createTextVNode as _createTextVNode, normalizeStyle as _normalizeStyle } from "vue";
import { computed, ref } from "vue";

// vue/reactivity/ar/cart-model.ts
var catalogue = [
  { id: 1, name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", price: 25 },
  { id: 2, name: "\u0643\u0648\u0628 \u0628\u0650\u062A", price: 8 },
  { id: 3, name: "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A", price: 12 }
];
var FREE_DELIVERY = 50;

// vue/reactivity/ar/Cart.vue
var _hoisted_1 = { class: "cart" };
var _hoisted_2 = { class: "row" };
var _hoisted_3 = ["onClick"];
var _hoisted_4 = {
  key: 0,
  class: "muted"
};
var _hoisted_5 = { key: 1 };
var _hoisted_6 = ["onClick"];
var _hoisted_7 = { class: "total" };
var _hoisted_8 = {
  class: "bar",
  "aria-hidden": "true"
};
var _hoisted_9 = {
  key: 2,
  class: "free"
};
var _hoisted_10 = {
  key: 3,
  class: "muted"
};
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Cart",
  setup(__props) {
    const lines = ref([]);
    const count = computed(() => lines.value.reduce((n, l) => n + l.quantity, 0));
    const total = computed(() => lines.value.reduce((sum, l) => sum + l.product.price * l.quantity, 0));
    const missing = computed(() => Math.max(0, FREE_DELIVERY - total.value));
    function add(product) {
      const line = lines.value.find((l) => l.product.id === product.id);
      if (line) line.quantity++;
      else lines.value.push({ product, quantity: 1 });
    }
    function remove(id) {
      lines.value = lines.value.filter((l) => l.product.id !== id);
    }
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("section", _hoisted_1, [
        _createElementVNode("div", _hoisted_2, [
          (_openBlock(true), _createElementBlock(
            _Fragment,
            null,
            _renderList(_unref(catalogue), (p) => {
              return _openBlock(), _createElementBlock("button", {
                key: p.id,
                type: "button",
                class: "secondary",
                onClick: ($event) => add(p)
              }, " \u0623\u0636\u0641 " + _toDisplayString(p.name), 9, _hoisted_3);
            }),
            128
            /* KEYED_FRAGMENT */
          ))
        ]),
        lines.value.length === 0 ? (_openBlock(), _createElementBlock("p", _hoisted_4, "\u0633\u0644\u062A\u0643 \u0641\u0627\u0631\u063A\u0629.")) : (_openBlock(), _createElementBlock("ul", _hoisted_5, [
          (_openBlock(true), _createElementBlock(
            _Fragment,
            null,
            _renderList(lines.value, (line) => {
              return _openBlock(), _createElementBlock("li", {
                key: line.product.id
              }, [
                _createElementVNode(
                  "span",
                  null,
                  _toDisplayString(line.product.name) + " \xD7 " + _toDisplayString(line.quantity),
                  1
                  /* TEXT */
                ),
                _createElementVNode("button", {
                  type: "button",
                  class: "secondary",
                  onClick: ($event) => remove(line.product.id)
                }, "\u0627\u062D\u0630\u0641", 8, _hoisted_6)
              ]);
            }),
            128
            /* KEYED_FRAGMENT */
          ))
        ])),
        _createElementVNode("p", null, [
          _createTextVNode(
            "\u0627\u0644\u0639\u0646\u0627\u0635\u0631: " + _toDisplayString(count.value) + " \xB7 ",
            1
            /* TEXT */
          ),
          _createElementVNode(
            "span",
            _hoisted_7,
            "\u0627\u0644\u0645\u062C\u0645\u0648\u0639: " + _toDisplayString(total.value) + " \u062C\u0646\u064A\u0647\u0627\u064B",
            1
            /* TEXT */
          )
        ]),
        _createElementVNode("div", _hoisted_8, [
          _createElementVNode(
            "span",
            {
              style: _normalizeStyle({ width: `${Math.min(100, total.value / 50 * 100)}%` })
            },
            null,
            4
            /* STYLE */
          )
        ]),
        missing.value === 0 ? (_openBlock(), _createElementBlock("p", _hoisted_9, "\u062A\u0648\u0635\u064A\u0644 \u0645\u062C\u0627\u0646\u064A!")) : (_openBlock(), _createElementBlock(
          "p",
          _hoisted_10,
          _toDisplayString(missing.value) + " \u062C\u0646\u064A\u0647\u0627\u064B \u0623\u062E\u0631\u0649 \u0644\u0644\u062A\u0648\u0635\u064A\u0644 \u0627\u0644\u0645\u062C\u0627\u0646\u064A",
          1
          /* TEXT */
        ))
      ]);
    };
  }
});
var Cart_default = _sfc;

// vue/reactivity/ar/cart.ts
createApp(Cart_default).mount("#app");
