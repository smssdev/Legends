// vue/components/en/cards.ts
import { createApp } from "vue";

// vue/components/en/Shop.vue
import { defineComponent as _defineComponent3 } from "vue";
import { unref as _unref, renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock3, createElementBlock as _createElementBlock3, createBlock as _createBlock, createElementVNode as _createElementVNode3, withCtx as _withCtx } from "vue";

// vue/components/en/ProductCard.vue
import { defineComponent as _defineComponent } from "vue";
import { openBlock as _openBlock, createElementBlock as _createElementBlock, createCommentVNode as _createCommentVNode, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode } from "vue";
var _hoisted_1 = { class: "card" };
var _hoisted_2 = {
  key: 0,
  class: "badge"
};
var _hoisted_3 = { class: "price" };
var _hoisted_4 = ["disabled"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "ProductCard",
  props: {
    product: {}
  },
  emits: ["add"],
  setup(__props, { emit: __emit }) {
    const emit = __emit;
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("article", _hoisted_1, [
        __props.product.isNew ? (_openBlock(), _createElementBlock("span", _hoisted_2, "New")) : _createCommentVNode("v-if", true),
        _createElementVNode(
          "h3",
          null,
          _toDisplayString(__props.product.name),
          1
          /* TEXT */
        ),
        _createElementVNode(
          "p",
          _hoisted_3,
          _toDisplayString(__props.product.price.toFixed(2)) + " EGP",
          1
          /* TEXT */
        ),
        _createElementVNode("button", {
          type: "button",
          disabled: !__props.product.inStock,
          onClick: _cache[0] || (_cache[0] = ($event) => emit("add", __props.product.id))
        }, _toDisplayString(__props.product.inStock ? "Add to cart" : "Sold out"), 9, _hoisted_4)
      ]);
    };
  }
});
var ProductCard_default = _sfc;

// vue/components/en/ShopSection.vue
import { defineComponent as _defineComponent2 } from "vue";
import { toDisplayString as _toDisplayString2, createElementVNode as _createElementVNode2, renderSlot as _renderSlot, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "ShopSection",
  props: {
    title: {}
  },
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2("section", null, [
        _createElementVNode2(
          "h2",
          null,
          _toDisplayString2(__props.title),
          1
          /* TEXT */
        ),
        _renderSlot(_ctx.$slots, "default")
      ]);
    };
  }
});
var ShopSection_default = _sfc2;

// vue/components/en/products.ts
var products = [
  { id: 1, name: "Code from Zero", price: 25, category: "books", isNew: true, inStock: true },
  { id: 2, name: "Bit mug", price: 8, category: "gifts", inStock: true },
  { id: 3, name: "Bit sticker", price: 3, category: "gifts", inStock: false },
  { id: 4, name: "Bit cap", price: 12, category: "gifts", isNew: true, inStock: true }
];

// vue/components/en/Shop.vue
var _hoisted_12 = { class: "grid" };
var _sfc3 = /* @__PURE__ */ _defineComponent3({
  __name: "Shop",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock3(), _createBlock(ShopSection_default, { title: "Bit's shop" }, {
        default: _withCtx(() => [
          _createElementVNode3("div", _hoisted_12, [
            (_openBlock3(true), _createElementBlock3(
              _Fragment,
              null,
              _renderList(_unref(products), (product) => {
                return _openBlock3(), _createBlock(ProductCard_default, {
                  key: product.id,
                  product
                }, null, 8, ["product"]);
              }),
              128
              /* KEYED_FRAGMENT */
            ))
          ])
        ]),
        _: 1
        /* STABLE */
      });
    };
  }
});
var Shop_default = _sfc3;

// vue/components/en/cards.ts
createApp(Shop_default).mount("#app");
