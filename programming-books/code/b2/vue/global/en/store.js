// vue/global/en/store.ts
import { createApp } from "vue";
import { createPinia } from "pinia";

// vue/global/en/ShopApp.vue
import { defineComponent as _defineComponent4 } from "vue";
import { createElementVNode as _createElementVNode4, createVNode as _createVNode, Fragment as _Fragment3, openBlock as _openBlock4, createElementBlock as _createElementBlock4 } from "vue";

// vue/global/en/CartBadge.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, createTextVNode as _createTextVNode, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { storeToRefs } from "pinia";

// vue/global/en/stores/cart.ts
import { computed } from "vue";
import { defineStore } from "pinia";
import { useLocalStorage } from "@vueuse/core";
var useCart = defineStore("cart", () => {
  const lines = useLocalStorage("cart", {});
  const count = computed(() => Object.values(lines.value).reduce((n, l) => n + l.quantity, 0));
  const total = computed(() => Object.values(lines.value).reduce((n, l) => n + l.quantity * l.product.price, 0));
  function add(product) {
    const line = lines.value[product.id];
    if (line) line.quantity++;
    else lines.value[product.id] = { product, quantity: 1 };
  }
  function clear() {
    lines.value = {};
  }
  return { lines, count, total, add, clear };
});

// vue/global/en/CartBadge.vue
var _hoisted_1 = { class: "row" };
var _hoisted_2 = { class: "badge" };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "CartBadge",
  setup(__props) {
    const { count } = storeToRefs(useCart());
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("span", _hoisted_1, [
        _cache[0] || (_cache[0] = _createTextVNode(
          "Cart ",
          -1
          /* CACHED */
        )),
        _createElementVNode(
          "span",
          _hoisted_2,
          _toDisplayString(_unref(count)),
          1
          /* TEXT */
        )
      ]);
    };
  }
});
var CartBadge_default = _sfc;

// vue/global/en/CartSummary.vue
import { defineComponent as _defineComponent2 } from "vue";
import { unref as _unref2, openBlock as _openBlock2, createElementBlock as _createElementBlock2, renderList as _renderList, Fragment as _Fragment, toDisplayString as _toDisplayString2, createElementVNode as _createElementVNode2 } from "vue";
import { storeToRefs as storeToRefs2 } from "pinia";
var _hoisted_12 = {
  key: 0,
  class: "card muted"
};
var _hoisted_22 = {
  key: 1,
  class: "card"
};
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "CartSummary",
  setup(__props) {
    const cart = useCart();
    const { lines, total } = storeToRefs2(cart);
    return (_ctx, _cache) => {
      return Object.keys(_unref2(lines)).length === 0 ? (_openBlock2(), _createElementBlock2("p", _hoisted_12, "The cart is empty.")) : (_openBlock2(), _createElementBlock2("section", _hoisted_22, [
        _createElementVNode2("ul", null, [
          (_openBlock2(true), _createElementBlock2(
            _Fragment,
            null,
            _renderList(_unref2(lines), (l) => {
              return _openBlock2(), _createElementBlock2("li", {
                key: l.product.id
              }, [
                _createElementVNode2(
                  "span",
                  null,
                  _toDisplayString2(l.quantity) + " \xD7 " + _toDisplayString2(l.product.name),
                  1
                  /* TEXT */
                ),
                _createElementVNode2(
                  "span",
                  null,
                  _toDisplayString2(l.quantity * l.product.price) + " EGP",
                  1
                  /* TEXT */
                )
              ]);
            }),
            128
            /* KEYED_FRAGMENT */
          ))
        ]),
        _createElementVNode2("p", null, [
          _createElementVNode2(
            "b",
            null,
            "Total: " + _toDisplayString2(_unref2(total)) + " EGP",
            1
            /* TEXT */
          )
        ]),
        _createElementVNode2("button", {
          type: "button",
          class: "secondary",
          onClick: _cache[0] || (_cache[0] = ($event) => _unref2(cart).clear())
        }, "Empty the cart")
      ]));
    };
  }
});
var CartSummary_default = _sfc2;

// vue/global/en/ProductList.vue
import { defineComponent as _defineComponent3 } from "vue";
import { renderList as _renderList2, Fragment as _Fragment2, openBlock as _openBlock3, createElementBlock as _createElementBlock3, toDisplayString as _toDisplayString3, createElementVNode as _createElementVNode3, unref as _unref3 } from "vue";
var _hoisted_13 = { class: "card" };
var _hoisted_23 = ["onClick"];
var _sfc3 = /* @__PURE__ */ _defineComponent3({
  __name: "ProductList",
  setup(__props) {
    const products = [
      { id: 1, name: "Code from Zero", price: 25 },
      { id: 2, name: "Bit mug", price: 8 },
      { id: 3, name: "Bit cap", price: 12 }
    ];
    const { add } = useCart();
    return (_ctx, _cache) => {
      return _openBlock3(), _createElementBlock3("section", _hoisted_13, [
        (_openBlock3(), _createElementBlock3(
          _Fragment2,
          null,
          _renderList2(products, (p) => {
            return _createElementVNode3("div", {
              key: p.id,
              class: "row spread"
            }, [
              _createElementVNode3(
                "span",
                null,
                _toDisplayString3(p.name),
                1
                /* TEXT */
              ),
              _createElementVNode3("button", {
                type: "button",
                onClick: ($event) => _unref3(add)(p)
              }, "Add", 8, _hoisted_23)
            ]);
          }),
          64
          /* STABLE_FRAGMENT */
        ))
      ]);
    };
  }
});
var ProductList_default = _sfc3;

// vue/global/en/ShopApp.vue
var _sfc4 = /* @__PURE__ */ _defineComponent4({
  __name: "ShopApp",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock4(), _createElementBlock4(
        _Fragment3,
        null,
        [
          _createElementVNode4("header", null, [
            _cache[0] || (_cache[0] = _createElementVNode4(
              "span",
              { class: "brand" },
              "Bit's shop",
              -1
              /* CACHED */
            )),
            _createVNode(CartBadge_default)
          ]),
          _createVNode(ProductList_default),
          _createVNode(CartSummary_default)
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var ShopApp_default = _sfc4;

// vue/global/en/store.ts
localStorage.clear();
createApp(ShopApp_default).use(createPinia()).mount("#app");
